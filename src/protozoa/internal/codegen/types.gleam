//// Type Generation Module
////
//// This module handles generating Gleam type definitions from Protocol Buffer messages.
//// It creates record types, enum types, and oneof types with proper nesting support.

import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import justin
import protozoa/internal/type_registry.{type TypeRegistry}
import protozoa/parser/proto.{
  type Enum, type Field, type FieldOption, type Message, type Type,
}

/// Codegen context - bundles registry, file path, and pre-computed package
pub type Context {
  Context(
    registry: TypeRegistry,
    file_path: String,
    package: String,
    local_names: Bool,
    references: dict.Dict(String, #(String, String, String)),
  )
}

/// Create a context from `registry` and its source `file_path`.
/// Unknown paths use an empty package; never
/// fails. Example: `new_ctx(registry, "messages.proto")`.
pub fn new_ctx(registry: TypeRegistry, file_path: String) -> Context {
  let package = case type_registry.get_file_package(registry, file_path) {
    option.Some(pkg) -> pkg
    option.None -> ""
  }
  Context(
    registry: registry,
    file_path: file_path,
    package: package,
    local_names: False,
    references: dict.new(),
  )
}

/// Build a package-free naming context for `file_path` in `registry`.
/// Resolution retains the original registry/package. Never fails.
/// Example: `new_local_ctx(registry, "items.proto")`.
pub fn new_local_ctx(registry: TypeRegistry, file_path: String) -> Context {
  let ctx = new_ctx(registry, file_path)
  Context(..ctx, local_names: True)
}

fn local_name(name: String, package: String) -> String {
  case package {
    "" -> name
    _ -> string.drop_start(name, string.length(package) + 1)
  }
}

// Reserved Gleam keywords that need to be escaped when used as field names
const gleam_keywords = [
  "case",
  "const",
  "fn",
  "if",
  "import",
  "let",
  "opaque",
  "pub",
  "todo",
  "type",
  "use",
  "assert",
  "try",
  "panic",
  "auto",
  "delegate",
  "derive",
  "echo",
  "else",
  "external",
  "macro",
  "module",
  "test",
  "as",
  "when",
]

/// Escape reserved Gleam keywords by appending underscore
pub fn escape_keyword(name: String) -> String {
  case list.contains(gleam_keywords, name) {
    True -> name <> "_"
    False -> name
  }
}

/// Map a protobuf field name to a Gleam label. `name` is the original label.
/// Never fails. Example: `field_name("specificationHash") == "specification_hash"`.
pub fn field_name(name: String) -> String {
  escape_keyword(justin.snake_case(name))
}

/// Prefix a variant with its generated owning type. Arguments are the rendered
/// owner and protobuf variant. Never fails. Example: `constructor("State", "v0")` is `"StateV0"`.
pub fn constructor(owner: String, variant: String) -> String {
  owner <> capitalize_first(variant)
}

/// Prefix an enum variant with its generated owning type.
/// `owner` is the rendered type, `variant` the proto name; `ctx` is unused.
/// Never fails. Example: `enum_constructor("State", "ZERO", ctx)` returns `"StateZero"`.
pub fn enum_constructor(
  owner: String,
  variant: String,
  _ctx: Context,
) -> String {
  owner <> enum_variant(variant)
}

/// Render uppercase snake enum `name` as PascalCase without stripping prefixes.
/// Mixed-case names retain their spelling. Never fails.
/// Example: `enum_variant("OPEN_STATUS_OPEN_FOR_ALL") == "OpenStatusOpenForAll"`.
pub fn enum_variant(name: String) -> String {
  case name == string.uppercase(name) {
    True ->
      name
      |> string.split("_")
      |> list.map(fn(part) { part |> string.lowercase |> capitalize_first })
      |> string.join("")
    False -> capitalize_first(name)
  }
}

/// Generate all type definitions for a list of messages
pub fn generate_types(messages: List(Message), ctx: Context) -> String {
  let generated_enum_names = set.new()
  let #(all_types, _) =
    messages
    |> list.fold(#([], generated_enum_names), fn(acc, msg) {
      let #(existing_types, seen_enums) = acc
      let #(new_types, updated_enums) = generate_msg_types(msg, ctx, seen_enums)
      #(list.append(existing_types, new_types), updated_enums)
    })

  all_types
  |> string.join("\n\n")
}

