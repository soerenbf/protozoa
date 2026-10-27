//// Cross-module codecs preserve imported values, scoped enums and recursive fields.

import generated/split/a/common as a
import generated/split/b/common as b
import generated/split/decode as token
import generated/split/google/protobuf/struct as wellknown
import generated/split/map
import generated/split/repeated
import generated/split/root
import generated/split/shadow
import gleam/option.{None, Some}

/// Check imported fields, enum variants and recursive values without arguments.
/// Asserts codec success and equality. Example: `cross_file_roundtrip_test()`.
pub fn cross_file_roundtrip_test() {
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

/// The bundled Value map retains required-value decoding, not ordinary defaults.
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
