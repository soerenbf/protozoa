#!/usr/bin/env python3
"""Run a bounded, non-gating JavaScript collection scaling experiment.

No arguments. Requires Gleam and Node; compilation/assertion failures propagate.
Example (fork root): python3 tools/benchmark_collections.py
Times exclude compilation, input construction and five warmup iterations.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = '''import gleam/bit_array
import gleam/int
import gleam/io
import gleam/list
import protozoa/decode

@external(javascript, "./clock.mjs", "now")
fn now() -> Int

/// No arguments; prints bounded elapsed milliseconds; assertions fail on errors.
/// Example: `main()`. Intended only for the JavaScript experiment runner.
pub fn main() {
  list.each([3000, 6000, 12000], fn(n) {
    let known = list.repeat(<<8, 1>>, n) |> bit_array.concat
    let unknown = list.repeat(<<16, 1>>, n) |> bit_array.concat
    let entries = list.repeat(Nil, n) |> list.index_map(fn(_, i) { #(i + 1, 1) })
    let duplicates = list.append(entries, entries)
    measure(n, "known", fn() {
      let assert Ok(values) = decode.run(known, decode.repeated_int32(1))
      let assert True = list.length(values) == n
    })
    measure(n, "unknown", fn() {
      let assert Ok(Nil) = decode.run(unknown, decode.success(Nil))
    })
    measure(n, "distinct-map", fn() {
      let assert True = list.length(decode.map_entries(entries)) == n
    })
    measure(n, "duplicate-map-2n", fn() {
      let assert True = list.length(decode.map_entries(duplicates)) == n
    })
  })
}

fn measure(n: Int, label: String, run: fn() -> a) {
  list.each(list.repeat(Nil, 5), fn(_) { run() })
  let start = now()
  list.each(list.repeat(Nil, 20), fn(_) { run() })
  io.println(label <> " n=" <> int.to_string(n) <> " total_ms=" <> int.to_string(now() - start))
}
'''
with tempfile.TemporaryDirectory(prefix="collection-scaling-", dir=root / "build") as tmp:
    stage = Path(tmp)
    (stage / "src").mkdir()
    (stage / "gleam.toml").write_text(
        'name = "collection_scaling"\nversion = "0.1.0"\n[dependencies]\n'
        f'protozoa = {{ path = "{root}" }}\n'
        'gleam_stdlib = ">= 0.44.0 and < 2.0.0"\n'
    )
    shutil.copy(root / "manifest.toml", stage / "manifest.toml")
    (stage / "src/collection_scaling.gleam").write_text(source)
    (stage / "src/clock.mjs").write_text('export const now = () => Math.floor(performance.now());\n')
    subprocess.run(["gleam", "run", "--target", "javascript"], cwd=stage, check=True)
