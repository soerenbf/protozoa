//// Standalone wrapper-reusable checks for the shared per-file schema collection.

import generated/per_file/a/common as a
import generated/per_file/app
import generated/per_file/b/common as b
import generated/per_file/base
import generated/per_file/decode as token
import generated/per_file/google/protobuf/struct as wkt
import generated/per_file/nested as n
import generated/per_file/types as t
import gleam/option.{None, Some}

/// Imported basename/runtime aliases and ordinary/WKT Value remain distinct.
pub fn imports_test() {
  // Original app fields 1,2 carry BaseMessage.id="b" and ACTIVE; fields 3..7
  // select the two Item types, Token, ordinary Value and WKT string Value.
  let bytes = <<
    10,
    3,
    10,
    1,
    98,
    16,
    1,
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
  let assert Ok(value) = app.decode_app_message(bytes)
  let assert Some(base.BaseMessage("b", base.BaseStatusUnknown, None)) =
    value.base
  let assert base.BaseStatusActive = value.status
  let assert Some(a.Item("x")) = value.first
  let assert Some(b.Item(7)) = value.second
  let assert Some(token.Token("t")) = value.token
  let assert Some(a.Value("v")) = value.ordinary
  let assert Some(wkt.Value(Some(wkt.ValueKindStringValue("w")))) =
    value.well_known
  let assert Ok(decoded) = app.decode_app_message(app.encode_app_message(value))
  let assert True = decoded == value
}

/// Packed enums, message maps, zero presence and recursive oneofs use local codecs.
pub fn fields_test() {
  // Repeated field 2 packs 1,2; field 4 is an empty message; field 5 packs ZERO,READY.
  let assert Ok(repeated) =
    t.decode_repeated_types(<<18, 2, 1, 2, 34, 0, 42, 2, 0, 1>>)
  let assert [1, 2] = repeated.numbers
  let assert [t.OptionalTypes(None, None, None, None, None)] = repeated.messages
  let assert [t.OptionalTypesStateZero, t.OptionalTypesStateReady] =
    repeated.states
  let assert Ok(decoded) =
    t.decode_repeated_types(t.encode_repeated_types(repeated))
  let assert True = decoded == repeated
  // Map fields 3,4 map the empty key to an empty message and READY respectively.
  let assert Ok(mapped) =
    t.decode_map_types(<<26, 4, 10, 0, 18, 0, 34, 4, 10, 0, 16, 1>>)
  let assert [#("", t.OptionalTypes(None, None, None, None, None))] =
    mapped.messages
  let assert [#("", t.OptionalTypesStateReady)] = mapped.states
  let assert Ok(decoded) = t.decode_map_types(t.encode_map_types(mapped))
  let assert True = decoded == mapped
  // Empty map field 5 entry defaults its zigzag key and fixed-width value to zero.
  let assert Ok(defaults) = t.decode_map_types(<<42, 0>>)
  let assert [#(0, 0)] = defaults.numeric_defaults
  // Optional field 2 is zero, field 3 is present, field 6 merges a child string.
  let bytes = <<16, 0, 26, 0, 50, 3, 10, 1, 120, 50, 0>>
  let assert Ok(value) = t.decode_optional_types(bytes)
  let assert Some(0) = value.maybe_number
  let assert Some(t.OptionalTypes(None, None, None, None, None)) = value.next
  let assert Some(t.OptionalTypesChoiceMessage(child)) = value.choice
  let assert Some("x") = child.maybe_string
  let assert Ok(decoded) =
    t.decode_optional_types(t.encode_optional_types(value))
  let assert True = decoded == value
  // Oneof field 5 selects 2^32+7, so generated dispatch must not truncate to int32.
  let assert Ok(wide) = t.decode_optional_types(<<40, 135, 128, 128, 128, 16>>)
  let assert Some(t.OptionalTypesChoiceNumber(4_294_967_303)) = wide.choice
  // Unknown enum in packed field 5 must fail rather than silently default.
  let assert Error(_) = t.decode_repeated_types(<<42, 1, 2>>)
}

/// Lexical/absolute/shadow references and field temporaries survive per-file naming.
pub fn names_test() {
  // Deep fields 1,2 select Outer.Inner strings; field 3 selects Container.Inner int32.
  let bytes = <<10, 3, 10, 1, 120, 18, 3, 10, 1, 121, 26, 2, 8, 7>>
  let assert Ok(value) = n.decode_outer_inner_deep(bytes)
  let assert Some(n.OuterInner("x")) = value.lexical
  let assert Some(n.OuterInner("y")) = value.absolute
  let assert Some(n.ContainerInner(7)) = value.shadow
  let assert True = n.encode_outer_inner_deep(value) == bytes
  // Outer field 3 selects a message-colliding enum name with explicit zero presence.
  let assert Ok(outer) = n.decode_outer(<<24, 0>>)
  let assert Some(n.OuterCollisionNestedContainer) = outer.collision
  let assert <<24, 0>> = n.encode_outer(outer)
  let repeated = t.RepeatedTypesValuesFields(["first", "second"], "later")
  let assert Ok(decoded) =
    t.decode_repeated_types_values_fields(t.encode_repeated_types_values_fields(
      repeated,
    ))
  let assert True = decoded == repeated
  let mapped = t.MapTypesValuesFields([#("key", "value")], "later")
  let assert Ok(decoded) =
    t.decode_map_types_values_fields(t.encode_map_types_values_fields(mapped))
  let assert True = decoded == mapped
}
