//// Encoder Generation Module
////
//// This module handles generating Gleam encoding functions for Protocol Buffer messages.
//// It creates functions that convert Gleam values to binary Protocol Buffer format.

import gleam/int
import gleam/list
import gleam/set
import gleam/string
import protozoa/internal/codegen/types.{type Context, capitalize_first}
import protozoa/internal/type_registry
import protozoa/parser/proto.{type Field, type Message, type Type}

/// Generate all encoders for a list of messages
pub fn generate_encoders(messages: List(Message), ctx: Context) -> String {
  let all_messages = collect_all_messages_flattened(messages)

  // Resolve enum types in all messages
  let resolved_messages =
    list.map(all_messages, fn(msg) { resolve_message_types(msg, ctx) })

  resolved_messages
  |> list.map(fn(message) { generate_encoder(message, ctx) })
  |> string.join("\n\n")
}

/// Resolve field types in a message (convert MessageType to EnumType if needed)
fn resolve_message_types(msg: Message, ctx: Context) -> Message {
  let resolved_fields =
    list.map(msg.fields, fn(field) {
      proto.Field(
        ..field,
        field_type: type_registry.resolve_field_type(
          ctx.registry,
          field.field_type,
          type_registry.make_fully_qualified_name(ctx.package, msg.name),
        ),
      )
    })

  let resolved_oneofs =
    list.map(msg.oneofs, fn(oneof) {
      let resolved_oneof_fields =
        list.map(oneof.fields, fn(field) {
          proto.Field(
            ..field,
            field_type: type_registry.resolve_field_type(
              ctx.registry,
              field.field_type,
              type_registry.make_fully_qualified_name(ctx.package, msg.name),
            ),
          )
        })
      proto.Oneof(..oneof, fields: resolved_oneof_fields)
    })

  proto.Message(..msg, fields: resolved_fields, oneofs: resolved_oneofs)
}

/// Generate encoder for a single message
pub fn generate_encoder(message: Message, ctx: Context) -> String {
  // Get qualified names for function and type
  let qualified_fn_name = types.qualified_fn(message.name, ctx)
  let qualified_type_name = types.qualified_type(message.name, ctx)
  let function_name = "encode_" <> qualified_fn_name
  let is_empty = list.is_empty(message.fields) && list.is_empty(message.oneofs)

  // Field temporaries end in _fields; helper payloads use value, oneof_value,
  // v, pair, and key, so none can shadow this schema-independent argument.
  let param_name = case is_empty {
    True -> "_message"
    False -> "message"
  }

  // Separate different field types
  let #(repeated_and_map_fields, regular_fields) =
    list.partition(message.fields, fn(field) {
      case field.field_type {
        proto.Repeated(_) -> True
        proto.Map(_, _) -> True
        _ -> False
      }
    })

  let #(map_fields, repeated_fields) =
    list.partition(repeated_and_map_fields, fn(field) {
      case field.field_type {
        proto.Map(_, _) -> True
        _ -> False
      }
    })

  // Generate different types of encoders
  let regular_encoders =
    generate_regular_field_encoders(regular_fields, param_name, ctx)
  let oneof_encoders =
    generate_oneof_encoders(
      message.oneofs,
      qualified_type_name,
      param_name,
      ctx,
    )
  let repeated_code =
    generate_repeated_fields_code(repeated_fields, param_name, ctx)
  let map_code = generate_map_fields_code(map_fields, param_name, ctx)

  // Build the function body
  let body =
    build_encoder_body(
      repeated_fields,
      map_fields,
      regular_encoders,
      oneof_encoders,
      repeated_code,
      map_code,
    )

  "pub fn "
  <> function_name
  <> "("
  <> param_name
  <> ": "
  <> qualified_type_name
  <> ") -> BitArray {\n"
  <> body
  <> "\n}"
}