/// Generate a single message type and its nested types
pub fn generate_msg_types(
  message: Message,
  ctx: Context,
  seen_enums: set.Set(String),
) -> #(List(String), set.Set(String)) {
  // Generate nested messages first
  let #(nested_types, enums_after_nested) =
    message.nested_messages
    |> list.fold(#([], seen_enums), fn(acc, nested_msg) {
      let #(existing_nested, current_enums) = acc
      let flattened_msg = flatten_nested_message(nested_msg, message)
      let #(new_nested_types, updated_enums) =
        generate_msg_types(flattened_msg, ctx, current_enums)
      #(list.append(existing_nested, new_nested_types), updated_enums)
    })

  // Generate nested enums
  let #(nested_enum_types, enums_after_enum_gen) =
    generate_nested_enum_types(message, ctx, enums_after_nested)

  // Generate oneof types
  let oneof_types =
    message.oneofs
    |> list.map(fn(oneof) { generate_oneof_type(message, oneof, ctx) })

  // Generate the main message type
  let main_type = generate_message_type(message, ctx)

  // Combine all types
  let all_types =
    list.flatten([nested_types, nested_enum_types, oneof_types, [main_type]])

  #(all_types, enums_after_enum_gen)
}

/// Generate enum types for all enums in a list
pub fn generate_enum_types(enums: List(Enum), ctx: Context) -> String {
  enums
  |> list.map(fn(enum) { generate_enum_type(enum, ctx) })
  |> string.join("\n\n")
}

/// Generate a single enum type
pub fn generate_enum_type(enum: Enum, ctx: Context) -> String {
  let type_name = qualified_type(enum.name, ctx)
  let variants =
    enum.values
    |> list.map(fn(variant) {
      "  " <> enum_constructor(type_name, variant.name, ctx)
    })
    |> string.join("\n")

  "pub type " <> type_name <> " {\n" <> variants <> "\n}"
}

/// Generate a single message type
fn generate_message_type(message: Message, ctx: Context) -> String {
  // Get the fully qualified type name for this message
  let type_name = qualified_type(message.name, ctx)

  let fields =
    message.fields
    |> list.map(fn(field) {
      let gleam_type = resolve_field_type(field, ctx, message)
      let escaped_name = field_name(field.name)
      let deprecation_comment = case has_deprecated_option(field.options) {
        True -> " // @deprecated"
        False -> ""
      }
      "    " <> escaped_name <> ": " <> gleam_type <> deprecation_comment
    })

  let oneofs =
    message.oneofs
    |> list.map(fn(oneof) {
      let oneof_type_name = type_name <> capitalize_first(oneof.name)
      let escaped_name = field_name(oneof.name)
      "    " <> escaped_name <> ": option.Option(" <> oneof_type_name <> ")"
    })

  let all_fields = list.append(fields, oneofs)

  case all_fields {
    [] -> "pub type " <> type_name <> " {\n  " <> type_name <> "\n}"
    _ -> {
      let fields_str = string.join(all_fields, ",\n")
      "pub type "
      <> type_name
      <> " {\n  "
      <> type_name
      <> "(\n"
      <> fields_str
      <> ",\n  )\n}"
    }
  }
}

/// Render declaration `name` with containing-message prefixes. A local `ctx`
/// omits the package; a legacy context retains it. Never fails.
/// Example: `qualified_type("Envelope.Item", local_ctx)` is `"EnvelopeItem"`.
pub fn qualified_type(name: String, ctx: Context) -> String {
  // Build fully qualified name and flatten it
  let fqn = case ctx.local_names, ctx.package {
    True, _ -> name
    _, "" -> name
    _, pkg -> pkg <> "." <> name
  }
  flatten_type_name(fqn)
}

/// Render the codec suffix for declaration `name` using `ctx`'s naming mode.
/// Local contexts omit packages but retain containing-message names. Never fails.
/// Example: `qualified_fn("Envelope.Item", local_ctx)` is `"envelope_item"`.
pub fn qualified_fn(name: String, ctx: Context) -> String {
  // Get the qualified type name first
  let type_name = qualified_type(name, ctx)
  // Convert to snake_case
  justin.snake_case(type_name)
}

