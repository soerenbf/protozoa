//// Focused combined-codec guarantees on the original integration model.

import generated/combined/app as a
import generated/combined/nested as n
import generated/combined/types as t
import gleam/option.{None, Some}

/// Optional zero, empty messages and recursive messages retain presence.
pub fn presence_test() {
  let assert Ok(absent) = t.decode_types_optional_types(<<>>)
  let assert None = absent.maybe_number
  let assert None = absent.next
  // Fields 2 and 4 explicitly select zero; field 3 is a present empty child.
  let bytes = <<16, 0, 26, 0, 32, 0>>
  let assert Ok(value) = t.decode_types_optional_types(bytes)
  let assert Some(0) = value.maybe_number
  let assert Some(t.TypesOptionalTypesStateZero) = value.state
  let assert Some(child) = value.next
  let assert True = child == absent
  let assert True = t.encode_types_optional_types(value) == bytes
}

/// Repeated scalar/message/enum fields accept packed and unpacked wire in order.
pub fn repeated_test() {
  // Field 2 mixes unpacked 1 and packed 2,3; field 4 is an empty message;
  // field 5 mixes unpacked READY and packed ZERO,READY.
  let bytes = <<16, 1, 18, 2, 2, 3, 34, 0, 40, 1, 42, 2, 0, 1>>
  let assert Ok(value) = t.decode_types_repeated_types(bytes)
  let assert [1, 2, 3] = value.numbers
  let assert [t.TypesOptionalTypes(None, None, None, None, None)] =
    value.messages
  let assert [
    t.TypesOptionalTypesStateReady,
    t.TypesOptionalTypesStateZero,
    t.TypesOptionalTypesStateReady,
  ] = value.states
  let assert Ok(roundtrip) =
    t.decode_types_repeated_types(t.encode_types_repeated_types(value))
  let assert True = value == roundtrip
  // Unknown enum value 2 must fail in packed and unpacked occurrences.
  let assert Error(_) = t.decode_types_repeated_types(<<42, 1, 2>>)
  let assert Error(_) = t.decode_types_repeated_types(<<40, 2>>)
}