/// Generate enum helper encoders
pub fn generate_enum_helpers(
  top_level_enums: List(proto.Enum),
  messages: List(Message),
  ctx: Context,
) -> String {
  let all_enums = collect_all_enums_flattened(top_level_enums, messages)
  let enums_in_oneofs = collect_enum_names_in_oneofs(messages, ctx)

  all_enums
  |> list.map(fn(enum) { generate_enum_helper(enum, enums_in_oneofs, ctx) })
  |> string.join("\n\n")
}

/// Collect enums needing a field decoder for oneof or optional presence.
fn collect_enum_names_in_oneofs(
  messages: List(Message),
  ctx: Context,
) -> set.Set(String) {
  let all_messages =
    collect_all_messages_flattened(messages)
    |> list.map(fn(msg) { resolve_message_types(msg, ctx) })
  list.fold(all_messages, set.new(), fn(acc, msg) {
    let acc =
      list.fold(msg.fields, acc, fn(field_acc, field) {
        case field.field_type {
          proto.Optional(proto.EnumType(name)) ->
            set.insert(field_acc, types.resolve_type(proto.EnumType(name), ctx))
          _ -> field_acc
        }
      })
    list.fold(msg.oneofs, acc, fn(inner_acc, oneof) {
      list.fold(oneof.fields, inner_acc, fn(field_acc, field) {
        case field.field_type {
          proto.EnumType(name) ->
            set.insert(field_acc, types.resolve_type(proto.EnumType(name), ctx))
          _ -> field_acc
        }
      })
    })
  })
}

// Helper functions

fn generate_regular_field_encoders(
  fields: List(Field),
  param_name: String,
  ctx: Context,
) -> List(String) {
  // Field types are already resolved by resolve_message_types in generate_encoders
  fields
  |> list.map(fn(field) { generate_field_encoder(field, param_name, ctx) })
}

fn generate_oneof_encoders(
  oneofs: List(proto.Oneof),
  message_name: String,
  param_name: String,
  ctx: Context,
) -> List(String) {
  oneofs
  |> list.map(fn(oneof) {
    generate_oneof_encoder(message_name, oneof, param_name, ctx)
  })
}

fn generate_repeated_fields_code(
  fields: List(Field),
  param_name: String,
  ctx: Context,
) -> String {
  case fields {
    [] -> ""
    _ -> {
      fields
      |> list.map(fn(field) {
        generate_repeated_field_code(field, param_name, ctx)
      })
      |> string.join("\n  ")
    }
  }
}

fn generate_map_fields_code(
  fields: List(Field),
  param_name: String,
  ctx: Context,
) -> String {
  case fields {
    [] -> ""
    _ -> {
      fields
      |> list.map(fn(field) { generate_map_field_code(field, param_name, ctx) })
      |> string.join("\n  ")
    }
  }
}

fn build_encoder_body(
  repeated_fields: List(Field),
  map_fields: List(Field),
  regular_encoders: List(String),
  oneof_encoders: List(String),
  repeated_code: String,
  map_code: String,
) -> String {
  let repeated_field_vars =
    repeated_fields
    |> list.map(fn(field) { types.field_name(field.name) <> "_fields" })

  let map_field_vars =
    map_fields
    |> list.map(fn(field) { types.field_name(field.name) <> "_fields" })

  let all_vars = list.flatten([repeated_field_vars, map_field_vars])
  let all_regular = list.append(regular_encoders, oneof_encoders)

  case all_vars, all_regular, repeated_code, map_code {
    [], [], "", "" -> "  encode.message([])"
    [], encoders, "", "" ->
      "  encode.message([\n    "
      <> string.join(encoders, ",\n    ")
      <> ",\n  ])"
    vars, [], code1, code2 -> {
      let code = case code1, code2 {
        "", c2 -> "  " <> c2
        c1, "" -> "  " <> c1
        c1, c2 -> "  " <> c1 <> "\n  " <> c2
      }
      code <> "\n  encode.message(" <> build_list_flattening(vars) <> ")"
    }
    vars, encoders, code1, code2 -> {
      let code = case code1, code2 {
        "", c2 -> "  " <> c2
        c1, "" -> "  " <> c1
        c1, c2 -> "  " <> c1 <> "\n  " <> c2
      }
      let individual_encoders =
        list.map(encoders, fn(enc) { "[" <> enc <> "]" })
      let concat_expr =
        build_list_flattening(list.append(vars, individual_encoders))
      code <> "\n  encode.message(" <> concat_expr <> ")"
    }
  }
}

