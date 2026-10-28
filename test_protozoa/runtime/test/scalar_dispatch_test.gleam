//// Observable generated dispatch covers every primitive across field shapes.
//// Canonical payloads distinguish signed, zigzag, unsigned and fixed readers.

import generated/combined/types as t
import gleam/bit_array as bits
import gleam/list
import gleam/option.{Some}

fn cases() {
  // Primitive payloads in schema field order: IEEE754 -1, signed -1, unsigned
  // 2^32−1, zigzag -1, fixed 2^32−1, signed fixed -1, true, "x", byte 255.
  [
    #(
      1,
      <<0, 0, 0, 0, 0, 0, 240, 191>>,
      t.TypesChoiceScalarsChoiceDoubleValue(-1.0),
    ),
    #(5, <<0, 0, 128, 191>>, t.TypesChoiceScalarsChoiceFloatValue(-1.0)),
    #(
      0,
      <<255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      t.TypesChoiceScalarsChoiceInt32Value(-1),
    ),
    #(
      0,
      <<255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      t.TypesChoiceScalarsChoiceInt64Value(-1),
    ),
    #(
      0,
      <<255, 255, 255, 255, 15>>,
      t.TypesChoiceScalarsChoiceUint32Value(4_294_967_295),
    ),
    #(
      0,
      <<255, 255, 255, 255, 15>>,
      t.TypesChoiceScalarsChoiceUint64Value(4_294_967_295),
    ),
    #(0, <<1>>, t.TypesChoiceScalarsChoiceSint32Value(-1)),
    #(0, <<1>>, t.TypesChoiceScalarsChoiceSint64Value(-1)),
    #(
      5,
      <<255, 255, 255, 255>>,
      t.TypesChoiceScalarsChoiceFixed32Value(4_294_967_295),
    ),
    #(
      1,
      <<255, 255, 255, 255, 0, 0, 0, 0>>,
      t.TypesChoiceScalarsChoiceFixed64Value(4_294_967_295),
    ),
    #(5, <<255, 255, 255, 255>>, t.TypesChoiceScalarsChoiceSfixed32Value(-1)),
    #(
      1,
      <<255, 255, 255, 255, 255, 255, 255, 255>>,
      t.TypesChoiceScalarsChoiceSfixed64Value(-1),
    ),
    #(0, <<1>>, t.TypesChoiceScalarsChoiceBoolValue(True)),
    #(2, <<1, 120>>, t.TypesChoiceScalarsChoiceStringValue("x")),
    #(2, <<1, 255>>, t.TypesChoiceScalarsChoiceBytesValue(<<255>>)),
  ]
}

fn wire() {
  cases()
  |> list.index_map(fn(row, index) {
    // Each field tag uses its schema number and primitive wire type.
    <<{ index * 8 + 8 + row.0 }, row.1:bits>>
  })
  |> bits.concat
}

/// Every primitive selects its generated singular and optional field helpers.
pub fn singular_and_optional_test() {
  let assert Ok(value) = t.decode_types_all_types(wire())
  // The bytes field carries arbitrary binary, not UTF-8 text.
  let expected =
    t.TypesAllTypes(
      -1.0,
      -1.0,
      -1,
      -1,
      4_294_967_295,
      4_294_967_295,
      -1,
      -1,
      4_294_967_295,
      4_294_967_295,
      -1,
      -1,
      True,
      "x",
      <<255>>,
    )
  let assert True = value == expected
  let assert True = t.encode_types_all_types(value) == wire()
  let assert Ok(optional) = t.decode_types_optional_scalars(wire())
  let expected =
    t.TypesOptionalScalars(
      Some(-1.0),
      Some(-1.0),
      Some(-1),
      Some(-1),
      Some(4_294_967_295),
      Some(4_294_967_295),
      Some(-1),
      Some(-1),
      Some(4_294_967_295),
      Some(4_294_967_295),
      Some(-1),
      Some(-1),
      Some(True),
      Some("x"),
      Some(<<255>>),
    )
  let assert True = optional == expected
  let assert True = t.encode_types_optional_scalars(optional) == wire()
  // Absent primitives produce actual generated defaults, including empty bytes.
  let assert Ok(defaults) = t.decode_types_all_types(<<>>)
  let expected =
    t.TypesAllTypes(0.0, 0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, False, "", <<>>)
  let assert True = defaults == expected
}

