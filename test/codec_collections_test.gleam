import codec_fixture/scalars
import gleam/bit_array
import gleam/dict
import gleam/list
import protozoa/decode

/// Literal interleaved tags preserve indexed order, scalar last-wins and unknowns.
/// No arguments; assertion failures indicate changed public decoder semantics.
pub fn repeated_order_test() {
  let data = <<8, 1, 16, 9, 8, 2, 16, 8, 10, 2, 3, 4, 8, 5>>
  let assert Ok([1, 2, 3, 4, 5]) = decode.run(data, decode.repeated_int32(1))
  let assert Ok(5) = decode.run(<<8, 1, 16, 9, 8, 5>>, decode.int32(1))
  let assert Ok([9, 8]) = decode.run(data, decode.repeated_int32(2))
  let assert Ok([9, 8]) =
    decode.run(
      data,
      decode.from_field_dict(fn(fields) {
        let assert Ok(fields) = dict.get(fields, 2)
        list.try_map(fields, decode.int32_field)
        |> fn(values) {
          case values {
            Ok(v) -> Ok(v)
            Error(e) -> Error([e])
          }
        }
      }),
    )
}

/// Large known and unknown equal-tag inputs exercise accumulation without timings.
/// No arguments; expected values come from literal wire occurrences.
pub fn large_repeated_test() {
  let expected = list.repeat([1, 2, 3], 4000) |> list.flatten
  let known = list.repeat(<<8, 1, 8, 2, 8, 3>>, 4000) |> bit_array.concat
  let unknown = list.repeat(<<16, 1, 16, 2, 16, 3>>, 4000) |> bit_array.concat
  let assert Ok(values) = decode.run(known, decode.repeated_int32(1))
  let assert True = values == expected
  let assert Ok(Nil) = decode.run(unknown, decode.success(Nil))
  let assert Error(expected_error) = decode.run(<<8, 128>>, decode.success(Nil))
  let assert Error(error) =
    decode.run(<<unknown:bits, 8, 128>>, decode.success(Nil))
  let assert True = error == expected_error
  let assert Ok([7]) =
    decode.run(<<unknown:bits, 8, 7>>, decode.repeated_int32(1))
}

/// Maps expose reverse final-occurrence order as well as last-key-wins values.
/// No arguments; generated decoding uses independently specified entry bytes.
pub fn map_order_test() {
  let assert [] = decode.map_entries([])
  let assert [#(1, 30), #(2, 20)] =
    decode.map_entries([#(1, 10), #(2, 20), #(1, 30)])
  let assert [#("a", 4), #("c", 3), #("b", 2)] =
    decode.map_entries([#("a", 1), #("b", 2), #("c", 3), #("a", 4)])
  let assert Ok(scalars.MapInt32([#(1, 30), #(2, 20)])) =
    scalars.decode_map_int32(<<
      10,
      4,
      8,
      1,
      16,
      10,
      10,
      4,
      8,
      2,
      16,
      20,
      10,
      4,
      8,
      1,
      16,
      30,
    >>)
}

/// Many distinct and duplicate map keys retain exact values and exposed order.
/// No arguments; no timing-sensitive assertions.
pub fn large_map_test() {
  let keys = list.repeat(Nil, 12_000) |> list.index_map(fn(_, i) { i + 1 })
  let first = list.map(keys, fn(k) { #(k, 1) })
  let last = list.map(keys, fn(k) { #(k, 2) })
  let assert result = decode.map_entries(list.append(first, last))
  let assert True = result == list.reverse(last)
}