fn build_list_flattening(vars: List(String)) -> String {
  case vars {
    [] -> "[]"
    [single] -> single
    _ -> "list.flatten([" <> string.join(vars, ", ") <> "])"
  }
}

fn generate_field_encoder(
  field: Field,
  param_name: String,
  ctx: Context,
) -> String {
  let escaped_field_name = types.field_name(field.name)
  let field_access = param_name <> "." <> escaped_field_name
  let field_num = int.to_string(field.number)

  case field.field_type {
    proto.Optional(inner) ->
      generate_optional_field_encoder_typed(inner, field_access, field_num, ctx)
    proto.MessageType(_) ->
      generate_optional_field_encoder_typed(
        field.field_type,
        field_access,
        field_num,
        ctx,
      )
    proto.Repeated(_) -> "// Repeated fields handled separately"
    _ ->
      generate_required_field_encoder(
        field.field_type,
        field_access,
        field_num,
        ctx,
      )
  }
}

fn generate_required_field_encoder(
  proto_type: Type,
  access: String,
  field_num: String,
  ctx: Context,
) -> String {
  case proto_type {
    proto.String -> "encode.string_field(" <> field_num <> ", " <> access <> ")"
    proto.Int32 -> "encode.int32_field(" <> field_num <> ", " <> access <> ")"
    proto.Int64 -> "encode.int64_field(" <> field_num <> ", " <> access <> ")"
    proto.UInt32 -> "encode.uint32_field(" <> field_num <> ", " <> access <> ")"
    proto.UInt64 -> "encode.uint64_field(" <> field_num <> ", " <> access <> ")"
    proto.SInt32 -> "encode.sint32_field(" <> field_num <> ", " <> access <> ")"
    proto.SInt64 -> "encode.sint64_field(" <> field_num <> ", " <> access <> ")"
    proto.Fixed32 ->
      "encode.fixed32_field(" <> field_num <> ", " <> access <> ")"
    proto.Fixed64 ->
      "encode.fixed64_field(" <> field_num <> ", " <> access <> ")"
    proto.SFixed32 ->
      "encode.sfixed32_field(" <> field_num <> ", " <> access <> ")"
    proto.SFixed64 ->
      "encode.sfixed64_field(" <> field_num <> ", " <> access <> ")"
    proto.Bool -> "encode.bool_field(" <> field_num <> ", " <> access <> ")"
    proto.Bytes ->
      "encode.field("
      <> field_num
      <> ", wire.LengthDelimited, encode.length_delimited("
      <> access
      <> "))"
    proto.Float -> "encode.float_field(" <> field_num <> ", " <> access <> ")"
    proto.Double -> "encode.double_field(" <> field_num <> ", " <> access <> ")"
    proto.MessageType(_) ->
      "encode.field("
      <> field_num
      <> ", wire.LengthDelimited, encode.length_delimited("
      <> types.codec(get_type_name(proto_type), "encode_", "", ctx)
      <> "("
      <> access
      <> ")))"
    proto.EnumType(_) ->
      "encode.int32_field("
      <> field_num
      <> ", "
      <> types.codec(get_type_name(proto_type), "encode_", "_value", ctx)
      <> "("
      <> access
      <> "))"
    _ -> "// Unsupported type: " <> string.inspect(proto_type)
  }
}

