#!/usr/bin/env python3
"""Run fork wire tests on both targets without Erlang-only snapshot dependencies.

No arguments; requires Gleam/OTP/Node. Subprocess failures propagate nonzero.
Example: python3 tools/test_codec_targets.py (from the fork root).
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="codec-targets-", dir=root / "build") as tmp:
    stage = Path(tmp)
    (stage / "test").mkdir()
    (stage / "src").mkdir()
    (stage / "gleam.toml").write_text(
        'name = "codec_targets"\nversion = "0.1.0"\n[dependencies]\n'
        f'protozoa = {{ path = "{root}" }}\n'
        'gleam_stdlib = ">= 0.44.0 and < 2.0.0"\n'
        '[dev-dependencies]\ngleeunit = ">= 1.0.0 and < 2.0.0"\n'
    )
    shutil.copy(root / "manifest.toml", stage / "manifest.toml")
    for name in ("codec_collections_test.gleam", "codec_correctness_test.gleam", "codec_scalars_test.gleam", "protozoa_test.gleam"):
        shutil.copy(root / "test" / name, stage / "test" / ("codec_targets_test.gleam" if name == "protozoa_test.gleam" else name))
    shutil.copytree(root / "test/codec_fixture", stage / "test/codec_fixture")
    for target in ("erlang", "javascript"):
        subprocess.run(["gleam", "test", "--target", target], cwd=stage, check=True)