/// Maps retain baseline scalar keys/values plus message and enum value identity.
pub fn maps_test() {
  // Empty field 5 entry defaults its zigzag key and fixed-width value to zero.
  let assert Ok(defaults) = t.decode_types_map_types(<<42, 0>>)
  let assert [#(0, 0)] = defaults.numeric_defaults
  // Empty field 1 entry defaults both strings; field 2 maps 7 to "x";
  // field 3 maps "m" to a present empty message; field 4 maps "e" to READY.
  let bytes = <<
    10,
    0,
    18,
    5,
    8,
    7,
    18,
    1,
    120,
    26,
    5,
    10,
    1,
    109,
    18,
    0,
    34,
    5,
    10,
    1,
    101,
    16,
    1,
  >>
  let assert Ok(value) = t.decode_types_map_types(bytes)
  let assert [#("", "")] = value.string_map
  let assert [#(7, "x")] = value.int_map
  let assert [#("m", t.TypesOptionalTypes(None, None, None, None, None))] =
    value.messages
  let assert [#("e", t.TypesOptionalTypesStateReady)] = value.states
  let assert Ok(roundtrip) =
    t.decode_types_map_types(t.encode_types_map_types(value))
  let assert True = value == roundtrip
}

/// Oneofs keep selected zero, last alternative, message merge/reset and errors.
pub fn oneof_test() {
  // Field 5 explicitly selects zero rather than absence.
  let assert Ok(zero) = t.decode_types_optional_types(<<40, 0>>)
  let assert Some(t.TypesOptionalTypesChoiceNumber(0)) = zero.choice
  let assert <<40, 0>> = t.encode_types_optional_types(zero)
  // Field 5 selects 2^32+7, distinguishing the int64 reader from an int32 reader.
  let bytes = <<40, 135, 128, 128, 128, 16>>
  let assert Ok(wide) = t.decode_types_optional_types(bytes)
  let assert Some(t.TypesOptionalTypesChoiceNumber(4_294_967_303)) = wide.choice
  let assert True = t.encode_types_optional_types(wide) == bytes
  // Field 6 contains maybe_string="x", then empty field 6 merges that message.
  let assert Ok(merged) =
    t.decode_types_optional_types(<<50, 3, 10, 1, 120, 50, 0>>)
  let assert Some(t.TypesOptionalTypesChoiceMessage(child)) = merged.choice
  let assert Some("x") = child.maybe_string
  // Intervening scalar field 5 resets the later empty message alternative.
  let assert Ok(reset) =
    t.decode_types_optional_types(<<50, 3, 10, 1, 120, 40, 7, 50, 0>>)
  let assert Some(t.TypesOptionalTypesChoiceMessage(t.TypesOptionalTypes(
    None,
    None,
    None,
    None,
    None,
  ))) = reset.choice
  // A final scalar wins; multi-byte field 56 selects false with presence.
  let assert Ok(last) = t.decode_types_optional_types(<<50, 0, 40, 7>>)
  let assert Some(t.TypesOptionalTypesChoiceNumber(7)) = last.choice
  let assert Ok(flag) = t.decode_types_optional_types(<<192, 3, 0>>)
  let assert Some(t.TypesOptionalTypesChoiceFlag(False)) = flag.choice
  let assert <<192, 3, 0>> = t.encode_types_optional_types(flag)
  // A wrong wire type is ignored; a truncated selected message is an error.
  let assert Ok(ignored) = t.decode_types_optional_types(<<48, 1>>)
  let assert None = ignored.choice
  let assert Error(_) = t.decode_types_optional_types(<<50, 1, 10>>)
}

/// Signed enum varints retain negative identity and explicit enum-zero selection.
pub fn enum_test() {
  // Field 4 is NEGATIVE=-1 using the canonical ten-byte signed varint.
  let bytes = <<32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  let assert Ok(value) = t.decode_types_optional_types(bytes)
  let assert Some(t.TypesOptionalTypesStateNegative) = value.state
  let assert True = t.encode_types_optional_types(value) == bytes
  // Field 7 selects enum ZERO in the oneof; zero remains on the wire.
  let assert Ok(value) = t.decode_types_optional_types(<<56, 0>>)
  let assert Some(t.TypesOptionalTypesChoiceSelectedState(
    t.TypesOptionalTypesStateZero,
  )) = value.choice
  let assert <<56, 0>> = t.encode_types_optional_types(value)
}

/// Baseline nested references resolve lexical, qualified, absolute and shadow names.
pub fn nested_test() {
  // Deep fields 1,2 use Outer.Inner strings; field 3 uses Container.Inner int32.
  let bytes = <<10, 3, 10, 1, 120, 18, 3, 10, 1, 121, 26, 2, 8, 7>>
  let assert Ok(value) = n.decode_nested_outer_inner_deep(bytes)
  let assert Some(n.NestedOuterInner("x")) = value.lexical
  let assert Some(n.NestedOuterInner("y")) = value.absolute
  let assert Some(n.NestedContainerInner(7)) = value.shadow
  let assert True = n.encode_nested_outer_inner_deep(value) == bytes
  // Original Container field 1 still resolves the qualified Outer.Inner.
  let assert Ok(container) = n.decode_nested_container(<<10, 3, 10, 1, 120>>)
  let assert Some(n.NestedOuterInner("x")) = container.nested_inner
  // Outer field 3 explicitly selects an enum whose short name collides with a message.
  let assert Ok(outer) = n.decode_nested_outer(<<24, 0>>)
  let assert Some(n.NestedOuterCollisionNestedContainer) = outer.collision
  let assert <<24, 0>> = n.encode_nested_outer(outer)
  let assert Ok(n.NestedOuterCollisionNestedOuterInner) =
    n.decode_nested_outer_collision_value(1)
}

/// Cross-file basename collisions and ordinary/WKT Value keep distinct codecs.
pub fn imports_test() {
  // App fields 3..7: string Item, numeric Item, runtime-named Token,
  // ordinary Value.text="v", and WKT Value.string_value="w".
  let bytes = <<
    26,
    3,
    10,
    1,
    120,
    34,
    2,
    8,
    7,
    42,
    3,
    10,
    1,
    116,
    50,
    3,
    10,
    1,
    118,
    58,
    3,
    26,
    1,
    119,
  >>
  let assert Ok(value) = a.decode_app_app_message(bytes)
  let assert Some(a.SameItem("x")) = value.first
  let assert Some(a.OtherItem(7)) = value.second
  let assert Some(a.RuntimeToken("t")) = value.token
  let assert Some(a.SameValue("v")) = value.ordinary
  let assert Some(a.Value(Some(a.ValueKindStringValue("w")))) = value.well_known
  let assert Ok(decoded) =
    a.decode_app_app_message(a.encode_app_app_message(value))
  let assert True = decoded == value
}

/// Repeated/map local temporaries cannot capture ValuesFields message arguments.
pub fn temporary_capture_test() {
  let repeated = t.TypesRepeatedTypesValuesFields(["first", "second"], "later")
  let assert Ok(decoded) =
    t.decode_types_repeated_types_values_fields(
      t.encode_types_repeated_types_values_fields(repeated),
    )
  let assert True = repeated == decoded
  let mapped = t.TypesMapTypesValuesFields([#("key", "value")], "later")
  let assert Ok(decoded) =
    t.decode_types_map_types_values_fields(
      t.encode_types_map_types_values_fields(mapped),
    )
  let assert True = mapped == decoded
}