fn generate_optional_field_encoder_typed(
  inner_type: Type,
  access: String,
  field_num: String,
  ctx: Context,
) -> String {
  "case "
  <> access
  <> " {\n      option.Some(value) -> "
  <> generate_required_field_encoder(inner_type, "value", field_num, ctx)
  <> "\n      option.None -> <<>>\n    }"
}

fn generate_oneof_encoder(
  message_name: String,
  oneof: proto.Oneof,
  param_name: String,
  ctx: Context,
) -> String {
  let escaped_oneof_name = types.field_name(oneof.name)
  let oneof_access = param_name <> "." <> escaped_oneof_name
  let type_name = capitalize_first(message_name) <> capitalize_first(oneof.name)

  let cases =
    oneof.fields
    |> list.map(fn(field) {
      let field_num = int.to_string(field.number)
      let variant_name = types.constructor(type_name, field.name)
      let encoder =
        generate_required_field_encoder(
          field.field_type,
          "value",
          field_num,
          ctx,
        )
      "      " <> variant_name <> "(value) -> " <> encoder
    })
    |> string.join("\n")

  "case "
  <> oneof_access
  <> " {\n      option.Some(oneof_value) -> {\n        case oneof_value {\n"
  <> cases
  <> "\n        }\n      }\n      option.None -> <<>>\n    }"
}

fn generate_repeated_field_code(
  field: Field,
  param_name: String,
  ctx: Context,
) -> String {
  let escaped_field_name = types.field_name(field.name)
  let field_name = escaped_field_name
  let var_name = field_name <> "_fields"
  let field_access = param_name <> "." <> escaped_field_name
  let field_num = int.to_string(field.number)

  case field.field_type {
    proto.Repeated(inner_type) -> {
      let encoder = generate_repeated_item_encoder(inner_type, field_num, ctx)
      "let "
      <> var_name
      <> " = list.map("
      <> field_access
      <> ", fn(v) { "
      <> encoder
      <> " })"
    }
    _ -> "// Not a repeated field"
  }
}

fn generate_repeated_item_encoder(
  proto_type: Type,
  field_num: String,
  ctx: Context,
) -> String {
  case proto_type {
    proto.String -> "encode.string_field(" <> field_num <> ", v)"
    proto.Int32 -> "encode.int32_field(" <> field_num <> ", v)"
    proto.Bool -> "encode.bool_field(" <> field_num <> ", v)"
    proto.Bytes ->
      "encode.field("
      <> field_num
      <> ", wire.LengthDelimited, encode.length_delimited(v))"
    proto.MessageType(_) ->
      "encode.field("
      <> field_num
      <> ", wire.LengthDelimited, encode.length_delimited("
      <> types.codec(get_type_name(proto_type), "encode_", "", ctx)
      <> "(v)))"
    proto.EnumType(_) ->
      "encode.int32_field("
      <> field_num
      <> ", "
      <> types.codec(get_type_name(proto_type), "encode_", "_value", ctx)
      <> "(v))"
    _ -> "encode.string_field(" <> field_num <> ", \"unsupported\")"
  }
}

fn generate_map_field_code(
  field: Field,
  param_name: String,
  ctx: Context,
) -> String {
  let escaped_field_name = types.field_name(field.name)
  let field_name = escaped_field_name
  let var_name = field_name <> "_fields"
  let field_access = param_name <> "." <> escaped_field_name
  let field_num = int.to_string(field.number)

  case field.field_type {
    proto.Map(key_type, value_type) -> {
      let key_encoder = generate_map_key_encoder(key_type)
      let value_encoder = generate_map_value_encoder(value_type, ctx)
      "let "
      <> var_name
      <> " = list.map("
      <> field_access
      <> ", fn(pair) { let #(key, value) = pair\n    encode.field("
      <> field_num
      <> ", wire.LengthDelimited, encode.length_delimited(encode.message(["
      <> key_encoder
      <> ", "
      <> value_encoder
      <> "]))) })"
    }
    _ -> "let " <> var_name <> " = [] // Not a map field"
  }
}

