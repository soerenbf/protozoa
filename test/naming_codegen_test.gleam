import gleam/string
import protozoa/internal/codegen
import protozoa/internal/type_registry
import protozoa/parser/file

pub fn unresolved_types_return_diagnostics_test() {
  rejects("message A { Missing value = 1; }", "Unknown type: Missing")
  rejects("message A { optional Missing value = 1; }", "Unknown type: Missing")
  rejects("message A { repeated Missing value = 1; }", "Unknown type: Missing")
  rejects(
    "message A { map<string, Missing> value = 1; }",
    "Unknown type: Missing",
  )
  rejects(
    "message A { oneof choice { Missing value = 1; } }",
    "Unknown type: Missing",
  )
  rejects("message A { message B { Missing value = 1; } }", "scope: A.B")
}

pub fn normalized_collisions_return_diagnostics_test() {
  rejects(
    "message FooBar {} message Foo { message Bar {} }",
    "Generated name collision",
  )
  rejects(
    "message A { int32 fooBar = 1; int32 foo_bar = 2; }",
    "Generated name collision",
  )
  rejects(
    "message A { oneof response { int32 v0 = 1; int32 V0 = 2; } }",
    "Generated name collision",
  )
  rejects(
    "enum A { ZERO = 0; } message ZERO {} message AZERO {}",
    "Generated name collision",
  )
  rejects("enum A { foo_bar = 0; FooBar = 1; }", "Generated name collision")
}

pub fn unrelated_suffix_does_not_resolve_test() {
  rejects(
    "message Other { message Inner {} } message A { Inner value = 1; }",
    "Unknown type: Inner",
  )
  rejects(
    "message Other {} message A { .Missing value = 1; }",
    "Unknown type: .Missing",
  )
}

/// Bare unique names and qualified duplicates agree in types and codecs.
pub fn enum_constructor_collision_policy_test() {
  let output =
    generates(
      "enum Unique { ONLY = 0; } enum A { ZERO = 0; } enum B { ZERO = 0; }",
    )
  let assert True = string.contains(output, "pub type Unique {\n  ONLY\n}")
  let assert True = string.contains(output, "  ONLY -> 0")
  let assert True = string.contains(output, "0 -> Ok(ONLY)")
  let assert True = string.contains(output, "}, ONLY)")
  let assert True = string.contains(output, "pub type A {\n  AZERO\n}")
  let assert True = string.contains(output, "pub type B {\n  BZERO\n}")
  let assert True = string.contains(output, "  AZERO -> 0")
  let assert True = string.contains(output, "0 -> Ok(BZERO)")
}

/// Distinct proto spellings that normalize identically qualify both owners.
pub fn normalized_enum_variants_are_qualified_test() {
  let output = generates("enum A { foo_bar = 0; } enum B { FooBar = 0; }")
  let assert True = string.contains(output, "pub type A {\n  AFooBar\n}")
  let assert True = string.contains(output, "pub type B {\n  BFooBar\n}")
  let assert True = string.contains(output, "  AFooBar -> 0")
  let assert True = string.contains(output, "0 -> Ok(BFooBar)")
}

/// Qualification handles message/oneof constructors and secondary collisions.
pub fn enum_constructor_message_oneof_and_cascade_collisions_test() {
  let output =
    generates(
      "message Clash {} message M { oneof choice { int32 item = 1; } }
     enum A { Clash = 0; MChoiceItem = 1; } enum B { AClash = 0; }",
    )
  let assert True = string.contains(output, "  AClash\n  AMChoiceItem")
  let assert True = string.contains(output, "pub type B {\n  BAClash\n}")
  let assert True = string.contains(output, "  AMChoiceItem -> 1")
  let assert True = string.contains(output, "0 -> Ok(BAClash)")
}

fn generates(source: String) -> String {
  let assert Ok(parsed) = file.parse("syntax = \"proto3\"; " <> source)
  let assert Ok(registry) =
    type_registry.add_file(type_registry.new(), "test.proto", parsed)
  let assert Ok(output) =
    codegen.generate(
      files: [file.Path("test.proto", parsed)],
      registry: registry,
    )
  output
}

fn rejects(source: String, diagnostic: String) {
  let assert Ok(parsed) = file.parse("syntax = \"proto3\"; " <> source)
  let assert Ok(registry) =
    type_registry.add_file(type_registry.new(), "test.proto", parsed)
  let assert Error(error) =
    codegen.generate(
      files: [file.Path("test.proto", parsed)],
      registry: registry,
    )
  let assert True = string.contains(error, diagnostic)
}
