import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import protozoa/internal/codegen
import protozoa/internal/type_registry
import protozoa/internal/well_known_type
import protozoa/parser/file

/// Parsed multi-file closure, including same-package and runtime-name owners.
/// No arguments or failures. Example: `files()`.
pub fn files() -> List(file.Path) {
  let assert Ok(struct) =
    dict.get(
      well_known_type.get_well_known_proto_files(),
      "google/protobuf/struct.proto",
    )
  [
    file.Path("google/protobuf/struct.proto", struct),
    parsed(
      "a/common.proto",
      "package same; message Value { string text = 1; } message Envelope { message Item { string text = 1; } enum State { ZERO = 0; READY = 1; } }",
    ),
    parsed(
      "b/common.proto",
      "package other; message Item { int32 number = 1; }",
    ),
    parsed(
      "decode.proto",
      "package runtime; message Token { string text = 1; }",
    ),
    parsed(
      "root.proto",
      "package same; import 'a/common.proto'; import 'b/common.proto'; import 'decode.proto'; message Root { Envelope.Item item = 1; other.Item other = 2; runtime.Token token = 3; Envelope.State state = 4; optional Envelope.State optional_state = 5; repeated Envelope.State states = 6; repeated Envelope.Item items = 7; map<string, Envelope.Item> items_by_name = 8; map<string, Envelope.State> states_by_name = 9; map<string, Value> values = 13; Root next = 10; oneof pick { Envelope.Item chosen = 11; Envelope.State status = 12; } }",
    ),
    parsed(
      "shadow.proto",
      "package p; message X { string text = 1; } message p { message X { int32 number = 1; } } message Root { .p.X x = 1; }",
    ),
    parsed(
      "repeated.proto",
      "package p.repeated; message ValuesFields { repeated string values = 1; string label = 2; }",
    ),
    parsed(
      "map.proto",
      "package p.maps; message ValuesFields { map<string, string> values = 1; string label = 2; }",
    ),
    parsed("service.proto", "package same; service OnlyService {}"),
  ]
}

fn parsed(path, source) {
  let assert Ok(content) = file.parse("syntax = 'proto3'; " <> source)
  file.Path(path, content)
}

/// Render the fixture without I/O. No arguments; asserts fixture validity.
/// Example: `modules()` returns eight codec sources.
pub fn modules() -> List(codegen.GeneratedModule) {
  render(files())
}

fn render(files: List(file.Path)) -> List(codegen.GeneratedModule) {
  let registry =
    list.fold(files, type_registry.new(), fn(registry, f) {
      let assert Ok(registry) =
        type_registry.add_file(registry, f.path, f.content)
      registry
    })
  let assert Ok(modules) =
    codegen.generate_modules(files, registry, "split_fixture")
  modules
}

pub fn deterministic_owners_test() {
  let modules = modules()
  let assert True = modules == render(list.reverse(files()))
  let assert 8 = list.length(modules)
  let assert Ok(root) =
    list.find(modules, fn(m) { m.module == "split_fixture/root" })
  let assert True =
    string.contains(root.source, "import split_fixture/a/common as pb_module_0")
  let assert True =
    string.contains(root.source, "import split_fixture/b/common as pb_module_1")
  let assert True =
    string.contains(root.source, "import split_fixture/decode as pb_module_2")
  let assert False = string.contains(root.source, "import split_fixture/root")
  let assert True = string.contains(root.source, "pb_module_0.EnvelopeItem")
  let assert True =
    string.contains(root.source, "pb_module_0.encode_envelope_item")
  let assert True =
    string.contains(root.source, "pb_module_0.decode_envelope_state_from_field")
}

/// Print delimited fixture sources for regeneration; no arguments or I/O errors.
/// Example: `gleam run -m module_set_fixture`.
pub fn main() {
  list.each(modules(), fn(m) {
    io.println("===MODULE " <> m.module)
    io.println(m.source)
  })
}