fn generate_map_key_encoder(proto_type: Type) -> String {
  case proto_type {
    proto.String -> "encode.string_field(1, key)"
    proto.Int32 -> "encode.int32_field(1, key)"
    proto.Int64 -> "encode.int64_field(1, key)"
    proto.UInt32 -> "encode.uint32_field(1, key)"
    proto.UInt64 -> "encode.uint64_field(1, key)"
    proto.SInt32 -> "encode.sint32_field(1, key)"
    proto.SInt64 -> "encode.sint64_field(1, key)"
    proto.Fixed32 -> "encode.fixed32_field(1, key)"
    proto.Fixed64 -> "encode.fixed64_field(1, key)"
    proto.SFixed32 -> "encode.sfixed32_field(1, key)"
    proto.SFixed64 -> "encode.sfixed64_field(1, key)"
    proto.Bool -> "encode.bool_field(1, key)"
    _ -> "encode.string_field(1, key)"
  }
}

fn generate_map_value_encoder(proto_type: Type, ctx: Context) -> String {
  case proto_type {
    proto.String -> "encode.string_field(2, value)"
    proto.Int32 -> "encode.int32_field(2, value)"
    proto.Int64 -> "encode.int64_field(2, value)"
    proto.UInt32 -> "encode.uint32_field(2, value)"
    proto.UInt64 -> "encode.uint64_field(2, value)"
    proto.SInt32 -> "encode.sint32_field(2, value)"
    proto.SInt64 -> "encode.sint64_field(2, value)"
    proto.Fixed32 -> "encode.fixed32_field(2, value)"
    proto.Fixed64 -> "encode.fixed64_field(2, value)"
    proto.SFixed32 -> "encode.sfixed32_field(2, value)"
    proto.SFixed64 -> "encode.sfixed64_field(2, value)"
    proto.Bool -> "encode.bool_field(2, value)"
    proto.Bytes ->
      "encode.field(2, wire.LengthDelimited, encode.length_delimited(value))"
    proto.Float -> "encode.float_field(2, value)"
    proto.Double -> "encode.double_field(2, value)"
    proto.MessageType(name) ->
      "encode.field(2, wire.LengthDelimited, encode.length_delimited("
      <> types.codec(name, "encode_", "", ctx)
      <> "(value)))"
    proto.EnumType(name) ->
      "encode.int32_field(2, "
      <> types.codec(name, "encode_", "_value", ctx)
      <> "(value))"
    _ -> "encode.string_field(2, value)"
  }
}

fn generate_enum_helper(
  enum: proto.Enum,
  enums_in_oneofs: set.Set(String),
  ctx: Context,
) -> String {
  // Get qualified names for the enum
  let qualified_type_name = types.qualified_type(enum.name, ctx)
  let qualified_fn_name = types.qualified_fn(enum.name, ctx)

  let encoder_function =
    generate_enum_encoder(enum, qualified_type_name, qualified_fn_name, ctx)
  let decoder_function =
    generate_enum_decoder(
      enum,
      enums_in_oneofs,
      qualified_type_name,
      qualified_fn_name,
      ctx,
    )
  let value_decoder_function =
    generate_enum_value_decoder(
      enum,
      qualified_type_name,
      qualified_fn_name,
      ctx,
    )
  let repeated_decoder_function =
    generate_repeated_enum_decoder(enum, qualified_type_name, qualified_fn_name)
  encoder_function
  <> "\n\n"
  <> decoder_function
  <> "\n\n"
  <> value_decoder_function
  <> "\n\n"
  <> repeated_decoder_function
}

