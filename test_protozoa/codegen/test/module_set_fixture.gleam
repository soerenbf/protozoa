//// Asserts deterministic module ownership using the integration owner's schemas.

import gleam/list
import gleam/string
import integration_codegen
import protozoa/internal/codegen
import protozoa/internal/type_registry
import protozoa/parser/file

fn render(files: List(file.Path)) -> List(codegen.GeneratedModule) {
  let registry =
    list.fold(files, type_registry.new(), fn(registry, f) {
      let assert Ok(registry) =
        type_registry.add_file(registry, f.path, f.content)
      registry
    })
  let assert Ok(modules) =
    codegen.generate_modules(files, registry, "generated/split")
  modules
}

/// No arguments; asserts stable owners and aliases regardless of file order.
/// Example: `deterministic_owners_test()`.
pub fn deterministic_owners_test() {
  let files = integration_codegen.split_files()
  let modules = render(files)
  let assert True = modules == render(list.reverse(files))
  let assert 8 = list.length(modules)
  let assert Ok(root) =
    list.find(modules, fn(m) { m.module == "generated/split/root" })
  let assert True =
    string.contains(
      root.source,
      "import generated/split/a/common as pb_module_0",
    )
  let assert True =
    string.contains(
      root.source,
      "import generated/split/b/common as pb_module_1",
    )
  let assert True =
    string.contains(root.source, "import generated/split/decode as pb_module_2")
  let assert False = string.contains(root.source, "import generated/split/root")
  let assert True = string.contains(root.source, "pb_module_0.EnvelopeItem")
  let assert True =
    string.contains(root.source, "pb_module_0.encode_envelope_item")
  let assert True =
    string.contains(root.source, "pb_module_0.decode_envelope_state_from_field")
}
