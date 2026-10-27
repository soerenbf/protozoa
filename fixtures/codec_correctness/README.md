# Signed wire regression fixture

`test/codec_fixture/sign.gleam` was generated through the parent wrapper:

```fish
begin
    cd packages/protobuf_codegen
    gleam run -m protobuf_codegen_cli -- generate ../../vendor/protozoa/fixtures/codec_correctness ../../vendor/protozoa/test codec_fixture sign.proto
end
begin
    cd vendor/protozoa
    gleam format test/codec_fixture
    gleam test
    python3 tools/test_codec_targets.py
end
```

Expected test bytes come from protobuf's canonical two's-complement encoding
and the pinned Python protobuf 6.33.5 oracle, not local round trips. The fixture
checks declared -1 and int32-min enum constructors, including packed values.
Generated runtime logic is unmodified; documentation annotations describe its API.

The cross-target runner copies the actual fork tests and fixture into a disposable
project because the full fork suite uses Erlang-only Birdie snapshots. It propagates
failures and removes the project. No production dependency or public integer type
is changed.

JavaScript signed int64 application values are guaranteed only within
[-9007199254740991, 9007199254740991]. Canonical negative wire values still occupy
ten bytes; decoding preserves bounded wire chunks until signed interpretation.
Full int64 and uint64 boundaries run only on Erlang. Unsigned tests cover uint32
max and uint64 2^53−1 on both targets. Zigzag regression vectors cover int32
boundaries and small signed int64 values; this is not an arbitrary-precision
sint64/uint64 API or a full protobuf conformance suite.

## Generated scalar decoder matrix (tasks 3.1–3.3)

From the parent root, using the existing pinned Python development environment:

```fish
.venv-codegen/bin/python tools/protobuf_codec_baseline.py > /tmp/scalar-oracle.json
.venv-codegen/bin/python vendor/protozoa/fixtures/codec_correctness/generate_scalars.py /tmp/scalar-oracle.json
begin
    cd packages/protobuf_codegen
    gleam run -m protobuf_codegen_cli -- generate ../../vendor/protozoa/fixtures/codec_correctness ../../vendor/protozoa/test codec_fixture scalars.proto packed_only.proto
end
begin
    cd vendor/protozoa
    python3 fixtures/codec_correctness/generate_scalars.py --document
    gleam format test/codec_fixture test/codec_scalars_test.gleam
    gleam test
    python3 tools/test_codec_targets.py
end
```

The script creates the schemas and assertion source, not the codec source. The
real CLI emits both codec modules and `test/schema.tsv`. `--document` adds API
comments only, after each fresh generation; it never repairs emitted expressions.
`packed_only.proto` proves a repeated-only module needs no oneof-provided imports.
Tests themselves need no Python or wrapper to run. Fixture regeneration requires
the parent development tooling, not a new production dependency.

`codec_scalars_test` covers all 13 packable scalar types plus enums:

- Ordinary empty messages receive zero defaults. All optional fields remain
  absent on empty input and retain explicitly present zero.
- All numeric oneof alternatives (int32/64, uint32/64, sint32/64, fixed32/64,
  sfixed32/64, float/double), plus bool, retain absence and decode independent
  nonzero/selected-zero payloads. Generated encoding of selected zero matches
  independent bytes, rather than merely round-tripping.
- Packed/unpacked/mixed repeated occurrences preserve exact order, including
  bool true/false, distinct enum values, and empty packed segments. Signed
  alternatives additionally exercise negative literals in all three forms.
- Numeric map entries omit both members, only key, or only value. All ten legal
  numeric key families are paired with same-type values; float/double values
  use sint32 keys. Zigzag/fixed/sfixed omissions now receive zero.
- Truncated/overflowing packed varints, incomplete fixed-width payloads and
  incorrect unpacked wire types return structured errors.

Positive/zero payloads come from the parent Python protobuf 6.33.5 oracle JSON.
The fixture script independently parses additional canonical negative, map and
positive-enum-number vectors with that same pinned Python library. Expected
values never come from Protozoa encoding. All new scalar vectors are small exact
values on both targets; prior signed/parser tests retain wide Erlang-only cases.
This is not an arbitrary-precision JavaScript API or full protobuf conformance.

Production changes are limited to decoder generation and scalar runtime helpers.
Generated repeated zigzag/fixed encoders still emit existing unsupported fallback
warnings: encoder expansion is outside this decoder group. No tests assert local
repeated encode/decode round trips. Collection accumulation/performance and parent
SDK/generated bindings are deliberately unchanged.
