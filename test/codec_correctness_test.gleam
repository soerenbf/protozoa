//// Direct signed scalar and wire-boundary tests use independent canonical bytes.

import gleam/list
import protozoa/decode as d
import protozoa/encode as e

// Canonical protobuf vectors, independently checked with Python protobuf 6.33.5.
// Values are literals so regeneration never depends on Python or parent packages.
/// Verifies canonical signed integer encoding/decoding and supported unsigned limits.
pub fn signed_boundary_test() {
  // Field 1 is int32 -1/min/max; negatives use sign-extended ten-byte varints.
  list.each(
    [
      #(-1, <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>),
      #(-2_147_483_648, <<8, 128, 128, 128, 128, 248, 255, 255, 255, 255, 1>>),
      #(2_147_483_647, <<8, 255, 255, 255, 255, 7>>),
    ],
    fn(row) {
      let assert Ok(value) = d.run(row.1, d.int32(1))
      let assert True = value == row.0
      let assert True = e.int32_field(1, row.0) == row.1
    },
  )
  // Field 1 is int64 -1 and ±(2^53−1); JS applications must stay in this safe range.
  list.each(
    [
      #(-1, <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>),
      #(-9_007_199_254_740_991, <<
        8,
        129,
        128,
        128,
        128,
        128,
        128,
        128,
        240,
        255,
        1,
      >>),
      #(9_007_199_254_740_991, <<8, 255, 255, 255, 255, 255, 255, 255, 15>>),
    ],
    fn(row) {
      let assert Ok(value) = d.run(row.1, d.int64(1))
      let assert True = value == row.0
      let assert True = e.int64_field(1, row.0) == row.1
    },
  )
  // Field 1 is uint32 maximum, then uint64 JS-safe maximum (not signed readers).
  let assert <<8, 255, 255, 255, 255, 15>> = e.uint32_field(1, 4_294_967_295)
  let assert Ok(4_294_967_295) =
    d.run(<<8, 255, 255, 255, 255, 15>>, d.uint32(1))
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 15>> =
    e.uint64_field(1, 9_007_199_254_740_991)
  let assert Ok(9_007_199_254_740_991) =
    d.run(<<8, 255, 255, 255, 255, 255, 255, 255, 15>>, d.uint64(1))
}

/// Rejects truncated or overflowing varints and out-of-range field numbers.
pub fn malformed_wire_test() {
  // Reject, in order: truncated tag; field 1 truncated value; eleven-byte value;
  // overflowing tenth value byte; field zero; field number > 2^29−1;
  // eleven-byte tag; overflowing length varint for field 1.
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
      let assert Error([d.DecodeError(..), ..]) = d.run(data, d.success(Nil))
    },
  )
}

/// Skips valid unknown fields and accepts non-minimal varints without losing known values.
pub fn valid_unknown_test() {
  // Read field 1=7 after unknown varints numbered 2, reserved 19000 and maximum 2^29−1.
  let assert Ok(7) = d.run(<<16, 1, 8, 7>>, d.int32(1))
  let assert Ok(7) = d.run(<<192, 163, 9, 1, 8, 7>>, d.int32(1))
  let assert Ok(7) = d.run(<<248, 255, 255, 255, 15, 1, 8, 7>>, d.int32(1))
  // Field 1=7 with a valid non-minimal varint is accepted.
  let assert Ok(7) = d.run(<<8, 135, 0>>, d.int32(1))
}

/// Verifies zigzag encoding/decoding and the ten-byte size of negative signed varints.
pub fn signed_paths_test() {
  // Field 1 is sint32 min, -129, -1, 1, max: zigzag, not two's-complement varints.
  list.each(
    [
      #(-2_147_483_648, <<8, 255, 255, 255, 255, 15>>),
      #(-129, <<8, 129, 2>>),
      #(-1, <<8, 1>>),
      #(1, <<8, 2>>),
      #(2_147_483_647, <<8, 254, 255, 255, 255, 15>>),
    ],
    fn(row) {
      let assert Ok(value) = d.run(row.1, d.sint32(1))
      let assert True = value == row.0
      let assert True = e.sint32_field(1, row.0) == row.1
      let assert Ok(value) = d.run(row.1, d.sint64(1))
      let assert True = value == row.0
      let assert True = e.sint64_field(1, row.0) == row.1
    },
  )
  let assert 10 = e.varint_size(-1)
}

@target(erlang)
/// Verifies full-width int64 endpoints and uint64 maximum against canonical bytes.
pub fn wide_integer_test() {
  // Field 1 is int64 min/max or uint64 max; these full-width values are Erlang-only.
  let assert <<8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1>> =
    e.int64_field(1, -9_223_372_036_854_775_808)
  let assert Ok(-9_223_372_036_854_775_808) =
    d.run(<<8, 128, 128, 128, 128, 128, 128, 128, 128, 128, 1>>, d.int64(1))
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 127>> =
    e.int64_field(1, 9_223_372_036_854_775_807)
  let assert Ok(9_223_372_036_854_775_807) =
    d.run(<<8, 255, 255, 255, 255, 255, 255, 255, 255, 127>>, d.int64(1))
  let assert <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>> =
    e.uint64_field(1, 18_446_744_073_709_551_615)
  let assert Ok(18_446_744_073_709_551_615) =
    d.run(<<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>, d.uint64(1))
}

/// Decodes present signed values and applies defaults only when the field is absent.
pub fn signed_default_test() {
  // Field 1=-1 is present, so signed defaults must decode rather than replace it.
  let data = <<8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1>>
  let assert Ok(-1) = d.run(data, d.int32_with_default(1, 0))
  let assert Ok(-1) = d.run(data, d.int64_with_default(1, 0))
  // Missing field 1 uses default 7; an unknown field 2=-1 must not affect field 1=7.
  let assert Ok(7) = d.run(<<>>, d.int64_with_default(1, 7))
  let assert Ok(7) =
    d.run(
      <<16, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 8, 7>>,
      d.int32(1),
    )
}
