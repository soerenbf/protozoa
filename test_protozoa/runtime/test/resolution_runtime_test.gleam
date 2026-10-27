//// Generated codecs resolve nested, imported and shadowed names with owner prefixes.
//// Enum fields retain optional presence, packing and map semantics.

import generated/naming as n
import gleam/option.{None, Some}

pub fn enum_constructor_policy_test() {
  let assert 0 =
    n.encode_sample_base_child_unique_value(n.SampleBaseChildUniqueDistinct)
  let assert Ok(n.SampleBaseChildUniqueOther) =
    n.decode_sample_base_child_unique_value(1)
  let assert 0 =
    n.encode_sample_base_child_colliding_value(
      n.SampleBaseChildCollidingSampleBaseItem,
    )
  let assert Ok(n.SampleBaseChildCollidingSampleBaseChildFirstResponseV0) =
    n.decode_sample_base_child_colliding_value(1)
}

pub fn optional_enum_test() {
  // Field 1 is absent, explicit ZERO=0 or ONE=1; each enum retains its owning type.
  let assert Ok(absent) = n.decode_sample_base_child_first(<<>>)
  let assert None = absent.state
  let assert Ok(zero) = n.decode_sample_base_child_first(<<8, 0>>)
  let assert Some(n.SampleBaseChildFirstStateZero) = zero.state
  let assert <<8, 0>> = n.encode_sample_base_child_first(zero)
  let assert Ok(one) = n.decode_sample_base_child_second(<<8, 1>>)
  let assert Some(n.SampleBaseChildSecondStateOne) = one.state
  let assert <<8, 1>> = n.encode_sample_base_child_second(one)
}

pub fn deep_resolution_test() {
  // Fields 1..7 identify nearest Inner="x", parent Inner=7, sibling Inner=true,
  // absolute Item=9, ancestor Item=10, ancestor State=ONE, and local shadow Item="y".
  // Message fields are length-delimited; state is a varint.
  let bytes = <<
    10,
    3,
    10,
    1,
    120,
    18,
    2,
    8,
    7,
    26,
    2,
    8,
    1,
    34,
    2,
    8,
    9,
    42,
    2,
    8,
    10,
    48,
    1,
    58,
    3,
    10,
    1,
    121,
  >>
  let assert Ok(value) = n.decode_sample_base_child_first_middle_deep(bytes)
  let assert Some(n.SampleBaseChildFirstMiddleInner("x")) = value.nearest
  let assert Some(n.SampleBaseChildFirstInner(7)) = value.parent
  let assert Some(n.SampleBaseChildSecondInner(True)) = value.sibling
  let assert Some(n.SampleBaseItem(9)) = value.absolute
  let assert Some(n.SampleBaseItem(10)) = value.ancestor
  let assert Some(n.SampleBaseChildFirstStateOne) = value.state
  let assert Some(n.SampleBaseChildFirstMiddleDeepItem("y")) = value.shadow
  let assert Ok(roundtrip) =
    n.decode_sample_base_child_first_middle_deep(
      n.encode_sample_base_child_first_middle_deep(value),
    )
  let assert True = roundtrip == value
}

pub fn repeated_enum_wire_test() {
  // Field 4 contains ZERO,ONE as packed and unpacked enum varints.
  let expected = [
    n.SampleBaseChildFirstStateZero,
    n.SampleBaseChildFirstStateOne,
  ]
  let assert Ok(packed) = n.decode_sample_base_child_first(<<34, 2, 0, 1>>)
  let assert True = packed.states == expected
  let assert Ok(unpacked) = n.decode_sample_base_child_first(<<32, 0, 32, 1>>)
  let assert True = unpacked.states == expected
  // Field 4 mixes ONE, packed ZERO/ONE, ZERO and an empty packed block.
  let assert Ok(mixed) =
    n.decode_sample_base_child_first(<<32, 1, 34, 2, 0, 1, 32, 0, 34, 0>>)
  let assert [
    n.SampleBaseChildFirstStateOne,
    n.SampleBaseChildFirstStateZero,
    n.SampleBaseChildFirstStateOne,
    n.SampleBaseChildFirstStateZero,
  ] = mixed.states
  let assert <<32, 1, 32, 0, 32, 1, 32, 0>> =
    n.encode_sample_base_child_first(mixed)
  // Field 4 has a truncated packed varint, then unknown enum 2 in each representation.
  let assert Error(_) = n.decode_sample_base_child_first(<<34, 1, 128>>)
  let assert Error(_) = n.decode_sample_base_child_first(<<34, 1, 2>>)
  let assert Error(_) = n.decode_sample_base_child_first(<<32, 2>>)
}

pub fn map_enum_wire_test() {
  // Field 5 maps string key "k" to owner-scoped enum ONE=1.
  let assert Ok(value) =
    n.decode_sample_base_child_first(<<42, 5, 10, 1, 107, 16, 1>>)
  let assert [#("k", n.SampleBaseChildFirstStateOne)] = value.flags
  let assert <<42, 5, 10, 1, 107, 16, 1>> =
    n.encode_sample_base_child_first(value)
}
