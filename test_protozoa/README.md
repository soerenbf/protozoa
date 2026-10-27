# Generated codec integration tests

```text
schemas/           Real protobuf inputs, including split imports
codegen/           Standalone Gleam generator + deterministic ownership test
  -> ../../        Protozoa fork dependency
  -> ../schemas/   Input files (original resolver filenames preserved)
runtime/           Gleam package with handwritten test/ and src/generated/
  -> ../../        Protozoa fork dependency
```

`runtime/src/generated/**/*.gleam` belongs in version control; never hand-edit it.
The split closure includes the resolver's bundled Struct schema.

From any working directory (requires Gleam, OTP and Node):

```sh
bash path/to/protozoa/test_protozoa/test.sh
bash path/to/protozoa/test_protozoa/test.sh --regenerate
```

The script generates through the existing codegen API in `codegen/`, formats
`codegen/build/generated/`, compares complete recursive module sets, then runs
fork, generator and runtime tests on Erlang and JavaScript. `--regenerate`
replaces the checked-in runtime outputs before comparison. Missing or invalid
runtime sources cannot block generator bootstrap. No Git, Python or protoc is
needed. Schemas remain independent protoc inputs.

JavaScript cases stay within safe integer limits; full-width integer endpoints
run only on Erlang. Repeated numeric decoder coverage does not promise encoder
support beyond the existing supported paths. Snapshot tests remain in the fork's
Erlang suite; only those tests are excluded on JavaScript.
