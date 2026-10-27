//// Oneof generation preserves alternatives, scoped types and decoder composition.

import gleam/int
import gleam/list
import gleam/string
import protozoa/internal/codegen
import protozoa/internal/type_registry
import protozoa/parser/file

/// Complete generated modules must have bounded, approximately constant growth
/// per alternative, not just a small decoder substring or a memoized generator.
pub fn linear_growth_test() {
  let small = generated_size(12)
  let assert True = small < 10_000
  let medium = generated_size(20)
  let assert True = medium < 20_000
  let large = generated_size(56)
  let assert True = small < medium && medium < large
  let assert True = large < 100_000
  // Compare slopes over 8 and 36 new alternatives (allow 20% name/number noise).
  let first = { medium - small } * 36
  let second = { large - medium } * 8
  let assert True = second * 100 >= first * 80
  let assert True = second * 100 <= first * 120
}

fn generated_size(count) {
  let fields =
    list.range(1, count)
    |> list.map(fn(number) {
      let n = int.to_string(number)
      "int32 pick" <> n <> " = " <> n <> ";"
    })
    |> string.join("\n")
  let source =
    "syntax = 'proto3'; message Choice { oneof choice {" <> fields <> "} }"
  let path = "choice.proto"
  let assert Ok(parsed) = file.parse(source)
  let assert Ok(registry) =
    type_registry.add_file(type_registry.new(), path, parsed)
  let assert Ok(generated) =
    codegen.generate(files: [file.Path(path, parsed)], registry: registry)
  string.byte_size(generated)
}
