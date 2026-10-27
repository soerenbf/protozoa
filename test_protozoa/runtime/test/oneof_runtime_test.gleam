//// Generated oneofs preserve last-on-wire selection and message merging/errors.

import generated/mixed as m
import gleam/option.{None, Some}

pub fn scalar_and_message_test() {
  // Field 1 selects number 42; field 2 selects Detail { value: "Hi" }.
  let number = m.Envelope(Some(m.EnvelopeChoiceNumber(42)))
  let nested = m.Envelope(Some(m.EnvelopeChoiceNested(m.Detail("Hi"))))
  let assert <<8, 42>> = m.encode_envelope(number)
  let assert Ok(value) = m.decode_envelope(<<8, 42>>)
  let assert True = value == number
  let assert <<18, 4, 10, 2, 72, 105>> = m.encode_envelope(nested)
  let assert Ok(value) = m.decode_envelope(<<18, 4, 10, 2, 72, 105>>)
  let assert True = value == nested
  // Field 56 selects true using a multi-byte tag, then field 1 can replace it.
  let flag = m.Envelope(Some(m.EnvelopeChoiceFlag(True)))
  let assert <<192, 3, 1>> = m.encode_envelope(flag)
  let assert Ok(value) = m.decode_envelope(<<192, 3, 1>>)
  let assert True = value == flag
  let assert Ok(value) = m.decode_envelope(<<192, 3, 1, 8, 42>>)
  let assert True = value == number
  // No field selects no alternative and encodes to no bytes.
  let assert Ok(m.Envelope(None)) = m.decode_envelope(<<>>)
  let assert <<>> = m.encode_envelope(m.Envelope(None))
}

pub fn wire_order_test() {
  // Field 1=42 then field 2="Hi", and the reverse: the last alternative wins.
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNested(m.Detail("Hi"))))) =
    m.decode_envelope(<<8, 42, 18, 4, 10, 2, 72, 105>>)
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNumber(42)))) =
    m.decode_envelope(<<18, 4, 10, 2, 72, 105, 8, 42>>)
  // Repeating scalar field 1 replaces 42 with 7.
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNumber(7)))) =
    m.decode_envelope(<<8, 42, 8, 7>>)
  // Switching field 2="Hi" to field 1=42 then empty field 2 resets message merging.
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNested(m.Detail(""))))) =
    m.decode_envelope(<<18, 4, 10, 2, 72, 105, 8, 42, 18, 0>>)
  // Repeating message field 2 with an empty message merges, preserving "Hi".
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNested(m.Detail("Hi"))))) =
    m.decode_envelope(<<18, 4, 10, 2, 72, 105, 18, 0>>)
}

pub fn wrong_wire_and_malformed_test() {
  // Field 1 has length-delimited bytes instead of varint; skip it, retaining field 2.
  let assert Ok(m.Envelope(Some(m.EnvelopeChoiceNested(m.Detail("Hi"))))) =
    m.decode_envelope(<<10, 1, 0, 18, 4, 10, 2, 72, 105>>)
  let assert Ok(m.Envelope(None)) = m.decode_envelope(<<10, 1, 0>>)
  // Field 2's message has a truncated tag, alone or with unknown fields around it.
  let assert Error(_) = m.decode_envelope(<<18, 1, 128>>)
  let assert Error(_) = m.decode_envelope(<<10, 1, 0, 18, 1, 128>>)
  let assert Error(_) = m.decode_envelope(<<18, 1, 128, 24, 1>>)
  // Malformed field 2 must not be hidden by a later valid scalar choice, field 1=42.
  let assert Error(_) = m.decode_envelope(<<18, 1, 128, 8, 42>>)
  // The outer tag itself is truncated.
  let assert Error(_) = m.decode_envelope(<<128>>)
}
