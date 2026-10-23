import dozen
import gleam/option.{None, Some}
import gleeunit
import many
import mixed
import score

pub fn main() {
  gleeunit.main()
}

pub fn scalar_roundtrip_test() {
  let value = mixed.Envelope(Some(mixed.EnvelopeChoiceNumber(42)))
  let assert <<8, 42>> = mixed.encode_envelope(value)
  let assert True = Ok(value) == mixed.decode_envelope(<<8, 42>>)
}

pub fn message_roundtrip_test() {
  let value =
    mixed.Envelope(Some(mixed.EnvelopeChoiceNested(mixed.Detail("Hi"))))
  let assert <<18, 4, 10, 2, 72, 105>> = mixed.encode_envelope(value)
  let assert True =
    Ok(value) == mixed.decode_envelope(<<18, 4, 10, 2, 72, 105>>)
}

pub fn absent_test() {
  let value = mixed.Envelope(None)
  let assert <<>> = mixed.encode_envelope(value)
  let assert True = Ok(value) == mixed.decode_envelope(<<>>)
}

pub fn wire_order_test() {
  let number = mixed.Envelope(Some(mixed.EnvelopeChoiceNumber(42)))
  let nested =
    mixed.Envelope(Some(mixed.EnvelopeChoiceNested(mixed.Detail("Hi"))))
  let assert True =
    Ok(nested) == mixed.decode_envelope(<<8, 42, 18, 4, 10, 2, 72, 105>>)
  let assert True =
    Ok(number) == mixed.decode_envelope(<<18, 4, 10, 2, 72, 105, 8, 42>>)
  let assert Ok(mixed.Envelope(Some(mixed.EnvelopeChoiceNumber(7)))) =
    mixed.decode_envelope(<<8, 42, 8, 7>>)
}

pub fn wrong_wire_is_unknown_test() {
  let nested =
    mixed.Envelope(Some(mixed.EnvelopeChoiceNested(mixed.Detail("Hi"))))
  let assert True =
    Ok(nested) == mixed.decode_envelope(<<10, 1, 0, 18, 4, 10, 2, 72, 105>>)
  let assert Ok(mixed.Envelope(None)) = mixed.decode_envelope(<<10, 1, 0>>)
}

pub fn malformed_message_is_error_test() {
  let assert Error(_) = mixed.decode_envelope(<<18, 1, 128>>)
  let assert Error(_) = mixed.decode_envelope(<<10, 1, 0, 18, 1, 128>>)
  let assert Error(_) = mixed.decode_envelope(<<18, 1, 128, 24, 1>>)
  // Repeated occurrences of the same message alternative merge, not replace.
  let assert Ok(mixed.Envelope(Some(mixed.EnvelopeChoiceNested(mixed.Detail(
    "Hi",
  ))))) = mixed.decode_envelope(<<18, 4, 10, 2, 72, 105, 18, 0>>)
}

pub fn malformed_wire_is_error_test() {
  let assert Error(_) = mixed.decode_envelope(<<128>>)
}

pub fn large_fixture_roundtrips_test() {
  // The last alternative remains reachable even in the 56-case fixture.
  let a = dozen.Dozen(Some(dozen.DozenChoicePick12(42)))
  let assert <<96, 42>> = dozen.encode_dozen(a)
  let assert True = Ok(a) == dozen.decode_dozen(<<96, 42>>)
  let b = score.Score(Some(score.ScoreChoicePick20(42)))
  let assert <<160, 1, 42>> = score.encode_score(b)
  let assert True = Ok(b) == score.decode_score(<<160, 1, 42>>)
  let c = many.Many(Some(many.ManyChoicePick56(42)))
  let assert <<192, 3, 42>> = many.encode_many(c)
  let assert True = Ok(c) == many.decode_many(<<192, 3, 42>>)
  let assert Ok(many.Many(None)) = many.decode_many(<<>>)
  let assert Ok(many.Many(Some(many.ManyChoicePick01(7)))) =
    many.decode_many(<<192, 3, 42, 8, 7>>)
}
