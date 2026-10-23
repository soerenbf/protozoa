//// Export the focused repeated-enum probe for independent protoc verification.

import gleam/bit_array
import gleam/io
import gleam/list
import naming

/// Print re-encoded packed/unpacked/mixed enum fixtures; no arguments.
/// Asserts on decode errors. Example: `gleam run -m wire_export`.
pub fn main() -> Nil {
  list.each(
    [
      #("packed", <<34, 2, 0, 1>>),
      #("unpacked", <<32, 0, 32, 1>>),
      #("mixed", <<32, 1, 34, 2, 0, 1, 32, 0, 34, 0>>),
    ],
    fn(fixture) {
      let assert Ok(value) = naming.decode_sample_base_child_first(fixture.1)
      io.println(
        "WIRE "
        <> fixture.0
        <> " "
        <> bit_array.base16_encode(naming.encode_sample_base_child_first(value)),
      )
    },
  )
}
