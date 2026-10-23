import gleam/list as gleam_list
import gleam/option.{None, Some}
import gleam/string
import protozoa/parser/file
import protozoa/parser/proto

/// Regression: token-based whitespace and inline bodies already work on main.
pub fn whitespace_inline_test() {
  let assert Ok(parsed) =
    file.parse(
      "syntax = 'proto3'; message A { string  x = 1; message B { int32 y = 2; } optional B b = 3; } message C {}",
    )
  let assert [
    proto.Message(
      "A",
      fields,
      [],
      [
        proto.Message(
          "B",
          [proto.Field("y", proto.Int32, 2, None, [])],
          [],
          [],
          [],
        ),
      ],
      [],
    ),
    proto.Message("C", [], [], [], []),
  ] = parsed.messages
  let assert [
    proto.Field("x", proto.String, 1, None, []),
    proto.Field("b", proto.Optional(proto.MessageType("B")), 3, None, []),
  ] = fields
}

/// Options and imports may precede the package without hiding definitions.
pub fn options_ordering_test() {
  let assert Ok(parsed) =
    file.parse(
      "syntax = 'proto3'; import public 'a.proto'; option java_package = 'example'; package example; option java_multiple_files = true; import weak 'b.proto'; message A { string x = 1; } enum E { ZERO = 0; } service S { rpc Call (A) returns (example.A); }",
    )
  let assert Some("example") = parsed.package
  let assert [
    proto.Import("a.proto", True, False),
    proto.Import("b.proto", False, True),
  ] = parsed.imports
  let assert [
    proto.Message(
      "A",
      [proto.Field("x", proto.String, 1, None, [])],
      [],
      [],
      [],
    ),
  ] = parsed.messages
  let assert [proto.Enum("E", [proto.EnumValue("ZERO", 0)])] = parsed.enums
  let assert [
    proto.Service(
      "S",
      [proto.Method("Call", "A", "example.A", False, False, None, None)],
    ),
  ] = parsed.services
}

/// Reservations must not remove surrounding fields, options, oneofs or messages.
pub fn reservations_test() {
  let assert Ok(parsed) =
    file.parse(
      "syntax = 'proto3'; message A { string x = 1 [deprecated = true]; reserved 2, 3 to 5, 8 to max; reserved 'old', 'older'; optional string y = 6; oneof choice { int32 z = 7; } message B {} } message C { map<string, int32> entries = 1; }",
    )
  let assert [
    proto.Message(
      "A",
      [
        proto.Field("x", proto.String, 1, None, [proto.Deprecated(True)]),
        proto.Field("y", proto.Optional(proto.String), 6, None, []),
      ],
      [
        proto.Oneof(
          "choice",
          [proto.Field("z", proto.Int32, 7, Some("choice"), [])],
        ),
      ],
      [proto.Message("B", [], [], [], [])],
      [],
    ),
    proto.Message(
      "C",
      [
        proto.Field(
          "entries",
          proto.Map(proto.String, proto.Int32),
          1,
          None,
          [],
        ),
      ],
      [],
      [],
      [],
    ),
  ] = parsed.messages
}

/// Unsupported, malformed and truncated inputs are errors, not partial success.
pub fn complete_input_test() {
  let inputs = [
    "message A {} extend A {}",
    "message A {",
    "message A { string x = 1;",
    "message A {} message B { string x = ; }",
    "option java_package = 'example' message A {}",
    "option java_package = ; message A {}",
    "option (custom) = { value: 'x' }; message A {}",
    "message A { reserved ; string x = 1; }",
    "message A { reserved 2 to ; string x = 1; }",
    "message A { reserved 'x', 2; string x = 1; }",
    "package a; package b; message A {}",
  ]
  gleam_list.each(inputs, fn(input) {
    let assert Error(error) = file.parse("syntax = 'proto3'; " <> input)
    let assert True =
      string.contains(file.describe_error(error), "Parse error:")
    let assert True = string.contains(file.describe_error(error), "1:")
  })
}

/// Absolute type references retain their root marker, unlike declaration names.
pub fn absolute_type_references_test() {
  let assert Ok(parsed) =
    file.parse(
      "syntax = 'proto3'; message A { .root.Item item = 1; } service S { rpc Call (.root.Item) returns (.root.Item); }",
    )
  let assert [
    proto.Message(
      _,
      [proto.Field(_, proto.MessageType(".root.Item"), _, _, _)],
      _,
      _,
      _,
    ),
  ] = parsed.messages
  gleam_list.each(
    [
      "message A { ..root.Item item = 1; }",
      "message A { .root. item = 1; }",
      "message A { . item = 1; }",
      "service S { rpc Call (..Item) returns (Item); }",
      "service S { rpc Call (Item) returns (.Item.); }",
      "package .root; message A {}",
      "message A { string .item = 1; }",
      "option .custom = true;",
    ],
    fn(source) {
      let assert Error(_) = file.parse("syntax = 'proto3'; " <> source)
    },
  )
}