/// Generate oneof type
fn generate_oneof_type(
  parent_message: Message,
  oneof: proto.Oneof,
  ctx: Context,
) -> String {
  // Get qualified parent type name and append oneof name
  let parent_type_name = qualified_type(parent_message.name, ctx)
  let type_name = parent_type_name <> capitalize_first(oneof.name)
  let variants =
    oneof.fields
    |> list.map(fn(field) {
      let scope =
        type_registry.make_fully_qualified_name(
          ctx.package,
          parent_message.name,
        )
      let resolved =
        type_registry.resolve_field_type(ctx.registry, field.field_type, scope)
      let gleam_type = resolve_type(resolved, ctx)
      let variant_name = constructor(type_name, field.name)
      "  " <> variant_name <> "(" <> gleam_type <> ")"
    })
    |> string.join("\n")

  "pub type " <> type_name <> " {\n" <> variants <> "\n}"
}

// Helper functions

/// Check if field has deprecated option set to true
fn has_deprecated_option(options: List(FieldOption)) -> Bool {
  list.any(options, fn(option) {
    case option {
      proto.Deprecated(True) -> True
      _ -> False
    }
  })
}

fn flatten_nested_message(nested_msg: Message, parent: Message) -> Message {
  proto.Message(..nested_msg, name: parent.name <> "." <> nested_msg.name)
}

fn generate_nested_enum_types(
  message: Message,
  ctx: Context,
  seen_enums: set.Set(String),
) -> #(List(String), set.Set(String)) {
  message.nested_enums
  |> list.fold(#([], seen_enums), fn(acc, nested_enum) {
    let #(existing_enum_types, current_enums) = acc
    let flattened_name = message.name <> "." <> nested_enum.name

    case set.contains(current_enums, flattened_name) {
      True -> acc
      False -> {
        let flattened_enum =
          proto.Enum(name: flattened_name, values: nested_enum.values)
        let enum_code = generate_enum_type(flattened_enum, ctx)
        let updated_enums = set.insert(current_enums, flattened_name)
        #(list.append(existing_enum_types, [enum_code]), updated_enums)
      }
    }
  })
}

fn resolve_field_type(
  field: Field,
  ctx: Context,
  parent_message: Message,
) -> String {
  let scope =
    type_registry.make_fully_qualified_name(ctx.package, parent_message.name)
  let resolved =
    type_registry.resolve_field_type(ctx.registry, field.field_type, scope)
  case resolved {
    proto.MessageType(_) ->
      "option.Option(" <> resolve_type(resolved, ctx) <> ")"
    _ -> resolve_type(resolved, ctx)
  }
}

pub fn resolve_type(proto_type: Type, ctx: Context) -> String {
  case proto_type {
    proto.String -> "String"
    proto.Int32 -> "Int"
    proto.Int64 -> "Int"
    proto.UInt32 -> "Int"
    proto.UInt64 -> "Int"
    proto.SInt32 -> "Int"
    proto.SInt64 -> "Int"
    proto.Fixed32 -> "Int"
    proto.Fixed64 -> "Int"
    proto.SFixed32 -> "Int"
    proto.SFixed64 -> "Int"
    proto.Bool -> "Bool"
    proto.Bytes -> "BitArray"
    proto.Double -> "Float"
    proto.Float -> "Float"
    proto.MessageType(name) -> resolve_external_type(name, ctx)
    proto.EnumType(name) -> resolve_external_type(name, ctx)
    proto.Repeated(inner) -> "List(" <> resolve_type(inner, ctx) <> ")"
    proto.Optional(inner) -> "option.Option(" <> resolve_type(inner, ctx) <> ")"
    proto.Map(key, value) ->
      "List(#("
      <> resolve_type(key, ctx)
      <> ", "
      <> resolve_type(value, ctx)
      <> "))"
  }
}

