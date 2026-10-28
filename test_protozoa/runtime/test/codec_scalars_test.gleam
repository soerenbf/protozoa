//// Generated scalar codecs preserve presence, defaults and signed enum mapping.
//// Canonical literal bytes are independent of the generated encoder.

import generated/combined/scalars as s
import generated/combined/sign
import gleam/list
import gleam/option.{None, Some}

/// Optional and oneof zero retain presence; map entries receive generated defaults.
pub fn presence_and_defaults_test() {
  // Missing field 1 differs from explicitly selected zero.
  let assert Ok(s.OptionalInt32(None)) = s.decode_optional_int32(<<>>)
  let assert Ok(s.OptionalInt32(Some(0))) = s.decode_optional_int32(<<8, 0>>)
  let assert <<8, 0>> = s.encode_optional_int32(s.OptionalInt32(Some(0)))
  let assert Ok(s.ScalarSint64(0)) = s.decode_scalar_sint64(<<>>)
  let assert <<8, 0>> = s.encode_scalar_sint64(s.ScalarSint64(0))
  let assert Ok(s.ChoiceSint64(None)) = s.decode_choice_sint64(<<>>)
  let value = s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(0)))
  let assert Ok(decoded) = s.decode_choice_sint64(<<8, 0>>)
  let assert True = decoded == value
  let assert <<8, 0>> = s.encode_choice_sint64(value)
  // Map field 1 defaults omitted keys and values.
  let assert Ok(s.MapInt32([#(0, 0)])) = s.decode_map_int32(<<10, 0>>)
  let assert Ok(s.MapInt32([#(1, 0)])) = s.decode_map_int32(<<10, 2, 8, 1>>)
  let assert Ok(s.MapInt32([#(0, 1)])) = s.decode_map_int32(<<10, 2, 16, 1>>)
}

/// Packed doubles dispatch to the generated fixed64 reader.
pub fn packed_double_test() {
  // Packed field 1 contains IEEE754 doubles [-1.0, 1.0] without scalar tags.
  let assert Ok(s.RepeatedDouble([-1.0, 1.0])) =
    s.decode_repeated_double(<<
      10,
      16,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      191,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
    >>)
}

/// Negative enum numbers select declared constructors in singular and packed fields.
pub fn negative_enum_test() {
  // Signed enum field 1 selects -1 or -2^31 using ten-byte sign extension.
  list.each(
    [
      #(sign.SignNegative, <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>),
      #(sign.SignMinimum, <<8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1>>),
    ],
    fn(row) {
      let assert Ok(value) = sign.decode_enumeration(row.1)
      let assert True = value == sign.Enumeration(row.0, [])
      let assert True = sign.encode_enumeration(value) == row.1
    },
  )
  // Field 2 packs [-1, -2^31]; absent field 1 defaults to ZERO.
  let assert Ok(sign.Enumeration(
    sign.SignZero,
    [sign.SignNegative, sign.SignMinimum],
  )) =
    sign.decode_enumeration(<<
      18,
      20,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      1,
      128,
      128,
      128,
      128,
      248,
      255,
      255,
      255,
      255,
      1,
    >>)
}
