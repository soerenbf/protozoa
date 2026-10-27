//// Plans where protobuf declarations live in per-file generated Gleam code.
////
//// Each proto file maps to a module beneath the caller's prefix. For example,
//// "api/user.proto" with prefix "generated" becomes "generated/api/user".
//// A protobuf package does not become part of the local type name:
//// "example.api.User" becomes "User" in that module. Nested declarations retain
//// their containing message name, such as "Envelope.Item" -> "EnvelopeItem".
////
//// The plan retains each declaration's protobuf identity and source file so
//// code generation can resolve cross-file references to their owning module.
//// It rejects unsafe paths and names that collide after normalization, rather
//// than silently renaming declarations or overwriting output.
////
//// This module plans and validates names only; it performs no filesystem I/O
//// and does not change the combined-output generator's naming policy.

import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import justin
import protozoa/internal/codegen/types
import protozoa/internal/type_registry.{type TypeRegistry}
import protozoa/parser/proto

pub type Declaration {
  Declaration(
    identity: String,
    source: String,
    module: String,
    local_type: String,
    codec_suffix: String,
  )
}

/// Parse a schema-relative `path` before any filesystem read. Rejects absolute,
/// empty, dot/traversal, Windows and ambiguous paths. Returns the original path.
/// Example: `safe_source("a/items.proto") == Ok("a/items.proto")`.
pub fn safe_source(path: String) -> Result(String, String) {
  case
    string.contains(path, "\\")
    || string.contains(path, ":")
    || string.contains(path, "\u{0}")
    || list.any(string.split(path, "/"), fn(p) {
      p == "" || p == "." || p == ".."
    })
  {
    True -> Error("Unsafe schema path: " <> path)
    False -> Ok(path)
  }
}

/// Validate `prefix` as a slash-separated Gleam module path. Returns a diagnostic
/// for invalid segments; does not normalize caller configuration.
/// Example: `valid_prefix("generated/proto") == Ok(Nil)`.
pub fn valid_prefix(prefix: String) -> Result(Nil, String) {
  case list.all(string.split(prefix, "/"), valid_segment) {
    True -> Ok(Nil)
    False -> Error("Invalid Gleam module path: " <> prefix)
  }
}

/// Map a safe schema `path` beneath validated `prefix`; errors identify the input.
/// Example: `module_path("api.proto", "generated")`.
pub fn module_path(path: String, prefix: String) -> Result(String, String) {
  use _ <- result.try(safe_source(path))
  use _ <- result.try(valid_prefix(prefix))
  use stem <- result.try(case string.ends_with(path, ".proto") {
    True -> Ok(string.drop_end(path, 6))
    False -> Error("Expected .proto schema path: " <> path)
  })
  let module =
    prefix
    <> "/"
    <> {
      stem
      |> string.split("/")
      |> list.map(justin.snake_case)
      |> string.join("/")
    }
  valid_prefix(module)
  |> result.map(fn(_) { module })
  |> result.map_error(fn(error) { error <> " from schema " <> path })
}

fn valid_segment(segment: String) -> Bool {
  let chars =
    string.to_utf_codepoints(segment) |> list.map(string.utf_codepoint_to_int)
  case chars {
    [first, ..rest] ->
      first >= 97
      && first <= 122
      && list.all(rest, fn(c) {
        c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 95
      })
      && types.escape_keyword(segment) == segment
    [] -> False
  }
}

/// Plan declarations from resolved `paths` using their original `registry` and
/// explicit `prefix`. Output is sorted by protobuf identity, independent of entry
/// order. Errors identify unsafe paths, normalized module collisions and local
/// symbol collisions. Writes nothing. Example: `plan(registry, paths, "gen/proto")`.
pub fn plan(
  registry: TypeRegistry,
  paths: List(String),
  prefix: String,
) -> Result(List(Declaration), String) {
  use _ <- result.try(valid_prefix(prefix))
  use modules <- result.try(
    list.try_fold(list.sort(paths, string.compare), dict.new(), fn(acc, path) {
      use _ <- result.try(safe_source(path))
      use module <- result.try(module_path(path, prefix))
      case
        list.find(dict.to_list(acc), fn(item) {
          item.1 == module && item.0 != path
        })
      {
        Ok(other) ->
          Error(
            "Module path collision: "
            <> other.0
            <> " and "
            <> path
            <> " -> "
            <> module,
          )
        Error(_) -> Ok(dict.insert(acc, path, module))
      }
    }),
  )
  let declarations =
    registry.type_sources
    |> dict.to_list
    |> list.filter_map(fn(entry) {
      use module <- result.try(dict.get(modules, entry.1))
      let ctx = types.new_local_ctx(registry, entry.1)
      let relative = case ctx.package {
        "" -> entry.0
        _ -> string.drop_start(entry.0, string.length(ctx.package) + 1)
      }
      let name = types.qualified_type(relative, ctx)
      Ok(Declaration(entry.0, entry.1, module, name, justin.snake_case(name)))
    })
    |> list.sort(fn(a, b) { string.compare(a.identity, b.identity) })
  use _ <- result.try(validate_symbols(declarations, registry, []))
  Ok(declarations)
}

