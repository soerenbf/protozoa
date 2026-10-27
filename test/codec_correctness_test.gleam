import codec_fixture/sign
import gleam/list
import protozoa/decode
import protozoa/encode

/// Independent Python protobuf vectors; JS cases stay within ±(2^53−1).
/// No arguments or errors. Run with `gleam test` on either target.
pub fn signed_boundary_test() {
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int32_field(1, -1)
  let assert Ok(-1) =
    decode.run(
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int32(1),
    )
  let assert <<8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1>> =
    encode.int32_field(1, -2_147_483_648)
  let assert Ok(-2_147_483_648) =
    decode.run(
      <<8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1>>,
      decode.int32(1),
    )
  let assert <<8, 255, 255, 255, 255, 7>> = encode.int32_field(1, 2_147_483_647)
  let assert Ok(2_147_483_647) =
    decode.run(<<8, 255, 255, 255, 255, 7>>, decode.int32(1))
  let assert <<8, 0>> = encode.int32_field(1, 0)
  let assert Ok(0) = decode.run(<<8, 0>>, decode.int32(1))
  let assert <<8, 1>> = encode.int32_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 1>>, decode.int32(1))
  let assert <<8, 127>> = encode.int32_field(1, 127)
  let assert Ok(127) = decode.run(<<8, 127>>, decode.int32(1))
  let assert <<8, 128, 1>> = encode.int32_field(1, 128)
  let assert Ok(128) = decode.run(<<8, 128, 1>>, decode.int32(1))
  let assert <<8, 128, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int32_field(1, -128)
  let assert Ok(-128) =
    decode.run(
      <<8, 128, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int32(1),
    )
  let assert <<8, 255, 254, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int32_field(1, -129)
  let assert Ok(-129) =
    decode.run(
      <<8, 255, 254, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int32(1),
    )
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int64_field(1, -1)
  let assert Ok(-1) =
    decode.run(
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int64(1),
    )
  let assert <<8, 129, 128, 128, 128, 128, 128, 128, 240, 255, 1>> =
    encode.int64_field(1, -9_007_199_254_740_991)
  let assert Ok(-9_007_199_254_740_991) =
    decode.run(
      <<8, 129, 128, 128, 128, 128, 128, 128, 240, 255, 1>>,
      decode.int64(1),
    )
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 15>> =
    encode.int64_field(1, 9_007_199_254_740_991)
  let assert Ok(9_007_199_254_740_991) =
    decode.run(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>, decode.int64(1))
  let assert <<8, 0>> = encode.int64_field(1, 0)
  let assert Ok(0) = decode.run(<<8, 0>>, decode.int64(1))
  let assert <<8, 1>> = encode.int64_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 1>>, decode.int64(1))
  let assert <<8, 127>> = encode.int64_field(1, 127)
  let assert Ok(127) = decode.run(<<8, 127>>, decode.int64(1))
  let assert <<8, 128, 1>> = encode.int64_field(1, 128)
  let assert Ok(128) = decode.run(<<8, 128, 1>>, decode.int64(1))
  let assert <<8, 128, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int64_field(1, -128)
  let assert Ok(-128) =
    decode.run(
      <<8, 128, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int64(1),
    )
  let assert <<8, 255, 254, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.int64_field(1, -129)
  let assert Ok(-129) =
    decode.run(
      <<8, 255, 254, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.int64(1),
    )
  let assert <<8, 255, 255, 255, 255, 15>> =
    encode.uint32_field(1, 4_294_967_295)
  let assert Ok(4_294_967_295) =
    decode.run(<<8, 255, 255, 255, 255, 15>>, decode.uint32(1))
  let assert <<8, 0>> = encode.uint32_field(1, 0)
  let assert Ok(0) = decode.run(<<8, 0>>, decode.uint32(1))
  let assert <<8, 1>> = encode.uint32_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 1>>, decode.uint32(1))
  let assert <<8, 127>> = encode.uint32_field(1, 127)
  let assert Ok(127) = decode.run(<<8, 127>>, decode.uint32(1))
  let assert <<8, 128, 1>> = encode.uint32_field(1, 128)
  let assert Ok(128) = decode.run(<<8, 128, 1>>, decode.uint32(1))
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 15>> =
    encode.uint64_field(1, 9_007_199_254_740_991)
  let assert Ok(9_007_199_254_740_991) =
    decode.run(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>, decode.uint64(1))
  let assert <<8, 0>> = encode.uint64_field(1, 0)
  let assert Ok(0) = decode.run(<<8, 0>>, decode.uint64(1))
  let assert <<8, 1>> = encode.uint64_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 1>>, decode.uint64(1))
  let assert <<8, 127>> = encode.uint64_field(1, 127)
  let assert Ok(127) = decode.run(<<8, 127>>, decode.uint64(1))
  let assert <<8, 128, 1>> = encode.uint64_field(1, 128)
  let assert Ok(128) = decode.run(<<8, 128, 1>>, decode.uint64(1))
}

/// Checks structured parser errors at tag, value, length and packed boundaries.
/// No arguments or errors; run with `gleam test`.
pub fn malformed_wire_test() {
  list.each(
    [
      <<128>>,
      <<8, 128>>,
      <<8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 0>>,
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 2>>,
      <<0, 1>>,
      <<128, 128, 128, 128, 16, 1>>,
      <<128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 0>>,
      <<10, 255, 255, 255, 255, 255, 255, 255, 255, 255, 2>>,
    ],
    fn(data) {
      let assert Error([decode.DecodeError(..), ..]) =
        decode.run(data, decode.success(Nil))
    },
  )
  let assert Error(_) =
    decode.run(
      <<10, 10, 255, 255, 255, 255, 255, 255, 255, 255, 255, 2>>,
      decode.repeated_int32(1),
    )
}

