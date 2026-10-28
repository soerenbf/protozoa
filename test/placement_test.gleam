//// Placement tests assert dependency ownership and deterministic emitted module paths.

import gleam/list
import gleam/string
import protozoa/internal/codegen/placement
import protozoa/internal/codegen/types
import protozoa/internal/type_registry
import protozoa/parser/file

fn add(registry, path, source) {
  let assert Ok(parsed) = file.parse("syntax = \"proto3\"; " <> source)
  let assert Ok(registry) = type_registry.add_file(registry, path, parsed)
  registry
}

/// Assigns stable module owners and nested names independently of input order.
pub fn ownership_and_order_test() {
  let registry =
    type_registry.new()
    |> add(
      "v2/first.proto",
      "package same; message Envelope { message Item {} Address address = 1; }",
    )
    |> add("v2/protocol-level-tokens.proto", "package same; message Address {}")
    |> add("other.proto", "package other; message Address {}")
  let paths = [
    "v2/first.proto",
    "v2/protocol-level-tokens.proto",
    "other.proto",
    "google/protobuf/timestamp.proto",
  ]
  let assert Ok(a) = placement.plan(registry, paths, "gen/proto")
  let assert Ok(b) = placement.plan(registry, list.reverse(paths), "gen/proto")
  let assert True = a == b
  let assert Ok(nested) =
    list.find(a, fn(d) { d.identity == "same.Envelope.Item" })
  let assert "EnvelopeItem" = nested.local_type
  let assert Ok("same.Address") =
    type_registry.resolve_type_reference(registry, "Address", "same.Envelope")
  let assert Ok(address) = list.find(a, fn(d) { d.identity == "same.Address" })
  let assert "gen/proto/v2/protocol_level_tokens" = address.module
  let assert Ok(timestamp) =
    list.find(a, fn(d) { d.identity == "google.protobuf.Timestamp" })
  let assert "Timestamp" = timestamp.local_type
}

/// Rejects local symbol collisions while allowing equal names in separate modules.
pub fn local_collisions_test() {
  reject(
    "message Envelope { message Item {} } message EnvelopeItem {}",
    "Envelope.Item",
  )
  reject("enum A { ZERO = 0; } message Zero {} message AZero {}", "A.ZERO")
  reject("message HTTP {} message Http {}", "HTTP")
  reject(
    "message Envelope { oneof item { string text = 1; } } message EnvelopeItem {}",
    "Envelope.item",
  )
  let local =
    add(
      type_registry.new(),
      "local.proto",
      "package pkg; enum A { ZERO = 0; } enum B { ZERO = 0; }",
    )
  let assert Ok(_) = placement.plan(local, ["local.proto"], "gen")
  let local_ctx = types.new_local_ctx(local, "local.proto")
  let assert "AZero" = types.enum_constructor("A", "ZERO", local_ctx)
  let assert "BZero" = types.enum_constructor("B", "ZERO", local_ctx)
  let registry =
    type_registry.new()
    |> add("a.proto", "package a; enum State { ZERO = 0; }")
    |> add("b.proto", "package b; enum State { ZERO = 0; }")
  let assert Ok(_) = placement.plan(registry, ["a.proto", "b.proto"], "gen")
  let ctx = types.new_local_ctx(registry, "a.proto")
  let assert "StateZero" = types.enum_constructor("State", "ZERO", ctx)
  let assert "State" = types.qualified_type("State", ctx)
  let assert "state" = types.qualified_fn("State", ctx)
}

fn reject(source, expected) {
  let registry = add(type_registry.new(), "a.proto", source)
  let assert Error(error) = placement.plan(registry, ["a.proto"], "gen")
  let assert True = string.contains(error, expected)
}

/// Rejects unsafe schema paths, invalid prefixes and colliding normalized module paths.
pub fn unsafe_paths_test() {
  list.each(
    [
      "/a.proto",
      "../a.proto",
      "a/../b.proto",
      "C:/a.proto",
      "a\\b.proto",
      "a//b.proto",
      "./a.proto",
      "a/./b.proto",
      "a\u{0}.proto",
    ],
    fn(path) {
      let assert Error(error) = placement.safe_source(path)
      let assert True = string.contains(error, path)
    },
  )
  list.each(["", "../gen", "Gen", "gen/type", "gen//proto"], fn(prefix) {
    let assert Error(_) = placement.valid_prefix(prefix)
  })
  let assert Error(error) =
    placement.plan(type_registry.new(), ["a-b.proto", "a_b.proto"], "gen")
  let assert True =
    string.contains(error, "a-b.proto") && string.contains(error, "a_b.proto")
  let assert Error(_) =
    placement.plan(type_registry.new(), ["123.proto"], "gen")
  let assert Error(error) =
    placement.plan(type_registry.new(), ["---.proto"], "gen")
  let assert True = string.contains(error, "---.proto")
}

/// Function collisions include private oneof and map decoders, and enum helpers.
pub fn actual_function_collisions_test() {
  reject(
    "package p; message Foo { oneof bar { string text = 1; } } message OneofFooBar {}",
    "oneof_foo_bar_decoder",
  )
  reject(
    "package p; enum Foo { ZERO = 0; } message FooValue {}",
    "encode_foo_value",
  )
  reject(
    "message Foo { oneof map_entry_1 { string text = 1; } } message OneofFoo { map<string, string> values = 1; }",
    "oneof_foo_map_entry_1_decoder",
  )
}

/// Reject only the flattened local prelude name, not nested source names.
pub fn prelude_names_test() {
  list.each(
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
    fn(name) { reject("package p; message " <> name <> " {}", "p." <> name) },
  )
  let registry =
    add(
      type_registry.new(),
      "a.proto",
      "package p; message Outer { message Result {} message Int { int32 number = 1; } }",
    )
  let assert Ok(_) = placement.plan(registry, ["a.proto"], "gen")
}

/// Schema constructors cannot shadow runtime/prelude constructors.
pub fn emitted_identifier_rejections_test() {
  list.each(["False", "True", "Ok", "Error", "_", "_123"], fn(name) {
    let registry =
      add(
        type_registry.new(),
        "a.proto",
        "package p; message "
          <> name
          <> " { bool value = 1; } enum State { ZERO = 0; }",
      )
    let assert Error(error) = placement.plan(registry, ["a.proto"], "gen")
    let assert True = string.contains(error, "p." <> name)
    let assert True = string.contains(error, "a.proto")
  })
  reject("package p; message Outer { message _ {} }", "p.Outer._")
  let enums =
    add(
      type_registry.new(),
      "a.proto",
      "package p; enum State { _ = 0; _123 = 1; }",
    )
  let assert Ok(_) = placement.plan(enums, ["a.proto"], "gen")
  let registry =
    add(
      type_registry.new(),
      "a.proto",
      "package p; message Outer { message False {} message Ok {} message _123 {} }",
    )
  let assert Ok(_) = placement.plan(registry, ["a.proto"], "gen")
}
