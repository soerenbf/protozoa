# Generated codec integration tests

`schemas/` contains protobuf fixtures. `codegen/` generates checked-in codecs in
`runtime/src/generated/{combined,per_file}/`. Never hand-edit generated files.
The shared import graph runs in both modes, including the bundled Struct schema.
The full primitive dispatch matrix runs only in combined mode.

Requires Gleam, Erlang/OTP and Node:

```sh
bash test_protozoa/test.sh
bash test_protozoa/test.sh --regenerate
```

The runner generates and formats a temporary output tree, checks the complete
recursive file set for freshness, then tests the fork and runtime on both targets.
`--regenerate` replaces checked-in outputs first. Generator bootstrap does not
compile runtime sources. No Git, Python or protoc is required.

Runtime tests check generator wiring, name resolution, presence, services and
signed enum mapping. Root tests own numeric boundaries, malformed wire inputs and
collection stress cases. JavaScript fixtures use safely representable integers;
repeated numeric encoding is not promised beyond supported generator paths.
