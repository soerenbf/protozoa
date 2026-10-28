# Generated codec integration tests

The five original inline schemas from `main` are now files. Original packages,
messages, fields and numbers are preserved; additions exercise distinct branches.

| Schema | Purpose |
| --- | --- |
| `base.proto` | Original message/enum; explicit enum-zero presence |
| `app.proto` | Original base import; same-basename/runtime aliases and ordinary vs WKT Value |
| `service.proto` | Original request, response and combined-only service handler |
| `types.proto` | Original 15 singular scalars, repeated/optional/maps; focused message/enum collections, signed enum, recursion, mixed oneof and ValuesFields capture |
| `nested.proto` | Original Outer/Inner/Container; lexical, qualified, absolute and shadow references, constructor-colliding enum |
| `a/common.proto`, `b/common.proto` | Same basename and short message name, distinct packages |
| `decode.proto` | Runtime import basename collision |

Requires Gleam, Erlang/OTP and Node. From the fork root:

```sh
bash test_protozoa/test.sh
bash test_protozoa/test.sh --regenerate
```

`codegen/` reads one eight-file source collection. For each of `app`, `types`,
`service`, `nested`, it resolves once and passes the **same `files` and `registry`**
to `generate` and `generate_modules`. The app closure includes base, both common
files, decode and bundled `google/protobuf/struct.proto`. The other closures are
disjoint, so no per-file output is overwritten. Per-file service output contains
request/response codecs but no handler because that API does not generate services. Combined grouping remains app/base,
types, service and nested. Never hand-edit generated files.

The Bash runner regenerates/formats a staged tree, recursively compares complete
file sets, and executes fork and runtime tests on Erlang and JavaScript. Generator
bootstrap never compiles runtime output. No Git, Python or protoc is required.

`runtime/test/per_file_test.gleam` is standalone for downstream wrapper reuse:
generate entries `app.proto`, `types.proto`, `nested.proto` with prefix
`generated/per_file` and copy that test; no helper files are needed. Supply all
schema files above as sources (the bundled WKT import is resolver-provided).
Combined tests additionally check all 15 singular scalar wire dispatches and the
service handler. Independent wire assertions cover presence, packing, maps,
negative enum, oneof order/merge/reset/errors, references and import identities;
small composition checks cover both ValuesFields temporary-capture regressions.

Root tests own arithmetic bounds, generic malformed input and stress matrices.
We intentionally remove the duplicated 15-scalar-by-field-shape and legal-map-key
matrices, not the original AllTypes coverage. Repeated numeric encoding is tested
only on supported int32/bool/enum paths. Wrong-wire oneof alternatives are ignored
by the current runtime; malformed selected message payloads fail. The nested enum
has meaningful owner-local optional/oneof presence uses: this avoids the known
combined imported-enum helper omission without claiming general support or
changing production code. The former extensive naming matrix is reduced to focused constructor-collision,
owner-qualified enum and lexical/absolute/shadow cases; deep ancestor permutations
are no longer duplicated here. JavaScript fixtures use safe integers.