/// Every primitive selects its repeated reader, including packed numeric fields.
pub fn repeated_decode_test() {
  // The same scalar occurrences decode as singleton repeated fields.
  let assert Ok(value) = t.decode_types_repeated_scalars(wire())
  let expected =
    t.TypesRepeatedScalars(
      [-1.0],
      [-1.0],
      [-1],
      [-1],
      [4_294_967_295],
      [4_294_967_295],
      [-1],
      [-1],
      [4_294_967_295],
      [4_294_967_295],
      [-1],
      [-1],
      [True],
      ["x"],
      [<<255>>],
    )
  let assert True = value == expected
  let packed =
    cases()
    |> list.index_map(fn(row, index) {
      case row.0 {
        // Strings and bytes are already length-delimited, not numeric packed blocks.
        2 -> <<{ index * 8 + 10 }, row.1:bits>>
        _ -> <<{ index * 8 + 10 }, bits.byte_size(row.1), row.1:bits>>
      }
    })
    |> bits.concat
  let assert Ok(value) = t.decode_types_repeated_scalars(packed)
  let assert True = value == expected
  // Repeated numeric encoder fallbacks are deliberately not asserted.
}

/// Every primitive oneof alternative selects its generated codec.
pub fn oneof_dispatch_test() {
  cases()
  |> list.index_map(fn(row, index) {
    // Select each primitive alternative with its independent canonical payload.
    let bytes = <<{ index * 8 + 8 + row.0 }, row.1:bits>>
    let expected = t.TypesChoiceScalars(Some(row.2))
    let assert Ok(value) = t.decode_types_choice_scalars(bytes)
    let assert True = value == expected
    let assert True = t.encode_types_choice_scalars(value) == bytes
  })
  Nil
}

/// Every primitive map value selects its reader, writer and default helper.
pub fn map_value_dispatch_test() {
  let bytes =
    cases()
    |> list.index_map(fn(row, index) {
      // Map entries encode empty string key 1, then primitive value 2.
      let entry = <<10, 0, { 16 + row.0 }, row.1:bits>>
      <<{ index * 8 + 10 }, bits.byte_size(entry), entry:bits>>
    })
    |> bits.concat
  let assert Ok(value) = t.decode_types_map_scalars(bytes)
  let expected =
    t.TypesMapScalars(
      [#("", -1.0)],
      [#("", -1.0)],
      [#("", -1)],
      [#("", -1)],
      [#("", 4_294_967_295)],
      [#("", 4_294_967_295)],
      [#("", -1)],
      [#("", -1)],
      [#("", 4_294_967_295)],
      [#("", 4_294_967_295)],
      [#("", -1)],
      [#("", -1)],
      [#("", True)],
      [#("", "x")],
      [#("", <<255>>)],
    )
  let assert True = value == expected
  let assert True = t.encode_types_map_scalars(value) == bytes
  // Empty map entries exercise every generated primitive's default reader.
  let empty_entries =
    cases()
    |> list.index_map(fn(_, index) { <<{ index * 8 + 10 }, 0>> })
    |> bits.concat
  let assert Ok(defaults) = t.decode_types_map_scalars(empty_entries)
  let expected =
    t.TypesMapScalars(
      [#("", 0.0)],
      [#("", 0.0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", 0)],
      [#("", False)],
      [#("", "")],
      [#("", <<>>)],
    )
  let assert True = defaults == expected
}

/// Every legal map key family selects its key reader, writer and default.
pub fn map_key_dispatch_test() {
  // Canonical key payloads reuse primitive vectors, ordered by MapKeys fields.
  let rows = cases()
  let rows = list.drop(rows, 2) |> list.take(10)
  // Bool true and string "x" complete the legal map key families.
  let rows = list.append(rows, list.drop(cases(), 12) |> list.take(2))
  let bytes =
    rows
    |> list.index_map(fn(row, index) {
      // Each entry has primitive key 1 and int32 value 2=7.
      let entry = <<{ 8 + row.0 }, row.1:bits, 16, 7>>
      <<{ index * 8 + 10 }, bits.byte_size(entry), entry:bits>>
    })
    |> bits.concat
  let assert Ok(value) = t.decode_types_map_keys(bytes)
  let expected =
    t.TypesMapKeys(
      [#(-1, 7)],
      [#(-1, 7)],
      [#(4_294_967_295, 7)],
      [#(4_294_967_295, 7)],
      [#(-1, 7)],
      [#(-1, 7)],
      [#(4_294_967_295, 7)],
      [#(4_294_967_295, 7)],
      [#(-1, 7)],
      [#(-1, 7)],
      [#(True, 7)],
      [#("x", 7)],
    )
  let assert True = value == expected
  let assert True = t.encode_types_map_keys(value) == bytes
  // Omitted keys exercise all legal key-family defaults rather than value readers.
  let defaults_wire =
    rows
    |> list.index_map(fn(_, index) { <<{ index * 8 + 10 }, 0>> })
    |> bits.concat
  let assert Ok(value) = t.decode_types_map_keys(defaults_wire)
  let expected =
    t.TypesMapKeys(
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(0, 0)],
      [#(False, 0)],
      [#("", 0)],
    )
  let assert True = value == expected
}
