import gleam/option.{None, Some}
import split_fixture/a/common as a
import split_fixture/b/common as b
import split_fixture/decode as token
import split_fixture/google/protobuf/struct as wellknown
import split_fixture/map
import split_fixture/repeated
import split_fixture/root
import split_fixture/shadow

pub fn cross_file_roundtrip_test() {
  let item = a.EnvelopeItem(text: "nested")
  let leaf =
    root.Root(
      item: None,
      other: None,
      token: None,
      state: a.ZERO,
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
      state: a.READY,
      optional_state: Some(a.ZERO),
      states: [a.ZERO, a.READY],
      items: [item],
      items_by_name: [#("item", item)],
      states_by_name: [#("ready", a.READY)],
      values: [#("ordinary", a.Value(text: "not a well-known value"))],
      next: Some(leaf),
      pick: Some(root.RootPickChosen(item)),
    )
  let assert Ok(decoded) = root.decode_root(root.encode_root(value))
  let assert True = decoded == value
  let value = root.Root(..value, pick: Some(root.RootPickStatus(a.READY)))
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
