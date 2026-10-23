import gleam/option.{None, Some}
import naming as n

/// Unique enum names stay bare; message and oneof collisions are qualified.
pub fn enum_constructor_policy_test() {
  let assert 0 = n.encode_sample_base_child_unique_value(n.Distinct)
  let assert Ok(n.Other) = n.decode_sample_base_child_unique_value(1)
  let assert 0 =
    n.encode_sample_base_child_colliding_value(
      n.SampleBaseChildCollidingSampleBaseItem,
    )
  let assert Ok(n.SampleBaseChildCollidingSampleBaseChildFirstResponseV0) =
    n.decode_sample_base_child_colliding_value(1)
}

/// Optional enum presence uses independently specified protobuf varints.
pub fn optional_enum_test() {
  let assert Ok(absent) = n.decode_sample_base_child_first(<<>>)
  let assert None = absent.state
  let assert Ok(zero) = n.decode_sample_base_child_first(<<8, 0>>)
  let assert Some(n.SampleBaseChildFirstStateZero) = zero.state
  let assert <<8, 0>> = n.encode_sample_base_child_first(zero)
  let assert Ok(one) = n.decode_sample_base_child_first(<<8, 1>>)
  let assert Some(n.SampleBaseChildFirstStateOne) = one.state
  let assert <<8, 1>> = n.encode_sample_base_child_first(one)
  let assert Ok(second) = n.decode_sample_base_child_second(<<8, 1, 24, 1>>)
  let assert Some(n.SampleBaseChildSecondStateOne) = second.state
  let assert Some(n.SampleBaseChildSecondResponseType(
    n.SampleBaseChildSecondStateOne,
  )) = second.response
}

/// Each length-delimited payload identifies a distinct lexical owner.
pub fn deep_resolution_test() {
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

/// Repeated, map and oneof references share the resolved owner identities.
pub fn wrapped_resolution_test() {
  let bytes = <<
    18,
    2,
    8,
    7,
    26,
    7,
    10,
    1,
    107,
    18,
    2,
    8,
    8,
    34,
    2,
    0,
    1,
    42,
    5,
    10,
    1,
    107,
    16,
    1,
    50,
    2,
    8,
    9,
  >>
  let assert Ok(value) = n.decode_sample_base_child_first(bytes)
  let assert [n.SampleBaseChildFirstInner(7)] = value.children
  let assert [#("k", n.SampleBaseChildFirstInner(8))] = value.entries
  let assert [n.SampleBaseChildFirstStateZero, n.SampleBaseChildFirstStateOne] =
    value.states
  let assert [#("k", n.SampleBaseChildFirstStateOne)] = value.flags
  let assert Some(n.SampleBaseChildFirstResponseV0(n.SampleBaseChildFirstInner(
    9,
  ))) = value.response
  let assert Ok(encoded) =
    n.decode_sample_base_child_first(n.encode_sample_base_child_first(value))
  let assert True = encoded == value
}

/// protoc accepts packed, unpacked and mixed repeated enum occurrences.
pub fn repeated_enum_wire_test() {
  let expected = [
    n.SampleBaseChildFirstStateZero,
    n.SampleBaseChildFirstStateOne,
  ]
  let assert Ok(packed) = n.decode_sample_base_child_first(<<34, 2, 0, 1>>)
  let assert True = packed.states == expected
  let assert Ok(unpacked) = n.decode_sample_base_child_first(<<32, 0, 32, 1>>)
  let assert True = unpacked.states == expected
  let assert Ok(mixed) =
    n.decode_sample_base_child_first(<<32, 1, 34, 2, 0, 1, 32, 0, 34, 0>>)
  let assert [
    n.SampleBaseChildFirstStateOne,
    n.SampleBaseChildFirstStateZero,
    n.SampleBaseChildFirstStateOne,
    n.SampleBaseChildFirstStateZero,
  ] = mixed.states
  let assert Ok(roundtrip) =
    n.decode_sample_base_child_first(n.encode_sample_base_child_first(mixed))
  let assert True = roundtrip.states == mixed.states
  let assert <<32, 1, 32, 0, 32, 1, 32, 0>> =
    n.encode_sample_base_child_first(mixed)
}

/// Packed payload errors and unknown enum numbers stay explicit errors.
pub fn invalid_repeated_enum_test() {
  let assert Error(_) = n.decode_sample_base_child_first(<<34, 1, 128>>)
  let assert Error(_) = n.decode_sample_base_child_first(<<34, 1, 2>>)
  let assert Error(_) = n.decode_sample_base_child_first(<<32, 2>>)
}

/// Independent map-entry bytes wrap an owner-scoped enum value.
pub fn map_enum_wire_test() {
  let assert Ok(value) =
    n.decode_sample_base_child_first(<<42, 5, 10, 1, 107, 16, 1>>)
  let assert [#("k", n.SampleBaseChildFirstStateOne)] = value.flags
  let assert <<42, 5, 10, 1, 107, 16, 1>> =
    n.encode_sample_base_child_first(value)
}