fn generate_enum_encoder(
  enum: proto.Enum,
  qualified_type_name: String,
  qualified_fn_name: String,
  ctx: Context,
) -> String {
  let function_name = "encode_" <> qualified_fn_name <> "_value"
  let cases =
    enum.values
    |> list.map(fn(variant) {
      let variant_name =
        types.enum_constructor(qualified_type_name, variant.name, ctx)
      "    " <> variant_name <> " -> " <> int.to_string(variant.number)
    })
    |> string.join("\n")

  "pub fn "
  <> function_name
  <> "(value: "
  <> qualified_type_name
  <> ") -> Int {\n  case value {\n"
  <> cases
  <> "\n  }\n}"
}

fn generate_enum_decoder(
  enum: proto.Enum,
  enums_in_oneofs: set.Set(String),
  qualified_type_name: String,
  qualified_fn_name: String,
  ctx: Context,
) -> String {
  let function_name = "decode_" <> qualified_fn_name <> "_field"
  let decode_cases =
    enum.values
    |> list.map(fn(variant) {
      let variant_name =
        types.enum_constructor(qualified_type_name, variant.name, ctx)
      "          "
      <> int.to_string(variant.number)
      <> " -> Ok("
      <> variant_name
      <> ")"
    })
    |> string.join("\n")

  let default = case enum.values {
    [first, ..] -> types.enum_constructor(qualified_type_name, first.name, ctx)
    [] -> qualified_type_name
  }
  let main_decoder =
    "pub fn "
    <> function_name
    <> "(field_num: Int) -> decode.Decoder("
    <> qualified_type_name
    <> ") {\n"
    <> "  decode.field_with_default(field_num, fn(field) {\n"
    <> "    use value <- result.try(decode.int32_field(field))\n"
    <> "    case value {\n"
    <> decode_cases
    <> "\n"
    <> "      _ -> Error(decode.DecodeError(expected: \"valid "
    <> string.lowercase(qualified_fn_name)
    <> " value\", found: \"Unknown "
    <> string.lowercase(qualified_fn_name)
    <> " value: \" <> string.inspect(value), path: []))\n"
    <> "    }\n"
    <> "  }, "
    <> default
    <> ")\n"
    <> "}"

  // Optional fields and oneofs both decode an enum from a runtime field.
  case ctx.local_names || set.contains(enums_in_oneofs, qualified_type_name) {
    True ->
      main_decoder
      <> "\n\n"
      <> generate_enum_field_decoder(
        enum,
        qualified_type_name,
        qualified_fn_name,
        ctx,
      )
    False -> main_decoder
  }
}

fn generate_enum_field_decoder(
  enum: proto.Enum,
  qualified_type_name: String,
  qualified_fn_name: String,
  ctx: Context,
) -> String {
  let function_name = "decode_" <> qualified_fn_name <> "_from_field"
  let decode_cases =
    enum.values
    |> list.map(fn(variant) {
      let variant_name =
        types.enum_constructor(qualified_type_name, variant.name, ctx)
      "      "
      <> int.to_string(variant.number)
      <> " -> Ok("
      <> variant_name
      <> ")"
    })
    |> string.join("\n")

  {
    case ctx.local_names {
      True -> "pub fn "
      False -> "fn "
    }
  }
  <> function_name
  <> "(field: decode.Field) -> Result("
  <> qualified_type_name
  <> ", decode.DecodeError) {\n"
  <> "  use value <- result.try(decode.int32_field(field))\n"
  <> "  case value {\n"
  <> decode_cases
  <> "\n"
  <> "    _ -> Error(decode.DecodeError(expected: \"valid "
  <> string.lowercase(qualified_fn_name)
  <> " value\", found: \"Unknown "
  <> string.lowercase(qualified_fn_name)
  <> " value: \" <> string.inspect(value), path: []))\n"
  <> "  }\n"
  <> "}"
}

