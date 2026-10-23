# Oneof code-generation regression

This separate package compiles generated output without the parent package's
BEAM-only snapshot test helper. It uses the local fork runtime, not a Hex release;
this is not a real-schema or Hex 2.0.3 compatibility check. Gleam 1.19.2,
Erlang/OTP and Node.js are required. Retain the manifest: nibble needs stdlib <1.

From the fork root:

```sh
(cd fixtures/oneof && gleam run -m generate &&
  wc -c src/dozen.gleam src/score.gleam src/many.gleam &&
  gleam format src test && gleam test --target erlang &&
  gleam test --target javascript && gleam format --check src test) &&
  gleam test
```

`generate.main()` reads the six schemas and overwrites the corresponding modules
in `src`; failures assert rather than continue with stale output. Generated files
are checked in and only formatted, never hand-repaired. The parent growth test
independently generates 12, 20 and 56 equivalent scalar alternatives, checks size
bounds before advancing to larger cases, and compares incremental bytes per
alternative (20% tolerance). This detects exponential and quadratic growth.

All three generated scalar-oneof modules compile on both targets, and tests reach
the last alternative of each (including 56). The parent growth regression checks
bounded linear growth, not a frozen byte count.

## Wire-order selection and errors

The historical shared-fallback implementation preserved declaration-priority and
suppressed malformed payload errors. This was incorrect for valid protobuf wire
orders and has been intentionally replaced. Generated alternatives now call the
runtime's ordered `decode.oneof`: last recognized wire occurrence wins, repeated
same-case message occurrences merge, and a different case resets that merge.
Wrong-wire tags are treated as unknown fields; recognized malformed nested
payloads return errors, including when followed by a different valid case.
Tests cover both distinct-case orders, duplicate scalar tags, same-case message
merge, absence, wrong-wire unknown fields and malformed framing/payload errors.
Generated helpers still emit each alternative once (linear source size).

The runtime context is opaque; its existing `from_field_dict` API is preserved.
Ordinary message record fields now have `Option(Message)` implicit presence.
Defaults apply only to missing fields, not malformed payloads. Unknown enum
numbers are errors, unknown fields are not retained, and exact JavaScript uint64
above `2^53 - 1` remains unsupported. These are representative codec tests, not a
full protobuf conformance claim.

## Naming and enum wire regression

`base.proto` and `naming.proto` cover imported ancestor packages, absolute refs,
`First.Inner`, `First.Middle.Inner`, deeper local `Item` shadowing, parent/sibling
refs, nested enums, optional/repeated/map/oneof wrappers, camelCase/acronym and
keyword labels, and reused oneof/enum variants. Dotted identities survive lookup;
only final Gleam names are flattened. `naming_test` is automatically discovered
by gleeunit, alongside the baseline oneof tests (15 tests total per target).
Enum constructors retain unprefixed names when unique. Collisions with normalized
variants, message constructors or oneof constructors qualify the enum variant
with its owning type. Qualification repeats until stable; remaining collisions
are generation errors. Types remain package-qualified.

Independent `protoc` 36.2 checks from this package:

```sh
printf 'states: ZERO states: ONE' | protoc -I schemas --encode=sample.base.child.First schemas/naming.proto | od -An -tx1
# 22 02 00 01 (packed repeated enum)
printf 'state: ZERO' | protoc -I schemas --encode=sample.base.child.First schemas/naming.proto | od -An -tx1
# 08 00; state: ONE gives 08 01; empty input gives no bytes
printf 'flags { key: "k" value: ONE }' | protoc -I schemas --encode=sample.base.child.First schemas/naming.proto | od -An -tx1
# 2a 05 0a 01 6b 10 01
printf '\040\001\042\002\000\001\040\000\042\000' | protoc -I schemas --decode=sample.base.child.First schemas/naming.proto
# states: ONE, ZERO, ONE, ZERO in that order
```

Tests decode packed `22 02 00 01`, unpacked `20 00 20 01`, and mixed occurrences
including an empty packed segment, then re-encode preserving values. The map test
also verifies exact re-encoded bytes independently accepted by protoc. Truncated
packed varints and unknown enum numbers fail explicitly. Optional enums preserve
presence, including zero. Deep/wrapped reference tests assert distinct owner
values, not only self-roundtrips.

The repeated-enum enhancement is in `decode.repeated_int32`, which unpacks only
int32 occurrences with the existing varint reader, preserving occurrence/element
order. Generic repeated-field behavior and all encoding/wire sources are unchanged.
Generated repeated-enum helpers now require this repaired fork runtime, not Hex
2.0.3. No claim is made for all packed numeric types or full protobuf conformance.

`gleam run -m wire_export --target erlang` (or `--target javascript`) prints
hexadecimal encoded values for independent checking. It asserts on decode failure
and never connects to a node.
