//// Full Proto File Parser with Validation
//// 
//// This module provides the complete parser for .proto files including:
//// - Lexing and parsing
//// - Field number validation
//// - Duplicate field number detection
//// - EnumType vs MessageType distinction

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string
import nibble
import nibble/lexer
import protozoa/parser/combinator as c
import protozoa/parser/lexer as proto_lexer
import protozoa/parser/proto
import protozoa/parser/token

pub type Path {
  Path(path: String, content: ProtoFile)
}

pub type ProtoFile {
  ProtoFile(
    syntax: String,
    package: Option(String),
    imports: List(proto.Import),
    messages: List(proto.Message),
    enums: List(proto.Enum),
    services: List(proto.Service),
  )
}

pub type ParseError {
  LexError(lexer.Error)
  ParseError(List(nibble.DeadEnd(token.ProtoToken, Nil)))
  InvalidFieldNumber(message: String, field: String, number: Int)
  DuplicateFieldNumber(message: String, number: Int)
}

type TopLevelItem {
  ItemMessage(proto.Message)
  ItemEnum(proto.Enum)
  ItemService(proto.Service)
  ItemPackage(String)
  ItemImport(proto.Import)
  ItemOption
}

/// Describe `error`, including token positions for syntax failures.
/// Returns a diagnostic string; this function does not fail.
/// Example: `describe_error(InvalidFieldNumber("A", "x", 0))`.
pub fn describe_error(error: ParseError) -> String {
  case error {
    LexError(lex_error) ->
      case lex_error {
        lexer.NoMatchFound(row, col, lexeme) ->
          "Lexer error at "
          <> int.to_string(row)
          <> ":"
          <> int.to_string(col)
          <> " - no match for: "
          <> lexeme
      }
    ParseError(dead_ends) -> {
      "Parse error: "
      <> string.join(list.map(dead_ends, describe_dead_end), "; ")
    }
    InvalidFieldNumber(message, field, number) ->
      "Invalid field number "
      <> int.to_string(number)
      <> " for field '"
      <> field
      <> "' in message '"
      <> message
      <> "'. Field numbers must be positive (> 0)."
    DuplicateFieldNumber(message, number) ->
      "Duplicate field number "
      <> int.to_string(number)
      <> " in message '"
      <> message
      <> "'"
  }
}

fn describe_dead_end(
  dead_end: nibble.DeadEnd(token.ProtoToken, Nil),
) -> String {
  let problem = case dead_end.problem {
    nibble.BadParser(message) | nibble.Custom(message) -> message
    nibble.EndOfInput -> "unexpected end of input"
    nibble.Expected(expected, got) ->
      "expected " <> expected <> ", got " <> token.describe(got)
    nibble.Unexpected(got) -> "unexpected " <> token.describe(got)
  }
  int.to_string(dead_end.pos.row_start)
  <> ":"
  <> int.to_string(dead_end.pos.col_start)
  <> " - "
  <> problem
}

// ---- MAIN PARSER ----

/// Parse all of `content` as proto3 source, preserving declaration and field order.
/// Returns lexical, syntax (including unsupported or incomplete input), or field
/// validation errors. File language options and reservations are consumed but not
/// represented in the codec-oriented AST.
/// Example: `parse("syntax = 'proto3'; message A { string x = 1; }")`.
pub fn parse(content: String) -> Result(ProtoFile, ParseError) {
  // Step 1: Lex
  use tokens <- result.try(
    lexer.run(content, proto_lexer.proto_lexer())
    |> result.map_error(LexError),
  )

  // Step 2: Parse
  use parsed <- result.try(
    nibble.run(tokens, proto_file_parser())
    |> result.map_error(ParseError),
  )

  // Step 3: Validate
  use validated <- result.try(validate_proto_file(parsed))

  // Step 4: Fix enum types
  Ok(fix_enum_types(validated))
}

fn proto_file_parser() {
  use syntax <- nibble.do(proto.syntax())
  // Parse all top-level items (messages, enums, services) in ANY order
  use items <- nibble.do(c.many(top_level_item()))
  // Reject unsupported trailing syntax instead of silently dropping declarations.
  use _ <- nibble.do(nibble.eof())
  let packages =
    list.filter_map(items, fn(item) {
      case item {
        ItemPackage(name) -> Ok(name)
        _ -> Error(Nil)
      }
    })
  use _ <- nibble.do(nibble.guard(
    list.length(packages) <= 1,
    "only one package declaration is allowed",
  ))
  let package = case list.first(packages) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
  let imports =
    list.filter_map(items, fn(item) {
      case item {
        ItemImport(value) -> Ok(value)
        _ -> Error(Nil)
      }
    })

  // Separate messages, enums, and services from items
  let #(messages, enums, services) = partition_items(items)

  nibble.return(ProtoFile(
    syntax: syntax,
    package: package,
    imports: imports,
    messages: messages,
    enums: enums,
    services: services,
  ))
}

fn top_level_item() {
  nibble.one_of([
    proto.package_declaration() |> nibble.map(ItemPackage),
    proto.import_statement() |> nibble.map(ItemImport),
    proto.file_option() |> nibble.replace(ItemOption),
    proto.message() |> nibble.map(ItemMessage),
    proto.enum_def() |> nibble.map(ItemEnum),
    proto.service() |> nibble.map(ItemService),
  ])
}

fn partition_items(
  items: List(TopLevelItem),
) -> #(List(proto.Message), List(proto.Enum), List(proto.Service)) {
  partition_items_helper(items, [], [], [])
}

