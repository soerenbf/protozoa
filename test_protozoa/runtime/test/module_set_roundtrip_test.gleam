//// Cross-module codecs preserve imported values, scoped enums and recursive fields.

import generated/per_file/a/common as a
import generated/per_file/b/common as b
import generated/per_file/decode as token
import generated/per_file/google/protobuf/struct as wellknown
import generated/per_file/map
import generated/per_file/repeated
import generated/per_file/root
import generated/per_file/shadow
import gleam/option.{None, Some}

/// Imported fields, scoped enums and recursive values retain their owning codecs.
pub fn cross_file_roundtrip_test() {
  // Independent bytes: field 2 other.number=42, field 4 state=READY,
  // field 5 optional_state=ZERO, field 6 packed states=[ZERO, READY],
  // and field 12 selects status=READY.
  let data = <<18, 2, 8, 42, 32, 1, 40, 0, 50, 2, 0, 1, 96, 1>>
  let assert Ok(wire) = root.decode_root(data)
  let assert Some(b.Item(42)) = wire.other
  let assert a.EnvelopeStateReady = wire.state
  let assert Some(a.EnvelopeStateZero) = wire.optional_state
  let assert [a.EnvelopeStateZero, a.EnvelopeStateReady] = wire.states
  let assert Some(root.RootPickStatus(a.EnvelopeStateReady)) = wire.pick
  let item = a.EnvelopeItem(text: "nested")
  let leaf =
    root.Root(
      item: None,
      other: None,
      token: None,
      state: a.EnvelopeStateZero,
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
    root.Root(
      item: Some(item),
      other: Some(b.Item(number: 42)),
      token: Some(token.Token(text: "runtime alias")),
      state: a.EnvelopeStateReady,
      optional_state: Some(a.EnvelopeStateZero),
      states: [a.EnvelopeStateZero, a.EnvelopeStateReady],
      items: [item],
      items_by_name: [#("item", item)],
      states_by_name: [#("ready", a.EnvelopeStateReady)],
      values: [#("ordinary", a.Value(text: "not a well-known value"))],
      next: Some(leaf),
      pick: Some(root.RootPickChosen(item)),
    )
  let assert Ok(decoded) = root.decode_root(root.encode_root(value))
  let assert True = decoded == value
  let value =
    root.Root(..value, pick: Some(root.RootPickStatus(a.EnvelopeStateReady)))
  let assert Ok(decoded) = root.decode_root(root.encode_root(value))
  let assert True = decoded == value
  let assert Ok(decoded) = root.decode_root(root.encode_root(leaf))
  let assert True = decoded == leaf
}

/// Absolute identities must not be reinterpreted relative to package p.
pub fn absolute_shadow_roundtrip_test() {
  let value = shadow.Root(x: Some(shadow.X(text: "absolute")))
  let assert Ok(decoded) = shadow.decode_root(shadow.encode_root(value))
  let assert True = decoded == value
  let nested = shadow.PX(number: 42)
  let assert Ok(decoded) = shadow.decode_px(shadow.encode_px(nested))
  let assert True = decoded == nested
}

/// Bundled Struct values stay distinct from ordinary imported Value messages.
pub fn bundled_struct_roundtrip_test() {
  let value =
    wellknown.Struct(fields: [
      #(
        "text",
        wellknown.Value(kind: Some(wellknown.ValueKindStringValue("bundled"))),
      ),
    ])
  let assert Ok(decoded) =
    wellknown.decode_struct(wellknown.encode_struct(value))
  let assert True = decoded == value
}

/// Repeated-field temporaries must not capture the message argument.
pub fn repeated_values_fields_roundtrip_test() {
  let value = repeated.ValuesFields(values: ["first", "second"], label: "later")
  let assert Ok(decoded) =
    repeated.decode_values_fields(repeated.encode_values_fields(value))
  let assert True = decoded == value
}

/// Map-field temporaries must not capture the message argument.
pub fn map_values_fields_roundtrip_test() {
  let value = map.ValuesFields(values: [#("key", "value")], label: "later")
  let assert Ok(decoded) =
    map.decode_values_fields(map.encode_values_fields(value))
  let assert True = decoded == value
}
