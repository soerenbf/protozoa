import codec_fixture/packed_only as p
import codec_fixture/scalars as s
import gleam/option.{None, Some}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_defaults_test() {
  let assert Ok(s.ScalarInt32(0)) = s.decode_scalar_int32(<<>>)
  let assert Ok(s.OptionalInt32(None)) = s.decode_optional_int32(<<>>)
  let assert Ok(s.OptionalInt32(Some(0))) = s.decode_optional_int32(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_oneof_test() {
  let assert Ok(s.ChoiceInt32(None)) = s.decode_choice_int32(<<>>)
  let assert Ok(s.ChoiceInt32(Some(s.ChoiceInt32SelectionValue(0)))) =
    s.decode_choice_int32(<<8, 0>>)
  let assert Ok(s.ChoiceInt32(Some(s.ChoiceInt32SelectionValue(1)))) =
    s.decode_choice_int32(<<8, 1>>)
  let assert <<8, 0>> =
    s.encode_choice_int32(s.ChoiceInt32(Some(s.ChoiceInt32SelectionValue(0))))
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_repeated_test() {
  let assert Ok(s.RepeatedInt32([1, 2])) =
    s.decode_repeated_int32(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedInt32([1, 2])) =
    s.decode_repeated_int32(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedInt32([1, 1, 2, 2])) =
    s.decode_repeated_int32(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  let assert Ok(s.RepeatedInt32([1, 2])) =
    s.decode_repeated_int32(<<10, 0, 10, 2, 1, 2, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_defaults_test() {
  let assert Ok(s.ScalarInt64(0)) = s.decode_scalar_int64(<<>>)
  let assert Ok(s.OptionalInt64(None)) = s.decode_optional_int64(<<>>)
  let assert Ok(s.OptionalInt64(Some(0))) = s.decode_optional_int64(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_oneof_test() {
  let assert Ok(s.ChoiceInt64(None)) = s.decode_choice_int64(<<>>)
  let assert Ok(s.ChoiceInt64(Some(s.ChoiceInt64SelectionValue(0)))) =
    s.decode_choice_int64(<<8, 0>>)
  let assert Ok(s.ChoiceInt64(Some(s.ChoiceInt64SelectionValue(1)))) =
    s.decode_choice_int64(<<8, 1>>)
  let assert <<8, 0>> =
    s.encode_choice_int64(s.ChoiceInt64(Some(s.ChoiceInt64SelectionValue(0))))
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_repeated_test() {
  let assert Ok(s.RepeatedInt64([1, 2])) =
    s.decode_repeated_int64(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedInt64([1, 2])) =
    s.decode_repeated_int64(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedInt64([1, 1, 2, 2])) =
    s.decode_repeated_int64(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  let assert Ok(s.RepeatedInt64([1, 2])) =
    s.decode_repeated_int64(<<10, 0, 10, 2, 1, 2, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint32_defaults_test() {
  let assert Ok(s.ScalarUint32(0)) = s.decode_scalar_uint32(<<>>)
  let assert Ok(s.OptionalUint32(None)) = s.decode_optional_uint32(<<>>)
  let assert Ok(s.OptionalUint32(Some(0))) = s.decode_optional_uint32(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint32_oneof_test() {
  let assert Ok(s.ChoiceUint32(None)) = s.decode_choice_uint32(<<>>)
  let assert Ok(s.ChoiceUint32(Some(s.ChoiceUint32SelectionValue(0)))) =
    s.decode_choice_uint32(<<8, 0>>)
  let assert Ok(s.ChoiceUint32(Some(s.ChoiceUint32SelectionValue(1)))) =
    s.decode_choice_uint32(<<8, 1>>)
  let assert <<8, 0>> =
    s.encode_choice_uint32(
      s.ChoiceUint32(Some(s.ChoiceUint32SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint32_repeated_test() {
  let assert Ok(s.RepeatedUint32([1, 2])) =
    s.decode_repeated_uint32(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedUint32([1, 2])) =
    s.decode_repeated_uint32(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedUint32([1, 1, 2, 2])) =
    s.decode_repeated_uint32(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  let assert Ok(s.RepeatedUint32([1, 2])) =
    s.decode_repeated_uint32(<<10, 0, 10, 2, 1, 2, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint64_defaults_test() {
  let assert Ok(s.ScalarUint64(0)) = s.decode_scalar_uint64(<<>>)
  let assert Ok(s.OptionalUint64(None)) = s.decode_optional_uint64(<<>>)
  let assert Ok(s.OptionalUint64(Some(0))) = s.decode_optional_uint64(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint64_oneof_test() {
  let assert Ok(s.ChoiceUint64(None)) = s.decode_choice_uint64(<<>>)
  let assert Ok(s.ChoiceUint64(Some(s.ChoiceUint64SelectionValue(0)))) =
    s.decode_choice_uint64(<<8, 0>>)
  let assert Ok(s.ChoiceUint64(Some(s.ChoiceUint64SelectionValue(1)))) =
    s.decode_choice_uint64(<<8, 1>>)
  let assert <<8, 0>> =
    s.encode_choice_uint64(
      s.ChoiceUint64(Some(s.ChoiceUint64SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint64_repeated_test() {
  let assert Ok(s.RepeatedUint64([1, 2])) =
    s.decode_repeated_uint64(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedUint64([1, 2])) =
    s.decode_repeated_uint64(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedUint64([1, 1, 2, 2])) =
    s.decode_repeated_uint64(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  let assert Ok(s.RepeatedUint64([1, 2])) =
    s.decode_repeated_uint64(<<10, 0, 10, 2, 1, 2, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_defaults_test() {
  let assert Ok(s.ScalarSint32(0)) = s.decode_scalar_sint32(<<>>)
  let assert Ok(s.OptionalSint32(None)) = s.decode_optional_sint32(<<>>)
  let assert Ok(s.OptionalSint32(Some(0))) = s.decode_optional_sint32(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_oneof_test() {
  let assert Ok(s.ChoiceSint32(None)) = s.decode_choice_sint32(<<>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(0)))) =
    s.decode_choice_sint32(<<8, 0>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(1)))) =
    s.decode_choice_sint32(<<8, 2>>)
  let assert <<8, 0>> =
    s.encode_choice_sint32(
      s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_repeated_test() {
  let assert Ok(s.RepeatedSint32([1, 2])) =
    s.decode_repeated_sint32(<<10, 2, 2, 4>>)
  let assert Ok(s.RepeatedSint32([1, 2])) =
    s.decode_repeated_sint32(<<8, 2, 8, 4>>)
  let assert Ok(s.RepeatedSint32([1, 1, 2, 2])) =
    s.decode_repeated_sint32(<<8, 2, 10, 2, 2, 4, 8, 4>>)
  let assert Ok(s.RepeatedSint32([1, 2])) =
    s.decode_repeated_sint32(<<10, 0, 10, 2, 2, 4, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_defaults_test() {
  let assert Ok(s.ScalarSint64(0)) = s.decode_scalar_sint64(<<>>)
  let assert Ok(s.OptionalSint64(None)) = s.decode_optional_sint64(<<>>)
  let assert Ok(s.OptionalSint64(Some(0))) = s.decode_optional_sint64(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_oneof_test() {
  let assert Ok(s.ChoiceSint64(None)) = s.decode_choice_sint64(<<>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(0)))) =
    s.decode_choice_sint64(<<8, 0>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(1)))) =
    s.decode_choice_sint64(<<8, 2>>)
  let assert <<8, 0>> =
    s.encode_choice_sint64(
      s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_repeated_test() {
  let assert Ok(s.RepeatedSint64([1, 2])) =
    s.decode_repeated_sint64(<<10, 2, 2, 4>>)
  let assert Ok(s.RepeatedSint64([1, 2])) =
    s.decode_repeated_sint64(<<8, 2, 8, 4>>)
  let assert Ok(s.RepeatedSint64([1, 1, 2, 2])) =
    s.decode_repeated_sint64(<<8, 2, 10, 2, 2, 4, 8, 4>>)
  let assert Ok(s.RepeatedSint64([1, 2])) =
    s.decode_repeated_sint64(<<10, 0, 10, 2, 2, 4, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed32_defaults_test() {
  let assert Ok(s.ScalarFixed32(0)) = s.decode_scalar_fixed32(<<>>)
  let assert Ok(s.OptionalFixed32(None)) = s.decode_optional_fixed32(<<>>)
  let assert Ok(s.OptionalFixed32(Some(0))) =
    s.decode_optional_fixed32(<<13, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed32_oneof_test() {
  let assert Ok(s.ChoiceFixed32(None)) = s.decode_choice_fixed32(<<>>)
  let assert Ok(s.ChoiceFixed32(Some(s.ChoiceFixed32SelectionValue(0)))) =
    s.decode_choice_fixed32(<<13, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceFixed32(Some(s.ChoiceFixed32SelectionValue(1)))) =
    s.decode_choice_fixed32(<<13, 1, 0, 0, 0>>)
  let assert <<13, 0, 0, 0, 0>> =
    s.encode_choice_fixed32(
      s.ChoiceFixed32(Some(s.ChoiceFixed32SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed32_repeated_test() {
  let assert Ok(s.RepeatedFixed32([1, 2])) =
    s.decode_repeated_fixed32(<<10, 8, 1, 0, 0, 0, 2, 0, 0, 0>>)
  let assert Ok(s.RepeatedFixed32([1, 2])) =
    s.decode_repeated_fixed32(<<13, 1, 0, 0, 0, 13, 2, 0, 0, 0>>)
  let assert Ok(s.RepeatedFixed32([1, 1, 2, 2])) =
    s.decode_repeated_fixed32(<<
      13,
      1,
      0,
      0,
      0,
      10,
      8,
      1,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      13,
      2,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedFixed32([1, 2])) =
    s.decode_repeated_fixed32(<<10, 0, 10, 8, 1, 0, 0, 0, 2, 0, 0, 0, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed64_defaults_test() {
  let assert Ok(s.ScalarFixed64(0)) = s.decode_scalar_fixed64(<<>>)
  let assert Ok(s.OptionalFixed64(None)) = s.decode_optional_fixed64(<<>>)
  let assert Ok(s.OptionalFixed64(Some(0))) =
    s.decode_optional_fixed64(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed64_oneof_test() {
  let assert Ok(s.ChoiceFixed64(None)) = s.decode_choice_fixed64(<<>>)
  let assert Ok(s.ChoiceFixed64(Some(s.ChoiceFixed64SelectionValue(0)))) =
    s.decode_choice_fixed64(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceFixed64(Some(s.ChoiceFixed64SelectionValue(1)))) =
    s.decode_choice_fixed64(<<9, 1, 0, 0, 0, 0, 0, 0, 0>>)
  let assert <<9, 0, 0, 0, 0, 0, 0, 0, 0>> =
    s.encode_choice_fixed64(
      s.ChoiceFixed64(Some(s.ChoiceFixed64SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed64_repeated_test() {
  let assert Ok(s.RepeatedFixed64([1, 2])) =
    s.decode_repeated_fixed64(<<
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedFixed64([1, 2])) =
    s.decode_repeated_fixed64(<<
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedFixed64([1, 1, 2, 2])) =
    s.decode_repeated_fixed64(<<
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedFixed64([1, 2])) =
    s.decode_repeated_fixed64(<<
      10,
      0,
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      0,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed32_defaults_test() {
  let assert Ok(s.ScalarSfixed32(0)) = s.decode_scalar_sfixed32(<<>>)
  let assert Ok(s.OptionalSfixed32(None)) = s.decode_optional_sfixed32(<<>>)
  let assert Ok(s.OptionalSfixed32(Some(0))) =
    s.decode_optional_sfixed32(<<13, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed32_oneof_test() {
  let assert Ok(s.ChoiceSfixed32(None)) = s.decode_choice_sfixed32(<<>>)
  let assert Ok(s.ChoiceSfixed32(Some(s.ChoiceSfixed32SelectionValue(0)))) =
    s.decode_choice_sfixed32(<<13, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceSfixed32(Some(s.ChoiceSfixed32SelectionValue(1)))) =
    s.decode_choice_sfixed32(<<13, 1, 0, 0, 0>>)
  let assert <<13, 0, 0, 0, 0>> =
    s.encode_choice_sfixed32(
      s.ChoiceSfixed32(Some(s.ChoiceSfixed32SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed32_repeated_test() {
  let assert Ok(s.RepeatedSfixed32([1, 2])) =
    s.decode_repeated_sfixed32(<<10, 8, 1, 0, 0, 0, 2, 0, 0, 0>>)
  let assert Ok(s.RepeatedSfixed32([1, 2])) =
    s.decode_repeated_sfixed32(<<13, 1, 0, 0, 0, 13, 2, 0, 0, 0>>)
  let assert Ok(s.RepeatedSfixed32([1, 1, 2, 2])) =
    s.decode_repeated_sfixed32(<<
      13,
      1,
      0,
      0,
      0,
      10,
      8,
      1,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      13,
      2,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed32([1, 2])) =
    s.decode_repeated_sfixed32(<<10, 0, 10, 8, 1, 0, 0, 0, 2, 0, 0, 0, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed64_defaults_test() {
  let assert Ok(s.ScalarSfixed64(0)) = s.decode_scalar_sfixed64(<<>>)
  let assert Ok(s.OptionalSfixed64(None)) = s.decode_optional_sfixed64(<<>>)
  let assert Ok(s.OptionalSfixed64(Some(0))) =
    s.decode_optional_sfixed64(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed64_oneof_test() {
  let assert Ok(s.ChoiceSfixed64(None)) = s.decode_choice_sfixed64(<<>>)
  let assert Ok(s.ChoiceSfixed64(Some(s.ChoiceSfixed64SelectionValue(0)))) =
    s.decode_choice_sfixed64(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceSfixed64(Some(s.ChoiceSfixed64SelectionValue(1)))) =
    s.decode_choice_sfixed64(<<9, 1, 0, 0, 0, 0, 0, 0, 0>>)
  let assert <<9, 0, 0, 0, 0, 0, 0, 0, 0>> =
    s.encode_choice_sfixed64(
      s.ChoiceSfixed64(Some(s.ChoiceSfixed64SelectionValue(0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed64_repeated_test() {
  let assert Ok(s.RepeatedSfixed64([1, 2])) =
    s.decode_repeated_sfixed64(<<
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed64([1, 2])) =
    s.decode_repeated_sfixed64(<<
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed64([1, 1, 2, 2])) =
    s.decode_repeated_sfixed64(<<
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed64([1, 2])) =
    s.decode_repeated_sfixed64(<<
      10,
      0,
      10,
      16,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      0,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn float_defaults_test() {
  let assert Ok(s.ScalarFloat(0.0)) = s.decode_scalar_float(<<>>)
  let assert Ok(s.OptionalFloat(None)) = s.decode_optional_float(<<>>)
  let assert Ok(s.OptionalFloat(Some(0.0))) =
    s.decode_optional_float(<<13, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn float_oneof_test() {
  let assert Ok(s.ChoiceFloat(None)) = s.decode_choice_float(<<>>)
  let assert Ok(s.ChoiceFloat(Some(s.ChoiceFloatSelectionValue(0.0)))) =
    s.decode_choice_float(<<13, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceFloat(Some(s.ChoiceFloatSelectionValue(1.0)))) =
    s.decode_choice_float(<<13, 0, 0, 128, 63>>)
  let assert <<13, 0, 0, 0, 0>> =
    s.encode_choice_float(s.ChoiceFloat(Some(s.ChoiceFloatSelectionValue(0.0))))
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn float_repeated_test() {
  let assert Ok(s.RepeatedFloat([1.0, 2.0])) =
    s.decode_repeated_float(<<10, 8, 0, 0, 128, 63, 0, 0, 0, 64>>)
  let assert Ok(s.RepeatedFloat([1.0, 2.0])) =
    s.decode_repeated_float(<<13, 0, 0, 128, 63, 13, 0, 0, 0, 64>>)
  let assert Ok(s.RepeatedFloat([1.0, 1.0, 2.0, 2.0])) =
    s.decode_repeated_float(<<
      13,
      0,
      0,
      128,
      63,
      10,
      8,
      0,
      0,
      128,
      63,
      0,
      0,
      0,
      64,
      13,
      0,
      0,
      0,
      64,
    >>)
  let assert Ok(s.RepeatedFloat([1.0, 2.0])) =
    s.decode_repeated_float(<<10, 0, 10, 8, 0, 0, 128, 63, 0, 0, 0, 64, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn double_defaults_test() {
  let assert Ok(s.ScalarDouble(0.0)) = s.decode_scalar_double(<<>>)
  let assert Ok(s.OptionalDouble(None)) = s.decode_optional_double(<<>>)
  let assert Ok(s.OptionalDouble(Some(0.0))) =
    s.decode_optional_double(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn double_oneof_test() {
  let assert Ok(s.ChoiceDouble(None)) = s.decode_choice_double(<<>>)
  let assert Ok(s.ChoiceDouble(Some(s.ChoiceDoubleSelectionValue(0.0)))) =
    s.decode_choice_double(<<9, 0, 0, 0, 0, 0, 0, 0, 0>>)
  let assert Ok(s.ChoiceDouble(Some(s.ChoiceDoubleSelectionValue(1.0)))) =
    s.decode_choice_double(<<9, 0, 0, 0, 0, 0, 0, 240, 63>>)
  let assert <<9, 0, 0, 0, 0, 0, 0, 0, 0>> =
    s.encode_choice_double(
      s.ChoiceDouble(Some(s.ChoiceDoubleSelectionValue(0.0))),
    )
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn double_repeated_test() {
  let assert Ok(s.RepeatedDouble([1.0, 2.0])) =
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
      63,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
    >>)
  let assert Ok(s.RepeatedDouble([1.0, 2.0])) =
    s.decode_repeated_double(<<
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
    >>)
  let assert Ok(s.RepeatedDouble([1.0, 1.0, 2.0, 2.0])) =
    s.decode_repeated_double(<<
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
      10,
      16,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
    >>)
  let assert Ok(s.RepeatedDouble([1.0, 2.0])) =
    s.decode_repeated_double(<<
      10,
      0,
      10,
      16,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
      10,
      0,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn bool_defaults_test() {
  let assert Ok(s.ScalarBool(False)) = s.decode_scalar_bool(<<>>)
  let assert Ok(s.OptionalBool(None)) = s.decode_optional_bool(<<>>)
  let assert Ok(s.OptionalBool(Some(False))) = s.decode_optional_bool(<<8, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn bool_oneof_test() {
  let assert Ok(s.ChoiceBool(None)) = s.decode_choice_bool(<<>>)
  let assert Ok(s.ChoiceBool(Some(s.ChoiceBoolSelectionValue(False)))) =
    s.decode_choice_bool(<<8, 0>>)
  let assert Ok(s.ChoiceBool(Some(s.ChoiceBoolSelectionValue(True)))) =
    s.decode_choice_bool(<<8, 1>>)
  let assert <<8, 0>> =
    s.encode_choice_bool(s.ChoiceBool(Some(s.ChoiceBoolSelectionValue(False))))
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn bool_repeated_test() {
  let assert Ok(s.RepeatedBool([True, False])) =
    s.decode_repeated_bool(<<10, 2, 1, 0>>)
  let assert Ok(s.RepeatedBool([True, False])) =
    s.decode_repeated_bool(<<8, 1, 8, 0>>)
  let assert Ok(s.RepeatedBool([True, True, False, False])) =
    s.decode_repeated_bool(<<8, 1, 10, 2, 1, 0, 8, 0>>)
  let assert Ok(s.RepeatedBool([True, False])) =
    s.decode_repeated_bool(<<10, 0, 10, 2, 1, 0, 10, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_negative_test() {
  let assert Ok(s.ChoiceInt32(Some(s.ChoiceInt32SelectionValue(-1)))) =
    s.decode_choice_int32(<<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>)
  let assert Ok(s.RepeatedInt32([-1, 1])) =
    s.decode_repeated_int32(<<
      10,
      11,
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
      1,
    >>)
  let assert Ok(s.RepeatedInt32([-1, 1])) =
    s.decode_repeated_int32(<<
      8,
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
      8,
      1,
    >>)
  let assert Ok(s.RepeatedInt32([-1, -1, 1, 1])) =
    s.decode_repeated_int32(<<
      8,
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
      10,
      11,
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
      1,
      8,
      1,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_negative_test() {
  let assert Ok(s.ChoiceInt64(Some(s.ChoiceInt64SelectionValue(-1)))) =
    s.decode_choice_int64(<<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>)
  let assert Ok(s.RepeatedInt64([-1, 1])) =
    s.decode_repeated_int64(<<
      10,
      11,
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
      1,
    >>)
  let assert Ok(s.RepeatedInt64([-1, 1])) =
    s.decode_repeated_int64(<<
      8,
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
      8,
      1,
    >>)
  let assert Ok(s.RepeatedInt64([-1, -1, 1, 1])) =
    s.decode_repeated_int64(<<
      8,
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
      10,
      11,
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
      1,
      8,
      1,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_negative_test() {
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(-1)))) =
    s.decode_choice_sint32(<<8, 1>>)
  let assert Ok(s.RepeatedSint32([-1, 1])) =
    s.decode_repeated_sint32(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedSint32([-1, 1])) =
    s.decode_repeated_sint32(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedSint32([-1, -1, 1, 1])) =
    s.decode_repeated_sint32(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_negative_test() {
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(-1)))) =
    s.decode_choice_sint64(<<8, 1>>)
  let assert Ok(s.RepeatedSint64([-1, 1])) =
    s.decode_repeated_sint64(<<10, 2, 1, 2>>)
  let assert Ok(s.RepeatedSint64([-1, 1])) =
    s.decode_repeated_sint64(<<8, 1, 8, 2>>)
  let assert Ok(s.RepeatedSint64([-1, -1, 1, 1])) =
    s.decode_repeated_sint64(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed32_negative_test() {
  let assert Ok(s.ChoiceSfixed32(Some(s.ChoiceSfixed32SelectionValue(-1)))) =
    s.decode_choice_sfixed32(<<13, 255, 255, 255, 255>>)
  let assert Ok(s.RepeatedSfixed32([-1, 1])) =
    s.decode_repeated_sfixed32(<<10, 8, 255, 255, 255, 255, 1, 0, 0, 0>>)
  let assert Ok(s.RepeatedSfixed32([-1, 1])) =
    s.decode_repeated_sfixed32(<<13, 255, 255, 255, 255, 13, 1, 0, 0, 0>>)
  let assert Ok(s.RepeatedSfixed32([-1, -1, 1, 1])) =
    s.decode_repeated_sfixed32(<<
      13,
      255,
      255,
      255,
      255,
      10,
      8,
      255,
      255,
      255,
      255,
      1,
      0,
      0,
      0,
      13,
      1,
      0,
      0,
      0,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed64_negative_test() {
  let assert Ok(s.ChoiceSfixed64(Some(s.ChoiceSfixed64SelectionValue(-1)))) =
    s.decode_choice_sfixed64(<<9, 255, 255, 255, 255, 255, 255, 255, 255>>)
  let assert Ok(s.RepeatedSfixed64([-1, 1])) =
    s.decode_repeated_sfixed64(<<
      10,
      16,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed64([-1, 1])) =
    s.decode_repeated_sfixed64(<<
      9,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  let assert Ok(s.RepeatedSfixed64([-1, -1, 1, 1])) =
    s.decode_repeated_sfixed64(<<
      9,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      10,
      16,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn float_negative_test() {
  let assert Ok(s.ChoiceFloat(Some(s.ChoiceFloatSelectionValue(-1.0)))) =
    s.decode_choice_float(<<13, 0, 0, 128, 191>>)
  let assert Ok(s.RepeatedFloat([-1.0, 1.0])) =
    s.decode_repeated_float(<<10, 8, 0, 0, 128, 191, 0, 0, 128, 63>>)
  let assert Ok(s.RepeatedFloat([-1.0, 1.0])) =
    s.decode_repeated_float(<<13, 0, 0, 128, 191, 13, 0, 0, 128, 63>>)
  let assert Ok(s.RepeatedFloat([-1.0, -1.0, 1.0, 1.0])) =
    s.decode_repeated_float(<<
      13,
      0,
      0,
      128,
      191,
      10,
      8,
      0,
      0,
      128,
      191,
      0,
      0,
      128,
      63,
      13,
      0,
      0,
      128,
      63,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn double_negative_test() {
  let assert Ok(s.ChoiceDouble(Some(s.ChoiceDoubleSelectionValue(-1.0)))) =
    s.decode_choice_double(<<9, 0, 0, 0, 0, 0, 0, 240, 191>>)
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
  let assert Ok(s.RepeatedDouble([-1.0, 1.0])) =
    s.decode_repeated_double(<<
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      191,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
    >>)
  let assert Ok(s.RepeatedDouble([-1.0, -1.0, 1.0, 1.0])) =
    s.decode_repeated_double(<<
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      191,
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
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_map_defaults_test() {
  let assert Ok(s.MapInt32([#(0, 0)])) = s.decode_map_int32(<<10, 0>>)
  let assert Ok(s.MapInt32([#(1, 0)])) = s.decode_map_int32(<<10, 2, 8, 1>>)
  let assert Ok(s.MapInt32([#(0, 1)])) = s.decode_map_int32(<<10, 2, 16, 1>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_map_defaults_test() {
  let assert Ok(s.MapInt64([#(0, 0)])) = s.decode_map_int64(<<10, 0>>)
  let assert Ok(s.MapInt64([#(1, 0)])) = s.decode_map_int64(<<10, 2, 8, 1>>)
  let assert Ok(s.MapInt64([#(0, 1)])) = s.decode_map_int64(<<10, 2, 16, 1>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint32_map_defaults_test() {
  let assert Ok(s.MapUint32([#(0, 0)])) = s.decode_map_uint32(<<10, 0>>)
  let assert Ok(s.MapUint32([#(1, 0)])) = s.decode_map_uint32(<<10, 2, 8, 1>>)
  let assert Ok(s.MapUint32([#(0, 1)])) = s.decode_map_uint32(<<10, 2, 16, 1>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn uint64_map_defaults_test() {
  let assert Ok(s.MapUint64([#(0, 0)])) = s.decode_map_uint64(<<10, 0>>)
  let assert Ok(s.MapUint64([#(1, 0)])) = s.decode_map_uint64(<<10, 2, 8, 1>>)
  let assert Ok(s.MapUint64([#(0, 1)])) = s.decode_map_uint64(<<10, 2, 16, 1>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_map_defaults_test() {
  let assert Ok(s.MapSint32([#(0, 0)])) = s.decode_map_sint32(<<10, 0>>)
  let assert Ok(s.MapSint32([#(1, 0)])) = s.decode_map_sint32(<<10, 2, 8, 2>>)
  let assert Ok(s.MapSint32([#(0, 1)])) = s.decode_map_sint32(<<10, 2, 16, 2>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_map_defaults_test() {
  let assert Ok(s.MapSint64([#(0, 0)])) = s.decode_map_sint64(<<10, 0>>)
  let assert Ok(s.MapSint64([#(1, 0)])) = s.decode_map_sint64(<<10, 2, 8, 2>>)
  let assert Ok(s.MapSint64([#(0, 1)])) = s.decode_map_sint64(<<10, 2, 16, 2>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed32_map_defaults_test() {
  let assert Ok(s.MapFixed32([#(0, 0)])) = s.decode_map_fixed32(<<10, 0>>)
  let assert Ok(s.MapFixed32([#(1, 0)])) =
    s.decode_map_fixed32(<<10, 5, 13, 1, 0, 0, 0>>)
  let assert Ok(s.MapFixed32([#(0, 1)])) =
    s.decode_map_fixed32(<<10, 5, 21, 1, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed64_map_defaults_test() {
  let assert Ok(s.MapFixed64([#(0, 0)])) = s.decode_map_fixed64(<<10, 0>>)
  let assert Ok(s.MapFixed64([#(1, 0)])) =
    s.decode_map_fixed64(<<10, 9, 9, 1, 0, 0, 0, 0, 0, 0, 0>>)
  let assert Ok(s.MapFixed64([#(0, 1)])) =
    s.decode_map_fixed64(<<10, 9, 17, 1, 0, 0, 0, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed32_map_defaults_test() {
  let assert Ok(s.MapSfixed32([#(0, 0)])) = s.decode_map_sfixed32(<<10, 0>>)
  let assert Ok(s.MapSfixed32([#(1, 0)])) =
    s.decode_map_sfixed32(<<10, 5, 13, 1, 0, 0, 0>>)
  let assert Ok(s.MapSfixed32([#(0, 1)])) =
    s.decode_map_sfixed32(<<10, 5, 21, 1, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sfixed64_map_defaults_test() {
  let assert Ok(s.MapSfixed64([#(0, 0)])) = s.decode_map_sfixed64(<<10, 0>>)
  let assert Ok(s.MapSfixed64([#(1, 0)])) =
    s.decode_map_sfixed64(<<10, 9, 9, 1, 0, 0, 0, 0, 0, 0, 0>>)
  let assert Ok(s.MapSfixed64([#(0, 1)])) =
    s.decode_map_sfixed64(<<10, 9, 17, 1, 0, 0, 0, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn float_map_defaults_test() {
  let assert Ok(s.MapFloat([#(0, 0.0)])) = s.decode_map_float(<<10, 0>>)
  let assert Ok(s.MapFloat([#(1, 0.0)])) = s.decode_map_float(<<10, 2, 8, 2>>)
  let assert Ok(s.MapFloat([#(0, 1.0)])) =
    s.decode_map_float(<<10, 5, 21, 0, 0, 128, 63>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn double_map_defaults_test() {
  let assert Ok(s.MapDouble([#(0, 0.0)])) = s.decode_map_double(<<10, 0>>)
  let assert Ok(s.MapDouble([#(1, 0.0)])) = s.decode_map_double(<<10, 2, 8, 2>>)
  let assert Ok(s.MapDouble([#(0, 1.0)])) =
    s.decode_map_double(<<10, 9, 17, 0, 0, 0, 0, 0, 0, 240, 63>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn enum_repeated_test() {
  let assert Ok(s.EnumList([s.First, s.Second])) =
    s.decode_enum_list(<<10, 2, 1, 2>>)
  let assert Ok(s.EnumList([s.First, s.Second])) =
    s.decode_enum_list(<<8, 1, 8, 2>>)
  let assert Ok(s.EnumList([s.First, s.First, s.Second, s.Second])) =
    s.decode_enum_list(<<8, 1, 10, 2, 1, 2, 8, 2>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn packed_errors_test() {
  let assert Error(_) = s.decode_repeated_int64(<<10, 1, 128>>)
  let assert Error(_) =
    s.decode_repeated_uint64(<<
      10,
      10,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      2,
    >>)
  let assert Error(_) = s.decode_repeated_fixed32(<<10, 3, 1, 2, 3>>)
  let assert Error(_) = s.decode_repeated_double(<<10, 1, 0>>)
  let assert Error(_) = s.decode_repeated_bool(<<13, 0, 0, 0, 0>>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn packed_only_test() {
  let assert Ok(p.PackedOnly([1.0, 2.0])) =
    p.decode_packed_only(<<
      10,
      16,
      0,
      0,
      0,
      0,
      0,
      0,
      240,
      63,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      64,
    >>)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint32_safe_boundaries_test() {
  let assert Ok(s.MapSint32([#(-2_147_483_648, -2_147_483_648)])) =
    s.decode_map_sint32(<<
      10,
      12,
      8,
      255,
      255,
      255,
      255,
      15,
      16,
      255,
      255,
      255,
      255,
      15,
    >>)
  let assert Ok(s.ScalarSint32(-2_147_483_648)) =
    s.decode_scalar_sint32(<<8, 255, 255, 255, 255, 15>>)
  let assert Ok(s.OptionalSint32(Some(-2_147_483_648))) =
    s.decode_optional_sint32(<<8, 255, 255, 255, 255, 15>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(-2_147_483_648)))) =
    s.decode_choice_sint32(<<8, 255, 255, 255, 255, 15>>)
  let assert Ok(s.RepeatedSint32([-2_147_483_648])) =
    s.decode_repeated_sint32(<<10, 5, 255, 255, 255, 255, 15>>)
  let assert <<8, 255, 255, 255, 255, 15>> =
    s.encode_scalar_sint32(s.ScalarSint32(-2_147_483_648))
  let assert Ok(s.MapSint32([#(-2_147_483_647, -2_147_483_647)])) =
    s.decode_map_sint32(<<
      10,
      12,
      8,
      253,
      255,
      255,
      255,
      15,
      16,
      253,
      255,
      255,
      255,
      15,
    >>)
  let assert Ok(s.ScalarSint32(-2_147_483_647)) =
    s.decode_scalar_sint32(<<8, 253, 255, 255, 255, 15>>)
  let assert Ok(s.OptionalSint32(Some(-2_147_483_647))) =
    s.decode_optional_sint32(<<8, 253, 255, 255, 255, 15>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(-2_147_483_647)))) =
    s.decode_choice_sint32(<<8, 253, 255, 255, 255, 15>>)
  let assert Ok(s.RepeatedSint32([-2_147_483_647])) =
    s.decode_repeated_sint32(<<10, 5, 253, 255, 255, 255, 15>>)
  let assert <<8, 253, 255, 255, 255, 15>> =
    s.encode_scalar_sint32(s.ScalarSint32(-2_147_483_647))
  let assert Ok(s.MapSint32([#(2_147_483_646, 2_147_483_646)])) =
    s.decode_map_sint32(<<
      10,
      12,
      8,
      252,
      255,
      255,
      255,
      15,
      16,
      252,
      255,
      255,
      255,
      15,
    >>)
  let assert Ok(s.ScalarSint32(2_147_483_646)) =
    s.decode_scalar_sint32(<<8, 252, 255, 255, 255, 15>>)
  let assert Ok(s.OptionalSint32(Some(2_147_483_646))) =
    s.decode_optional_sint32(<<8, 252, 255, 255, 255, 15>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(2_147_483_646)))) =
    s.decode_choice_sint32(<<8, 252, 255, 255, 255, 15>>)
  let assert Ok(s.RepeatedSint32([2_147_483_646])) =
    s.decode_repeated_sint32(<<10, 5, 252, 255, 255, 255, 15>>)
  let assert <<8, 252, 255, 255, 255, 15>> =
    s.encode_scalar_sint32(s.ScalarSint32(2_147_483_646))
  let assert Ok(s.MapSint32([#(2_147_483_647, 2_147_483_647)])) =
    s.decode_map_sint32(<<
      10,
      12,
      8,
      254,
      255,
      255,
      255,
      15,
      16,
      254,
      255,
      255,
      255,
      15,
    >>)
  let assert Ok(s.ScalarSint32(2_147_483_647)) =
    s.decode_scalar_sint32(<<8, 254, 255, 255, 255, 15>>)
  let assert Ok(s.OptionalSint32(Some(2_147_483_647))) =
    s.decode_optional_sint32(<<8, 254, 255, 255, 255, 15>>)
  let assert Ok(s.ChoiceSint32(Some(s.ChoiceSint32SelectionValue(2_147_483_647)))) =
    s.decode_choice_sint32(<<8, 254, 255, 255, 255, 15>>)
  let assert Ok(s.RepeatedSint32([2_147_483_647])) =
    s.decode_repeated_sint32(<<10, 5, 254, 255, 255, 255, 15>>)
  let assert <<8, 254, 255, 255, 255, 15>> =
    s.encode_scalar_sint32(s.ScalarSint32(2_147_483_647))
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_safe_boundaries_test() {
  let assert Ok(s.MapSint64([#(-9_007_199_254_740_991, -9_007_199_254_740_991)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      253,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
      16,
      253,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
    >>)
  let assert Ok(s.ScalarSint64(-9_007_199_254_740_991)) =
    s.decode_scalar_sint64(<<8, 253, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.OptionalSint64(Some(-9_007_199_254_740_991))) =
    s.decode_optional_sint64(<<8, 253, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    -9_007_199_254_740_991,
  )))) = s.decode_choice_sint64(<<8, 253, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.RepeatedSint64([-9_007_199_254_740_991])) =
    s.decode_repeated_sint64(<<10, 8, 253, 255, 255, 255, 255, 255, 255, 31>>)
  let assert <<8, 253, 255, 255, 255, 255, 255, 255, 31>> =
    s.encode_scalar_sint64(s.ScalarSint64(-9_007_199_254_740_991))
  let assert Ok(s.MapSint64([#(-9_007_199_254_740_990, -9_007_199_254_740_990)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      251,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
      16,
      251,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
    >>)
  let assert Ok(s.ScalarSint64(-9_007_199_254_740_990)) =
    s.decode_scalar_sint64(<<8, 251, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.OptionalSint64(Some(-9_007_199_254_740_990))) =
    s.decode_optional_sint64(<<8, 251, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    -9_007_199_254_740_990,
  )))) = s.decode_choice_sint64(<<8, 251, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.RepeatedSint64([-9_007_199_254_740_990])) =
    s.decode_repeated_sint64(<<10, 8, 251, 255, 255, 255, 255, 255, 255, 31>>)
  let assert <<8, 251, 255, 255, 255, 255, 255, 255, 31>> =
    s.encode_scalar_sint64(s.ScalarSint64(-9_007_199_254_740_990))
  let assert Ok(s.MapSint64([#(-4_503_599_627_370_497, -4_503_599_627_370_497)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      129,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
      16,
      129,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
    >>)
  let assert Ok(s.ScalarSint64(-4_503_599_627_370_497)) =
    s.decode_scalar_sint64(<<8, 129, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.OptionalSint64(Some(-4_503_599_627_370_497))) =
    s.decode_optional_sint64(<<8, 129, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    -4_503_599_627_370_497,
  )))) = s.decode_choice_sint64(<<8, 129, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.RepeatedSint64([-4_503_599_627_370_497])) =
    s.decode_repeated_sint64(<<10, 8, 129, 128, 128, 128, 128, 128, 128, 16>>)
  let assert <<8, 129, 128, 128, 128, 128, 128, 128, 16>> =
    s.encode_scalar_sint64(s.ScalarSint64(-4_503_599_627_370_497))
  let assert Ok(s.MapSint64([#(-4_503_599_627_370_496, -4_503_599_627_370_496)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      15,
      16,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      15,
    >>)
  let assert Ok(s.ScalarSint64(-4_503_599_627_370_496)) =
    s.decode_scalar_sint64(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>)
  let assert Ok(s.OptionalSint64(Some(-4_503_599_627_370_496))) =
    s.decode_optional_sint64(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    -4_503_599_627_370_496,
  )))) = s.decode_choice_sint64(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>)
  let assert Ok(s.RepeatedSint64([-4_503_599_627_370_496])) =
    s.decode_repeated_sint64(<<10, 8, 255, 255, 255, 255, 255, 255, 255, 15>>)
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 15>> =
    s.encode_scalar_sint64(s.ScalarSint64(-4_503_599_627_370_496))
  let assert Ok(s.MapSint64([#(4_503_599_627_370_496, 4_503_599_627_370_496)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      128,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
      16,
      128,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
    >>)
  let assert Ok(s.ScalarSint64(4_503_599_627_370_496)) =
    s.decode_scalar_sint64(<<8, 128, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.OptionalSint64(Some(4_503_599_627_370_496))) =
    s.decode_optional_sint64(<<8, 128, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    4_503_599_627_370_496,
  )))) = s.decode_choice_sint64(<<8, 128, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.RepeatedSint64([4_503_599_627_370_496])) =
    s.decode_repeated_sint64(<<10, 8, 128, 128, 128, 128, 128, 128, 128, 16>>)
  let assert <<8, 128, 128, 128, 128, 128, 128, 128, 16>> =
    s.encode_scalar_sint64(s.ScalarSint64(4_503_599_627_370_496))
  let assert Ok(s.MapSint64([#(4_503_599_627_370_497, 4_503_599_627_370_497)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      130,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
      16,
      130,
      128,
      128,
      128,
      128,
      128,
      128,
      16,
    >>)
  let assert Ok(s.ScalarSint64(4_503_599_627_370_497)) =
    s.decode_scalar_sint64(<<8, 130, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.OptionalSint64(Some(4_503_599_627_370_497))) =
    s.decode_optional_sint64(<<8, 130, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    4_503_599_627_370_497,
  )))) = s.decode_choice_sint64(<<8, 130, 128, 128, 128, 128, 128, 128, 16>>)
  let assert Ok(s.RepeatedSint64([4_503_599_627_370_497])) =
    s.decode_repeated_sint64(<<10, 8, 130, 128, 128, 128, 128, 128, 128, 16>>)
  let assert <<8, 130, 128, 128, 128, 128, 128, 128, 16>> =
    s.encode_scalar_sint64(s.ScalarSint64(4_503_599_627_370_497))
  let assert Ok(s.MapSint64([#(9_007_199_254_740_990, 9_007_199_254_740_990)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      252,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
      16,
      252,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
    >>)
  let assert Ok(s.ScalarSint64(9_007_199_254_740_990)) =
    s.decode_scalar_sint64(<<8, 252, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.OptionalSint64(Some(9_007_199_254_740_990))) =
    s.decode_optional_sint64(<<8, 252, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    9_007_199_254_740_990,
  )))) = s.decode_choice_sint64(<<8, 252, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.RepeatedSint64([9_007_199_254_740_990])) =
    s.decode_repeated_sint64(<<10, 8, 252, 255, 255, 255, 255, 255, 255, 31>>)
  let assert <<8, 252, 255, 255, 255, 255, 255, 255, 31>> =
    s.encode_scalar_sint64(s.ScalarSint64(9_007_199_254_740_990))
  let assert Ok(s.MapSint64([#(9_007_199_254_740_991, 9_007_199_254_740_991)])) =
    s.decode_map_sint64(<<
      10,
      18,
      8,
      254,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
      16,
      254,
      255,
      255,
      255,
      255,
      255,
      255,
      31,
    >>)
  let assert Ok(s.ScalarSint64(9_007_199_254_740_991)) =
    s.decode_scalar_sint64(<<8, 254, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.OptionalSint64(Some(9_007_199_254_740_991))) =
    s.decode_optional_sint64(<<8, 254, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.ChoiceSint64(Some(s.ChoiceSint64SelectionValue(
    9_007_199_254_740_991,
  )))) = s.decode_choice_sint64(<<8, 254, 255, 255, 255, 255, 255, 255, 31>>)
  let assert Ok(s.RepeatedSint64([9_007_199_254_740_991])) =
    s.decode_repeated_sint64(<<10, 8, 254, 255, 255, 255, 255, 255, 255, 31>>)
  let assert <<8, 254, 255, 255, 255, 255, 255, 255, 31>> =
    s.encode_scalar_sint64(s.ScalarSint64(9_007_199_254_740_991))
  Nil
}

@target(erlang)
/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn sint64_full_endpoints_test() {
  let assert Ok(s.ScalarSint64(-9_223_372_036_854_775_808)) =
    s.decode_scalar_sint64(<<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>)
  let assert Ok(s.ScalarSint64(9_223_372_036_854_775_807)) =
    s.decode_scalar_sint64(<<8, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1>>)
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    s.encode_scalar_sint64(s.ScalarSint64(-9_223_372_036_854_775_808))
  let assert <<8, 254, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    s.encode_scalar_sint64(s.ScalarSint64(9_223_372_036_854_775_807))
  Nil
}

import gleam/bit_array
import gleam/list

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int64_large_packed_test() {
  let payload = bit_array.concat(list.repeat(<<1>>, 12_000))
  let packed = bit_array.concat([<<10, 224, 93>>, payload])
  let assert Ok(s.RepeatedInt64(values)) = s.decode_repeated_int64(packed)
  let assert True = values == list.repeat(1, 12_000)
  let mixed = bit_array.concat([<<8, 1>>, packed, <<8, 1>>])
  let assert Ok(s.RepeatedInt64(values)) = s.decode_repeated_int64(mixed)
  let assert True = values == list.repeat(1, 12_002)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn int32_large_packed_test() {
  let payload = bit_array.concat(list.repeat(<<1>>, 12_000))
  let packed = bit_array.concat([<<10, 224, 93>>, payload])
  let assert Ok(s.RepeatedInt32(values)) = s.decode_repeated_int32(packed)
  let assert True = values == list.repeat(1, 12_000)
  let mixed = bit_array.concat([<<8, 1>>, packed, <<8, 1>>])
  let assert Ok(s.RepeatedInt32(values)) = s.decode_repeated_int32(mixed)
  let assert True = values == list.repeat(1, 12_002)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed32_large_packed_test() {
  let payload = bit_array.concat(list.repeat(<<1, 0, 0, 0>>, 12_000))
  let packed = bit_array.concat([<<10, 128, 247, 2>>, payload])
  let assert Ok(s.RepeatedFixed32(values)) = s.decode_repeated_fixed32(packed)
  let assert True = values == list.repeat(1, 12_000)
  let mixed = bit_array.concat([<<13, 1, 0, 0, 0>>, packed, <<13, 1, 0, 0, 0>>])
  let assert Ok(s.RepeatedFixed32(values)) = s.decode_repeated_fixed32(mixed)
  let assert True = values == list.repeat(1, 12_002)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn fixed64_large_packed_test() {
  let payload =
    bit_array.concat(list.repeat(<<1, 0, 0, 0, 0, 0, 0, 0>>, 12_000))
  let packed = bit_array.concat([<<10, 128, 238, 5>>, payload])
  let assert Ok(s.RepeatedFixed64(values)) = s.decode_repeated_fixed64(packed)
  let assert True = values == list.repeat(1, 12_000)
  let mixed =
    bit_array.concat([
      <<9, 1, 0, 0, 0, 0, 0, 0, 0>>,
      packed,
      <<9, 1, 0, 0, 0, 0, 0, 0, 0>>,
    ])
  let assert Ok(s.RepeatedFixed64(values)) = s.decode_repeated_fixed64(mixed)
  let assert True = values == list.repeat(1, 12_002)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn enum_list_large_packed_test() {
  let payload = bit_array.concat(list.repeat(<<1>>, 12_000))
  let packed = bit_array.concat([<<10, 224, 93>>, payload])
  let assert Ok(s.EnumList(values)) = s.decode_enum_list(packed)
  let assert True = values == list.repeat(s.First, 12_000)
  let mixed = bit_array.concat([<<8, 1>>, packed, <<8, 1>>])
  let assert Ok(s.EnumList(values)) = s.decode_enum_list(mixed)
  let assert True = values == list.repeat(s.First, 12_002)
  Nil
}

/// Independent oracle assertions; no arguments/errors. Run with `gleam test`.
pub fn packed_int32_enum_errors_test() {
  let assert Error(_) = s.decode_repeated_int32(<<10, 1, 128>>)
  let assert Error(_) = s.decode_enum_list(<<10, 1, 128>>)
  let assert Error(_) =
    s.decode_repeated_int32(<<
      10,
      10,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      2,
    >>)
  Nil
}
