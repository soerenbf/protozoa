import gleam/list
import protozoa/internal/codegen
import protozoa/internal/type_registry
import protozoa/parser/file
import simplifile

/// Generates the six schema fixtures into `src`, relative to this package.
/// Run `gleam run -m generate` on Erlang; asserts on read/parse/generation/write
/// errors so validation cannot accidentally continue with stale output.
pub fn main() {
  list.each(["dozen", "score", "many", "mixed"], fn(name) {
    let path = "schemas/" <> name <> ".proto"
    let assert Ok(source) = simplifile.read(path)
    let assert Ok(parsed) = file.parse(source)
    let assert Ok(registry) =
      type_registry.add_file(type_registry.new(), path, parsed)
    let assert Ok(generated) =
      codegen.generate(files: [file.Path(path, parsed)], registry: registry)
    let assert Ok(Nil) = simplifile.write("src/" <> name <> ".gleam", generated)
  })
  let assert Ok(base) = simplifile.read("schemas/base.proto")
  let assert Ok(base) = file.parse(base)
  let assert Ok(naming) = simplifile.read("schemas/naming.proto")
  let assert Ok(naming) = file.parse(naming)
  let assert Ok(registry) =
    type_registry.add_file(type_registry.new(), "schemas/base.proto", base)
  let assert Ok(registry) =
    type_registry.add_file(registry, "schemas/naming.proto", naming)
  let assert Ok(generated) =
    codegen.generate(
      files: [
        file.Path("schemas/base.proto", base),
        file.Path("schemas/naming.proto", naming),
      ],
      registry: registry,
    )
  let assert Ok(Nil) = simplifile.write("src/naming.gleam", generated)
}