fn partition_items_helper(
  items: List(TopLevelItem),
  messages: List(proto.Message),
  enums: List(proto.Enum),
  services: List(proto.Service),
) -> #(List(proto.Message), List(proto.Enum), List(proto.Service)) {
  case items {
    [] -> #(list.reverse(messages), list.reverse(enums), list.reverse(services))
    [ItemMessage(msg), ..rest] ->
      partition_items_helper(rest, [msg, ..messages], enums, services)
    [ItemEnum(enum), ..rest] ->
      partition_items_helper(rest, messages, [enum, ..enums], services)
    [ItemService(service), ..rest] ->
      partition_items_helper(rest, messages, enums, [service, ..services])
    [ItemPackage(_), ..rest] | [ItemImport(_), ..rest] | [ItemOption, ..rest] ->
      partition_items_helper(rest, messages, enums, services)
  }
}

// ---- VALIDATION ----

fn validate_proto_file(proto: ProtoFile) -> Result(ProtoFile, ParseError) {
  use validated_messages <- result.try(validate_messages(proto.messages))

  Ok(ProtoFile(..proto, messages: validated_messages))
}

fn validate_messages(
  messages: List(proto.Message),
) -> Result(List(proto.Message), ParseError) {
  list.try_map(messages, validate_message)
}

fn validate_message(msg: proto.Message) -> Result(proto.Message, ParseError) {
  // 1. Validate field numbers > 0
  use _ <- result.try(validate_field_numbers(msg.name, msg.fields))

  // 2. Check for duplicate field numbers
  use _ <- result.try(check_duplicate_field_numbers(msg.name, msg.fields))

  // 3. Validate oneof fields
  use _ <- result.try(validate_oneofs(msg.name, msg.oneofs))

  // 4. Recursively validate nested messages
  use validated_nested <- result.try(validate_messages(msg.nested_messages))

  Ok(proto.Message(..msg, nested_messages: validated_nested))
}

fn validate_field_numbers(
  message_name: String,
  fields: List(proto.Field),
) -> Result(Nil, ParseError) {
  case list.find(fields, fn(field) { field.number <= 0 }) {
    Ok(invalid_field) ->
      Error(InvalidFieldNumber(
        message_name,
        invalid_field.name,
        invalid_field.number,
      ))
    Error(_) -> Ok(Nil)
  }
}

fn check_duplicate_field_numbers(
  message_name: String,
  fields: List(proto.Field),
) -> Result(Nil, ParseError) {
  let field_numbers = list.map(fields, fn(field) { field.number })

  case has_duplicates(field_numbers) {
    Some(dup_num) -> Error(DuplicateFieldNumber(message_name, dup_num))
    None -> Ok(Nil)
  }
}

fn has_duplicates(numbers: List(Int)) -> Option(Int) {
  has_duplicates_helper(numbers, set.new())
}

fn has_duplicates_helper(
  numbers: List(Int),
  seen: set.Set(Int),
) -> Option(Int) {
  case numbers {
    [] -> None
    [num, ..rest] ->
      case set.contains(seen, num) {
        True -> Some(num)
        False -> has_duplicates_helper(rest, set.insert(seen, num))
      }
  }
}

fn validate_oneofs(
  message_name: String,
  oneofs: List(proto.Oneof),
) -> Result(Nil, ParseError) {
  list.try_each(oneofs, fn(oneof) {
    use _ <- result.try(validate_field_numbers(message_name, oneof.fields))
    check_duplicate_field_numbers(message_name, oneof.fields)
  })
}

// ---- ENUM TYPE FIXING ----

fn fix_enum_types(proto: ProtoFile) -> ProtoFile {
  // Collect all enum names (including nested)
  let enum_names = collect_all_enum_names(proto.messages, proto.enums)

  // Fix all message field types
  let fixed_messages =
    list.map(proto.messages, fn(msg) { fix_message_types(msg, enum_names) })

  ProtoFile(..proto, messages: fixed_messages)
}

fn collect_all_enum_names(
  messages: List(proto.Message),
  enums: List(proto.Enum),
) -> List(String) {
  let top_level = list.map(enums, fn(e) { e.name })
  let nested =
    list.flat_map(messages, fn(msg) {
      list.append(
        list.map(msg.nested_enums, fn(e) { e.name }),
        collect_all_enum_names(msg.nested_messages, []),
      )
    })
  list.append(top_level, nested)
}

fn fix_message_types(
  msg: proto.Message,
  enum_names: List(String),
) -> proto.Message {
  let fixed_fields = fix_field_types(msg.fields, enum_names)
  let fixed_oneofs =
    list.map(msg.oneofs, fn(oneof) {
      proto.Oneof(..oneof, fields: fix_field_types(oneof.fields, enum_names))
    })
  let fixed_nested =
    list.map(msg.nested_messages, fn(nested) {
      fix_message_types(nested, enum_names)
    })

  proto.Message(
    ..msg,
    fields: fixed_fields,
    oneofs: fixed_oneofs,
    nested_messages: fixed_nested,
  )
}

fn fix_field_types(
  fields: List(proto.Field),
  enum_names: List(String),
) -> List(proto.Field) {
  list.map(fields, fn(field) {
    proto.Field(
      ..field,
      field_type: fix_proto_type(field.field_type, enum_names),
    )
  })
}

fn fix_proto_type(
  proto_type: proto.Type,
  enum_names: List(String),
) -> proto.Type {
  case proto_type {
    proto.MessageType(name) ->
      case list.contains(enum_names, name) {
        True -> proto.EnumType(name)
        False -> proto.MessageType(name)
      }
    proto.Repeated(inner) -> proto.Repeated(fix_proto_type(inner, enum_names))
    proto.Optional(inner) -> proto.Optional(fix_proto_type(inner, enum_names))
    proto.Map(key, value) ->
      proto.Map(
        fix_proto_type(key, enum_names),
        fix_proto_type(value, enum_names),
      )
    other -> other
  }
}