fn resolve_external_type(name: String, ctx: Context) -> String {
  // Field references have already been resolved in their original lexical scope.
  case dict.get(ctx.references, name) {
    Ok(#(local, _, qualifier)) -> qualifier <> local
    Error(_) -> {
      case dict.has_key(ctx.registry.type_sources, name) {
        True -> flatten_type_name(name)
        False ->
          case
            type_registry.resolve_type_reference(
              ctx.registry,
              name,
              ctx.package,
            )
          {
            Ok(identity) -> flatten_type_name(identity)
            Error(error) -> panic as error
          }
      }
    }
  }
}

pub fn flatten_type_name(name: String) -> String {
  // Handle well-known types
  case name {
    "google.protobuf.Timestamp" -> "Timestamp"
    "google.protobuf.Duration" -> "Duration"
    "google.protobuf.FieldMask" -> "FieldMask"
    "google.protobuf.Empty" -> "Empty"
    "google.protobuf.Any" -> "Any"
    "google.protobuf.Struct" -> "Struct"
    "google.protobuf.Value" -> "Value"
    "google.protobuf.ListValue" -> "ListValue"
    "google.protobuf.NullValue" -> "NullValue"
    "google.protobuf.DoubleValue" -> "DoubleValue"
    "google.protobuf.FloatValue" -> "FloatValue"
    "google.protobuf.Int64Value" -> "Int64Value"
    "google.protobuf.UInt64Value" -> "UInt64Value"
    "google.protobuf.Int32Value" -> "Int32Value"
    "google.protobuf.UInt32Value" -> "UInt32Value"
    "google.protobuf.BoolValue" -> "BoolValue"
    "google.protobuf.StringValue" -> "StringValue"
    "google.protobuf.BytesValue" -> "BytesValue"
    // Types from source_context.proto
    "google.protobuf.SourceContext" -> "SourceContext"
    // Types from type.proto
    "google.protobuf.Type" -> "Type"
    "google.protobuf.Field" -> "Field"
    "google.protobuf.Enum" -> "Enum"
    "google.protobuf.EnumValue" -> "EnumValue"
    "google.protobuf.Option" -> "Option"
    "google.protobuf.Syntax" -> "Syntax"
    "google.protobuf.FieldKind" -> "FieldKind"
    "google.protobuf.FieldCardinality" -> "FieldCardinality"
    // Types from api.proto
    "google.protobuf.Api" -> "Api"
    "google.protobuf.Method" -> "Method"
    "google.protobuf.Mixin" -> "Mixin"
    _ -> {
      // Convert dotted names like "base.BaseMessage" to "BaseBaseMessage"
      // Each part needs to be capitalized when joined
      name
      |> string.split(".")
      |> list.map(capitalize_first)
      |> string.join("")
    }
  }
}

pub fn capitalize_first(str: String) -> String {
  // Convert snake_case to PascalCase
  str
  |> string.split("_")
  |> list.map(fn(part) {
    case string.pop_grapheme(part) {
      Ok(#(first, rest)) -> string.uppercase(first) <> rest
      Error(_) -> part
    }
  })
  |> string.join("")
}

/// Render a codec reference to resolved protobuf `identity` in `ctx`, with the
/// supplied function `prefix` and `suffix`. Legacy contexts keep flattened names.
/// Never fails for validated schemas. Example: `codec("pkg.Item", "encode_", "", ctx)`.
pub fn codec(
  identity: String,
  prefix: String,
  suffix: String,
  ctx: Context,
) -> String {
  case dict.get(ctx.references, identity) {
    Ok(#(_, name, qualifier)) -> qualifier <> prefix <> name <> suffix
    Error(_) ->
      prefix <> justin.snake_case(flatten_type_name(identity)) <> suffix
  }
}

/// Name the private oneof decoder for local `owner` and protobuf `field`.
/// Never fails. Example: `oneof_decoder_name("Foo", "bar")`.
pub fn oneof_decoder_name(owner: String, field: String) -> String {
  "oneof_"
  <> justin.snake_case(owner)
  <> "_"
  <> justin.snake_case(field)
  <> "_decoder"
}

/// Name a map helper from its message codec `suffix` and decimal field `number`.
/// Never fails. Example: `map_decoder_name("foo", "1")`.
pub fn map_decoder_name(suffix: String, number: String) -> String {
  suffix <> "_map_entry_" <> number <> "_decoder"
}
