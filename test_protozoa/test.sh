#!/usr/bin/env bash
# Generate -> format -> compare the complete recursive set -> test both targets.
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$here/.."
stage="$here/codegen/build/generated"
output="$here/runtime/src/generated"
if [[ $# -gt 1 || ( ${1:-} != "" && ${1:-} != --regenerate ) ]]; then
  printf 'Usage: bash %s [--regenerate]\n' "$0" >&2
  exit 2
fi
rm -rf -- "$stage"
mkdir -p "$stage"
trap 'rm -rf -- "$stage"' EXIT
# Runtime sources never enter the generator bootstrap compilation.
(cd "$here/codegen" && gleam run --target erlang --module integration_codegen)
gleam format "$stage"
if [[ ${1:-} == --regenerate ]]; then
  rm -rf -- "$output"
  mkdir -p "$output"
  cp -R "$stage/." "$output/"
fi
if ! diff -ru -- "$output" "$stage"; then
  printf 'Generated codecs are stale. Run: bash %s --regenerate\n' "$here/test.sh" >&2
  exit 1
fi
for target in erlang javascript; do
  gleam test --target "$target"
  (cd "$here/codegen" && gleam test --target "$target")
  (cd "$here/runtime" && gleam test --target "$target")
done