fn generate_enum_value_decoder(
  enum: proto.Enum,
  qualified_type_name: String,
  qualified_fn_name: String,
  ctx: Context,
) -> String {
  let function_name = "decode_" <> qualified_fn_name <> "_value"
  let decode_cases =
    enum.values
    |> list.map(fn(variant) {
      let variant_name =
        types.enum_constructor(qualified_type_name, variant.name, ctx)
      "    "
      <> int.to_string(variant.number)
      <> " -> Ok("
      <> variant_name
      <> ")"
    })
    |> string.join("\n")

  "pub fn "
  <> function_name
  <> "(value: Int) -> Result("
  <> qualified_type_name
  <> ", String) {\n"
  <> "  case value {\n"
  <> decode_cases
  <> "\n"
  <> "    _ -> Error(\"Unknown "
  <> string.lowercase(qualified_fn_name)
  <> " value: \" <> int.to_string(value))\n"
  <> "  }\n"
  <> "}"
}

fn generate_repeated_enum_decoder(
  _enum: proto.Enum,
  qualified_type_name: String,
  qualified_fn_name: String,
) -> String {
  let function_name = "decode_repeated_" <> qualified_fn_name

  "pub fn "
  <> function_name
  <> "(field_num: Int) -> decode.Decoder(List("
  <> qualified_type_name
  <> ")) {\n"
  <> "  use values <- decode.then(decode.repeated_int32(field_num))\n"
  <> "  case list.try_map(values, decode_"
  <> qualified_fn_name
  <> "_value) {\n"
  <> "    Ok(values) -> decode.success(values)\n"
  <> "    Error(err) -> decode.fail(\""
  <> string.lowercase(qualified_fn_name)
  <> "\", err, [])\n"
  <> "  }\n"
  <> "}"
}

// Utility functions that should be extracted from the main module

fn collect_all_messages_flattened(messages: List(Message)) -> List(Message) {
  list.fold(messages, [], fn(acc, msg) {
    // Recursively flatten nested messages (updating message names only, not field types)
    // Field type resolution is handled separately by resolve_message_types using the registry
    let flattened_nested =
      flatten_nested_messages_simple(msg.nested_messages, msg.name)

    [msg, ..list.append(flattened_nested, acc)]
  })
}

/// Flatten nested messages by prepending parent name to message name
/// Does NOT modify field types - that's handled by resolve_message_types
fn flatten_nested_messages_simple(
  nested_messages: List(Message),
  parent_name: String,
) -> List(Message) {
  list.fold(nested_messages, [], fn(acc, nested_msg) {
    let flattened_name = parent_name <> "." <> nested_msg.name

    // Create the flattened message
    let flattened_msg = proto.Message(..nested_msg, name: flattened_name)

    // Recursively handle deeper nesting
    let deeper_nested =
      flatten_nested_messages_simple(nested_msg.nested_messages, flattened_name)

    [flattened_msg, ..list.append(deeper_nested, acc)]
  })
}

fn collect_all_enums_flattened(
  top_level_enums: List(proto.Enum),
  messages: List(Message),
) -> List(proto.Enum) {
  let nested_enums =
    messages
    |> list.fold([], fn(acc, msg) {
      list.append(
        acc,
        collect_nested_enums_flattened(
          msg.nested_enums,
          msg.nested_messages,
          msg.name,
        ),
      )
    })

  list.append(top_level_enums, nested_enums)
}

fn collect_nested_enums_flattened(
  enums: List(proto.Enum),
  nested_messages: List(Message),
  parent_name: String,
) -> List(proto.Enum) {
  let current_enums =
    enums
    |> list.map(fn(enum) {
      proto.Enum(..enum, name: parent_name <> "." <> enum.name)
    })

  let deeper_enums =
    nested_messages
    |> list.fold([], fn(acc, nested_msg) {
      let nested_name = parent_name <> "." <> nested_msg.name
      list.append(
        acc,
        collect_nested_enums_flattened(
          nested_msg.nested_enums,
          nested_msg.nested_messages,
          nested_name,
        ),
      )
    })

  list.append(current_enums, deeper_enums)
}

fn get_type_name(proto_type: Type) -> String {
  case proto_type {
    proto.MessageType(name) -> name
    proto.EnumType(name) -> name
    _ -> "UnknownType"
  }
}
