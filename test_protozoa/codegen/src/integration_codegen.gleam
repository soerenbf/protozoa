//// Generate both integration modes from the same resolved schema closures.
//// This package never compiles the runtime output it replaces.

import gleam/dict
import gleam/list
import gleam/string
import protozoa/internal/codegen
import protozoa/internal/import_resolver
import protozoa/parser/file
import simplifile

/// Regenerate staged codecs with `gleam run -m integration_codegen`.
/// No arguments; file, resolution and generation failures abort with an assertion.
pub fn main() {
  let sources =
    list.fold(
      [
        "base",
        "app",
        "service",
        "types",
        "nested",
        "a/common",
        "b/common",
        "decode",
      ],
      dict.new(),
      fn(sources, name) {
        let assert Ok(source) =
          simplifile.read("../schemas/" <> name <> ".proto")
        dict.insert(sources, name <> ".proto", import_resolver.Raw(source))
      },
    )
  list.each(["app", "types", "service", "nested"], fn(entry) {
    let assert Ok(resolver) =
      import_resolver.resolve(sources, entry <> ".proto")
    let files =
      import_resolver.get_all_loaded_files(resolver)
      |> list.map(fn(pair) { file.Path(pair.0, pair.1) })
    let registry = import_resolver.get_type_registry(resolver)
    let assert Ok(combined) = codegen.generate(files, registry)
    let assert Ok(Nil) = write_module("generated/combined/" <> entry, combined)
    let assert Ok(modules) =
      codegen.generate_modules(files, registry, "generated/per_file")
    list.each(modules, fn(module) { write_module(module.module, module.source) })
  })
}

fn write_module(module: String, source: String) {
  let directory =
    module
    |> string.split("/")
    |> list.reverse
    |> list.drop(1)
    |> list.reverse
    |> string.join("/")
  let assert Ok(Nil) = simplifile.create_directory_all("build/" <> directory)
  let assert Ok(Nil) = simplifile.write("build/" <> module <> ".gleam", source)
}