/// Valid unknown tags, including schema-reserved numbers, remain skippable.
/// No arguments or errors; run with `gleam test`.
pub fn valid_unknown_test() {
  let assert Ok(7) = decode.run(<<16, 1, 8, 7>>, decode.int32(1))
  let assert Ok(7) = decode.run(<<192, 163, 9, 1, 8, 7>>, decode.int32(1))
  let assert Ok(7) =
    decode.run(<<248, 255, 255, 255, 15, 1, 8, 7>>, decode.int32(1))
  let assert Ok(7) = decode.run(<<8, 135, 0>>, decode.int32(1))
}

/// Signed repeated/enum numeric paths and unsigned/zigzag stay distinct.
/// No arguments or errors; run with `gleam test`.
pub fn signed_paths_test() {
  let assert <<8, 255, 255, 255, 255, 15>> =
    encode.sint32_field(1, -2_147_483_648)
  let assert Ok(-2_147_483_648) =
    decode.run(<<8, 255, 255, 255, 255, 15>>, decode.sint32(1))
  let assert <<8, 129, 2>> = encode.sint32_field(1, -129)
  let assert Ok(-129) = decode.run(<<8, 129, 2>>, decode.sint32(1))
  let assert <<8, 1>> = encode.sint32_field(1, -1)
  let assert Ok(-1) = decode.run(<<8, 1>>, decode.sint32(1))
  let assert <<8, 2>> = encode.sint32_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 2>>, decode.sint32(1))
  let assert <<8, 254, 255, 255, 255, 15>> =
    encode.sint32_field(1, 2_147_483_647)
  let assert Ok(2_147_483_647) =
    decode.run(<<8, 254, 255, 255, 255, 15>>, decode.sint32(1))
  let assert <<8, 255, 255, 255, 255, 15>> =
    encode.sint64_field(1, -2_147_483_648)
  let assert Ok(-2_147_483_648) =
    decode.run(<<8, 255, 255, 255, 255, 15>>, decode.sint64(1))
  let assert <<8, 129, 2>> = encode.sint64_field(1, -129)
  let assert Ok(-129) = decode.run(<<8, 129, 2>>, decode.sint64(1))
  let assert <<8, 1>> = encode.sint64_field(1, -1)
  let assert Ok(-1) = decode.run(<<8, 1>>, decode.sint64(1))
  let assert <<8, 2>> = encode.sint64_field(1, 1)
  let assert Ok(1) = decode.run(<<8, 2>>, decode.sint64(1))
  let assert <<8, 254, 255, 255, 255, 15>> =
    encode.sint64_field(1, 2_147_483_647)
  let assert Ok(2_147_483_647) =
    decode.run(<<8, 254, 255, 255, 255, 15>>, decode.sint64(1))
  let assert Ok([-1]) =
    decode.run(
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.repeated_int32(1),
    )
  let assert Ok([-1]) =
    decode.run(
      <<10, 10, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.repeated_int32(1),
    )
  let assert 10 = encode.varint_size(-1)
}

/// Declared negative enum constructors use signed scalar and packed paths.
/// No arguments or errors; run with `gleam test`.
pub fn negative_enum_test() {
  let assert Ok(sign.Enumeration(sign.Negative, [])) =
    sign.decode_enumeration(<<
      8,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      1,
    >>)
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    sign.encode_enumeration(sign.Enumeration(sign.Negative, []))
  let assert Ok(sign.Enumeration(sign.Minimum, [])) =
    sign.decode_enumeration(<<
      8,
      128,
      128,
      128,
      128,
      248,
      255,
      255,
      255,
      255,
      1,
    >>)
  let assert <<8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1>> =
    sign.encode_enumeration(sign.Enumeration(sign.Minimum, []))
  let assert Ok(sign.Enumeration(sign.Zero, [sign.Negative, sign.Minimum])) =
    sign.decode_enumeration(<<
      18,
      20,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      255,
      1,
      128,
      128,
      128,
      128,
      248,
      255,
      255,
      255,
      255,
      1,
    >>)
}

@target(erlang)
/// Full-width application integers are supported on Erlang only.
/// No arguments or errors; run with `gleam test --target erlang`.
pub fn wide_integer_test() {
  let assert <<8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1>> =
    encode.int64_field(1, -9_223_372_036_854_775_808)
  let assert Ok(-9_223_372_036_854_775_808) =
    decode.run(
      <<8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1>>,
      decode.int64(1),
    )
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 127>> =
    encode.int64_field(1, 9_223_372_036_854_775_807)
  let assert Ok(9_223_372_036_854_775_807) =
    decode.run(
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 127>>,
      decode.int64(1),
    )
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    encode.uint64_field(1, 18_446_744_073_709_551_615)
  let assert Ok(18_446_744_073_709_551_615) =
    decode.run(
      <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>,
      decode.uint64(1),
    )
}

/// Defaults interpret present signed fields and leave absent fields unchanged.
/// No arguments or errors; run with `gleam test`.
pub fn signed_default_test() {
  let data = <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  let assert Ok(-1) = decode.run(data, decode.int32_with_default(1, 0))
  let assert Ok(-1) = decode.run(data, decode.int64_with_default(1, 0))
  let assert Ok(7) = decode.run(<<>>, decode.int64_with_default(1, 7))
  let assert Ok(7) =
    decode.run(
      <<16, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 8, 7>>,
      decode.int32(1),
    )
}
