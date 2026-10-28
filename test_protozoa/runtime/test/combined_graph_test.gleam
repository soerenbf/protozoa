//// The shared import graph also executes through a single combined module.

import generated/combined/shared as c
import gleam/option.{None, Some}

/// Imported nested messages and enums retain presence, maps, recursion and oneofs.
pub fn cross_file_roundtrip_test() {
  // Independent bytes: field 2 other.number=42, field 4 state=READY,
  // field 5 optional_state=ZERO, field 6 packed states=[ZERO, READY],
  // and field 12 selects status=READY.
  let data = <<18, 2, 8, 42, 32, 1, 40, 0, 50, 2, 0, 1, 96, 1>>
  let assert Ok(wire) = c.decode_same_root(data)
  let assert Some(c.OtherItem(42)) = wire.other
  let assert c.SameEnvelopeStateReady = wire.state
  let assert Some(c.SameEnvelopeStateZero) = wire.optional_state
  let assert [c.SameEnvelopeStateZero, c.SameEnvelopeStateReady] = wire.states
  let assert Some(c.SameRootPickStatus(c.SameEnvelopeStateReady)) = wire.pick
  let item = c.SameEnvelopeItem("nested")
  let leaf =
    c.SameRoot(
      item: None,
      other: None,
      token: None,
      state: c.SameEnvelopeStateZero,
      optional_state: None,
      states: [],
      items: [],
      items_by_name: [],
      states_by_name: [],
      values: [],
      next: None,
      pick: None,
    )
  let value =
    c.SameRoot(
      item: Some(item),
      other: Some(c.OtherItem(42)),
      token: Some(c.RuntimeToken("runtime alias")),
      state: c.SameEnvelopeStateReady,
      optional_state: Some(c.SameEnvelopeStateZero),
      states: [c.SameEnvelopeStateZero, c.SameEnvelopeStateReady],
      items: [item],
      items_by_name: [#("item", item)],
      states_by_name: [#("ready", c.SameEnvelopeStateReady)],
      next: Some(leaf),
      pick: Some(c.SameRootPickChosen(item)),
      values: [#("ordinary", c.SameValue("not a well-known value"))],
    )
  let assert Ok(decoded) = c.decode_same_root(c.encode_same_root(value))
  let assert True = decoded == value
  let value =
    c.SameRoot(
      ..value,
      pick: Some(c.SameRootPickStatus(c.SameEnvelopeStateReady)),
    )
  let assert Ok(decoded) = c.decode_same_root(c.encode_same_root(value))
  let assert True = decoded == value
  let assert Ok(decoded) = c.decode_same_root(c.encode_same_root(leaf))
  let assert True = decoded == leaf
}

/// Absolute package references stay distinct from relative shadowed names.
pub fn absolute_shadow_roundtrip_test() {
  let value = c.PRoot(Some(c.PX("absolute")))
  let assert Ok(decoded) = c.decode_proot(c.encode_proot(value))
  let assert True = decoded == value
  let nested = c.PPX(42)
  let assert Ok(decoded) = c.decode_ppx(c.encode_ppx(nested))
  let assert True = decoded == nested
}

/// Bundled Struct values stay distinct from ordinary imported Value messages.
pub fn bundled_struct_roundtrip_test() {
  let value =
    c.Struct([#("text", c.Value(Some(c.ValueKindStringValue("bundled"))))])
  let assert Ok(decoded) = c.decode_struct(c.encode_struct(value))
  let assert True = decoded == value
}

/// Collection temporaries do not capture later fields in combined encoders.
pub fn collection_fields_roundtrip_test() {
  let repeated = c.PRepeatedValuesFields(["first", "second"], "later")
  let assert Ok(decoded) =
    c.decode_prepeated_values_fields(c.encode_prepeated_values_fields(repeated))
  let assert True = decoded == repeated
  let map = c.PMapsValuesFields([#("key", "value")], "later")
  let assert Ok(decoded) =
    c.decode_pmaps_values_fields(c.encode_pmaps_values_fields(map))
  let assert True = decoded == map
}