/// Validate schema and extension `symbols` together (module:kind:name, owner).
/// Kinds are type, constructor and fn; errors identify conflicting owners.
/// Example: `validate_symbols(declarations, registry, symbols)`.
pub fn validate_symbols(
  declarations: List(Declaration),
  registry: TypeRegistry,
  extra: List(#(String, String)),
) -> Result(Nil, String) {
  use _ <- result.try(
    list.try_each(declarations, fn(d) {
      case
        list.contains(
          [
            "Int",
            "Float",
            "Bool",
            "String",
            "BitArray",
            "List",
            "Result",
            "Nil",
            "UtfCodepoint",
          ],
          d.local_type,
        )
      {
        True ->
          Error(
            "Reserved Gleam prelude type "
            <> d.local_type
            <> " from "
            <> d.identity
            <> " in "
            <> d.source,
          )
        False -> Ok(Nil)
      }
    }),
  )
  let symbols =
    list.flat_map(declarations, fn(d) {
      let base = [
        #(d.module <> ":type:" <> d.local_type, d.identity),
      ]
      let constructors = case dict.get(registry.messages, d.identity) {
        Ok(message) -> [
          #(d.local_type, d.identity),
          ..list.flat_map(message.oneofs, fn(o) {
            let owner = d.local_type <> types.capitalize_first(o.name)
            [
              #("type:" <> owner, d.identity <> "." <> o.name),
              ..list.map(o.fields, fn(f) {
                #(
                  types.constructor(owner, f.name),
                  d.identity <> "." <> o.name <> "." <> f.name,
                )
              })
            ]
          })
        ]
        Error(_) ->
          case dict.get(registry.enums, d.identity) {
            Ok(enum) ->
              list.map(enum.values, fn(v) {
                #(
                  types.enum_constructor(
                    d.local_type,
                    v.name,
                    types.new_local_ctx(registry, d.source),
                  ),
                  d.identity <> "." <> v.name,
                )
              })
            Error(_) -> []
          }
      }
      let functions = case dict.get(registry.messages, d.identity) {
        Ok(message) -> [
          #("encode_" <> d.codec_suffix, d.identity),
          #("decode_" <> d.codec_suffix, d.identity),
          #(d.codec_suffix <> "_decoder", d.identity),
          ..list.append(
            list.map(message.oneofs, fn(o) {
              #(
                types.oneof_decoder_name(d.local_type, o.name),
                d.identity <> "." <> o.name,
              )
            }),
            list.filter_map(message.fields, fn(f) {
              case f.field_type {
                proto.Map(_, _) ->
                  Ok(#(
                    types.map_decoder_name(
                      d.codec_suffix,
                      int.to_string(f.number),
                    ),
                    d.identity <> "." <> f.name,
                  ))
                _ -> Error(Nil)
              }
            }),
          )
        ]
        Error(_) ->
          list.map(
            [
              "encode_" <> d.codec_suffix <> "_value",
              "decode_" <> d.codec_suffix <> "_field",
              "decode_" <> d.codec_suffix <> "_from_field",
              "decode_" <> d.codec_suffix <> "_value",
              "decode_repeated_" <> d.codec_suffix,
            ],
            fn(name) { #(name, d.identity) },
          )
      }
      list.append(
        list.append(
          base,
          list.map(functions, fn(f) { #(d.module <> ":fn:" <> f.0, f.1) }),
        ),
        list.map(constructors, fn(c) {
          let key = case string.starts_with(c.0, "type:") {
            True -> c.0
            False -> "constructor:" <> c.0
          }
          #(d.module <> ":" <> key, c.1)
        }),
      )
    })
  let symbols = list.append(symbols, extra)
  use _ <- result.try(
    list.try_each(symbols, fn(item) {
      let assert [module, kind, name] = string.split(item.0, ":")
      let source =
        list.find(declarations, fn(d) { d.module == module })
        |> result.map(fn(d) { d.source })
        |> result.unwrap(item.1)
      validate_identifier(kind, name, item.1, source)
    }),
  )
  use _ <- result.try(
    list.try_fold(symbols, dict.new(), fn(seen, item) {
      case dict.get(seen, item.0) {
        Ok(other) ->
          Error(
            "Generated name collision: "
            <> item.0
            <> " from "
            <> other
            <> " and "
            <> item.1,
          )
        Error(_) -> Ok(dict.insert(seen, item.0, item.1))
      }
    }),
  )
  Ok(Nil)
}

fn validate_identifier(
  kind: String,
  name: String,
  identity: String,
  source: String,
) -> Result(Nil, String) {
  let valid = case kind {
    "fn" -> valid_segment(name)
    _ -> {
      let chars =
        string.to_utf_codepoints(name) |> list.map(string.utf_codepoint_to_int)
      case chars {
        [first, ..rest] ->
          first >= 65
          && first <= 90
          && list.all(rest, fn(c) {
            c >= 65
            && c <= 90
            || c >= 97
            && c <= 122
            || c >= 48
            && c <= 57
            || c == 95
          })
        [] -> False
      }
    }
  }
  let reserved =
    kind == "constructor"
    && list.contains(["False", "True", "Ok", "Error", "Nil"], name)
  case valid && !reserved {
    True -> Ok(Nil)
    False ->
      Error(
        "Invalid or reserved Gleam "
        <> kind
        <> " identifier `"
        <> name
        <> "` from "
        <> identity
        <> " in "
        <> source,
      )
  }
}
