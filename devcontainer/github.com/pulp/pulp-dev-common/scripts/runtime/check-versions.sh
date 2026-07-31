#!/usr/bin/env bash
# Check installed package versions against pulpcore pyproject.toml dependency ranges.
set -euo pipefail

if [ -n "${1:-}" ]; then
  PYPROJECT="$1"
elif [ -n "${PULP_PYPROJECT:-}" ]; then
  PYPROJECT="${PULP_PYPROJECT}"
elif [ "${PULP_DEV_KIND:-}" = "core" ]; then
  PYPROJECT="/workspace/pyproject.toml"
else
  PYPROJECT="/repositories/pulpcore/pyproject.toml"
fi

if [ ! -f "$PYPROJECT" ]; then
  echo "ERROR: pyproject.toml not found: ${PYPROJECT}" >&2
  exit 1
fi

echo "==> Checking installed versions against ${PYPROJECT} dependencies..."
python3 - "$PYPROJECT" <<'PY'
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore

from importlib.metadata import PackageNotFoundError, version as pkg_version
from packaging.requirements import Requirement

path = Path(sys.argv[1])
data = tomllib.loads(path.read_text())
deps = data.get("project", {}).get("dependencies", [])

mismatches = 0
missing = 0

for raw in deps:
    req = Requirement(raw)
    name = req.name
    try:
        installed = pkg_version(name)
    except PackageNotFoundError:
        print(f"  MISSING: {raw}")
        missing += 1
        continue
    if req.specifier and installed not in req.specifier:
        print(f"  MISMATCH: {name} installed={installed} expected={req.specifier}")
        mismatches += 1

if mismatches == 0 and missing == 0:
    print("==> All declared dependencies satisfy their version ranges.")
    sys.exit(0)

print(f"==> {mismatches} version mismatch(es), {missing} missing package(s).")
sys.exit(1)
PY
