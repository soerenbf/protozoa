//// Independent canonical wire verifies all fifteen baseline singular scalars.

import generated/combined/types as t

/// Every baseline scalar selects its reader, writer and absent default.
pub fn singular_scalars_test() {
  // Fields 1..15 carry IEEE -1, signed -1, unsigned 2^32-1, zigzag -1,
  // unsigned fixed 2^32-1, signed fixed -1, true, "x", and binary 255.
  let bytes = <<
    9, 0, 0, 0, 0, 0, 0, 240, 191, 21, 0, 0, 128, 191, 24, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 1, 32, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    1, 40, 255, 255, 255, 255, 15, 48, 255, 255, 255, 255, 15, 56, 1, 64, 1, 77,
    255, 255, 255, 255, 81, 255, 255, 255, 255, 0, 0, 0, 0, 93, 255, 255, 255,
    255, 97, 255, 255, 255, 255, 255, 255, 255, 255, 104, 1, 114, 1, 120, 122, 1,
    255,
  >>
  let expected =
    t.TypesAllTypes(
      -1.0,
      -1.0,
      -1,
      -1,
      4_294_967_295,
      4_294_967_295,
      -1,
      -1,
      4_294_967_295,
      4_294_967_295,
      -1,
      -1,
      True,
      "x",
      <<255>>,
    )
  let assert Ok(value) = t.decode_types_all_types(bytes)
  let assert True = value == expected
  let assert True = t.encode_types_all_types(value) == bytes
  let assert Ok(defaults) = t.decode_types_all_types(<<>>)
  let assert t.TypesAllTypes(
    0.0,
    0.0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    False,
    "",
    <<>>,
  ) = defaults
}
