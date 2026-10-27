//// Regenerates integration codecs from schema files without compiling their owner.
//// File, resolver and generation failures abort before freshness comparison.

import gleam/dict
import gleam/list
import gleam/string
import protozoa/internal/codegen
import protozoa/internal/import_resolver
import protozoa/internal/type_registry
import protozoa/parser/file
import simplifile

/// Generate staged modules from this package: `gleam run -m integration_codegen`.
/// No arguments; file, parse, resolver and generation errors abort with an assertion.
pub fn main() {
  list.each(
    [
      #("app", ["base", "app"]),
      #("service", ["service"]),
      #("types", ["types"]),
      #("nested", ["nested"]),
      #("mixed", ["mixed"]),
      #("scalars", ["scalars"]),
      #("sign", ["sign"]),
      #("naming", ["naming_base", "naming"]),
    ],
    fn(entry) {
      let sources =
        list.fold(entry.1, dict.new(), fn(sources, name) {
          let assert Ok(source) =
            simplifile.read("../schemas/" <> name <> ".proto")
          let assert Ok(parsed) = file.parse(source)
          dict.insert(sources, name <> ".proto", import_resolver.Parsed(parsed))
        })
      let assert Ok(resolver) =
        import_resolver.resolve(sources, entry.0 <> ".proto")
      let files =
        import_resolver.get_all_loaded_files(resolver)
        |> list.map(fn(pair) { file.Path(pair.0, pair.1) })
      let assert Ok(source) =
        codegen.generate(files, import_resolver.get_type_registry(resolver))
      let assert Ok(Nil) = simplifile.create_directory_all("build/generated")
      let assert Ok(Nil) =
        simplifile.write("build/generated/" <> entry.0 <> ".gleam", source)
    },
  )
  list.each(split_modules(), fn(module) {
    let path = "build/" <> module.module <> ".gleam"
    let directory =
      module.module
      |> string.split("/")
      |> list.reverse
      |> list.drop(1)
      |> list.reverse
      |> string.join("/")
    let assert Ok(Nil) = simplifile.create_directory_all("build/" <> directory)
    let assert Ok(Nil) = simplifile.write(path, module.source)
  })
}

/// Resolve checked-in split schemas and render their per-file modules.
/// No arguments; asserts on file, parse, resolution or generation errors.
/// Example: `split_modules()`.
pub fn split_modules() -> List(codegen.GeneratedModule) {
  let files = split_files()
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

/// Load the actual import closure of split/root.proto from the integration owner.
/// No arguments; asserts on missing, malformed or unresolved schemas.
/// Example: `split_files()`.
pub fn split_files() -> List(file.Path) {
  let sources =
    list.fold(
      [
        "a/common", "b/common", "decode", "root", "shadow", "repeated", "map",
        "service",
      ],
      dict.new(),
      fn(sources, name) {
        let assert Ok(source) =
          simplifile.read("../schemas/split/" <> name <> ".proto")
        dict.insert(sources, name <> ".proto", import_resolver.Raw(source))
      },
    )
  let assert Ok(resolver) = import_resolver.resolve(sources, "root.proto")
  import_resolver.get_all_loaded_files(resolver)
  |> list.map(fn(pair) { file.Path(pair.0, pair.1) })
}
