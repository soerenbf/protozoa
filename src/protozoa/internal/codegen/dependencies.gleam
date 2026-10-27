//// Checks dependencies between generated Gleam modules before rendering.
////
//// A field referencing a type in another proto file creates a dependency.
//// Optional, repeated, map and oneof fields are included; unused proto imports
//// and references within the same file do not create dependencies.
////
//// For example, a.proto -> b.proto is allowed, but a.proto -> b.proto ->
//// a.proto is rejected because the generated Gleam imports would be cyclic.
//// Callers can also supply dependencies required by generated extensions.

import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import protozoa/internal/type_registry.{type TypeRegistry}
import protozoa/parser/proto

/// Check the generated file dependency graph in `registry` before rendering or
/// writing. Returns a cycle diagnostic containing source paths, or `Ok(Nil)`.
/// Same-file recursion and unused proto imports do not create edges.
/// Example: `check(registry)`.
pub fn check(registry: TypeRegistry) -> Result(Nil, String) {
  check_with_edges(registry, [])
}

/// Check codec dependencies plus extension source-to-source `edges`.
/// Returns a cycle diagnostic before writes. Example: `check_with_edges(registry, [])`.
pub fn check_with_edges(
  registry: TypeRegistry,
  edges: List(#(String, String)),
) -> Result(Nil, String) {
  let graph =
    list.fold(edges, graph(registry), fn(graph, edge) {
      case edge.0 == edge.1 {
        True -> graph
        False ->
          dict.insert(graph, edge.0, [
            edge.1,
            ..{ dict.get(graph, edge.0) |> result.unwrap([]) }
          ])
      }
    })
  use _ <- result.try(
    list.try_fold(
      dict.keys(graph) |> list.sort(string.compare),
      [],
      fn(done, path) { visit(path, graph, [], done) },
    ),
  )
  Ok(Nil)
}

fn graph(registry: TypeRegistry) -> dict.Dict(String, List(String)) {
  registry.messages
  |> dict.to_list
  |> list.fold(dict.new(), fn(graph, entry) {
    let #(identity, message) = entry
    let assert Ok(source) = dict.get(registry.type_sources, identity)
    let fields =
      list.append(
        message.fields,
        list.flat_map(message.oneofs, fn(oneof) { oneof.fields }),
      )
    let dependencies =
      fields
      |> list.flat_map(fn(field) {
        type_registry.resolve_field_type(registry, field.field_type, identity)
        |> references
      })
      |> list.filter_map(fn(identity) {
        use owner <- result.try(dict.get(registry.type_sources, identity))
        case owner == source {
          True -> Error(Nil)
          False -> Ok(owner)
        }
      })
    let previous = dict.get(graph, source) |> result.unwrap([])
    dict.insert(
      graph,
      source,
      list.append(previous, dependencies)
        |> list.unique
        |> list.sort(string.compare),
    )
  })
}

fn references(field_type: proto.Type) -> List(String) {
  case field_type {
    proto.MessageType(name) | proto.EnumType(name) -> [name]
    proto.Optional(inner) | proto.Repeated(inner) -> references(inner)
    proto.Map(key, value) -> list.append(references(key), references(value))
    _ -> []
  }
}

fn visit(
  path: String,
  graph: dict.Dict(String, List(String)),
  active: List(String),
  done: List(String),
) -> Result(List(String), String) {
  case list.contains(active, path), list.contains(done, path) {
    True, _ ->
      Error(
        "Required generated module dependency cycle: "
        <> string.join(list.append(list.reverse(active), [path]), " -> "),
      )
    False, True -> Ok(done)
    False, False -> {
      use done <- result.try(
        list.try_fold(
          dict.get(graph, path) |> result.unwrap([]),
          done,
          fn(done, dependency) {
            visit(dependency, graph, [path, ..active], done)
          },
        ),
      )
      Ok([path, ..done])
    }
  }
}
