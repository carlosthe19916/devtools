#!/usr/bin/env bash
# Check installed package versions.
# - core/plugin: pulpcore pyproject.toml dependency ranges (DEVCONTAINER_PYPROJECT)
# - service: pinned requirements.txt (DEVCONTAINER_REQUIREMENTS)
set -euo pipefail

check_pyproject() {
  local PYPROJECT="$1"
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
}

check_requirements() {
  local REQ_FILE="$1"
  if [ ! -f "$REQ_FILE" ]; then
    echo "ERROR: requirements file not found: ${REQ_FILE}" >&2
    exit 1
  fi

  echo "==> Checking installed versions against ${REQ_FILE}..."
  local installed mismatches missing line pkg version pip_pkg pip_pkg_hyphen installed_version
  installed="$(uv pip list --format=freeze 2>/dev/null)"
  mismatches=0
  missing=0

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(echo "$line" | sed 's/#.*//' | xargs)"
    [ -z "$line" ] && continue

    if [[ "$line" =~ ^([a-zA-Z0-9_-]+)==([0-9].*)$ ]]; then
      pkg="${BASH_REMATCH[1]}"
      version="${BASH_REMATCH[2]}"
    else
      continue
    fi

    pip_pkg="${pkg//-/_}"
    pip_pkg_hyphen="${pkg//_/-}"
    installed_version="$(echo "$installed" | grep -iE "^(${pip_pkg}|${pip_pkg_hyphen})==" | head -1 | cut -d= -f3)"

    if [ -z "$installed_version" ]; then
      echo "  MISSING: ${pkg}==${version} (not installed)"
      missing=$((missing + 1))
    elif [ "$installed_version" != "$version" ]; then
      echo "  MISMATCH: ${pkg} installed=${installed_version} expected=${version}"
      mismatches=$((mismatches + 1))
    fi
  done < "$REQ_FILE"

  if [ "$mismatches" -eq 0 ] && [ "$missing" -eq 0 ]; then
    echo "==> All pinned versions match."
    exit 0
  fi

  echo "==> ${mismatches} version mismatch(es), ${missing} missing package(s)."
  echo "    Rebuild/recreate the devcontainer or reinstall from ${REQ_FILE}."
  exit 1
}

if [ -n "${1:-}" ]; then
  if [[ "$1" == *.txt ]]; then
    check_requirements "$1"
  else
    check_pyproject "$1"
  fi
elif [ -n "${DEVCONTAINER_REQUIREMENTS:-}" ]; then
  check_requirements "${DEVCONTAINER_REQUIREMENTS}"
elif [ "${DEVCONTAINER_DEV_KIND:-}" = "service" ]; then
  check_requirements "/workspace/pulp_service/requirements.txt"
elif [ -n "${DEVCONTAINER_PYPROJECT:-}" ]; then
  check_pyproject "${DEVCONTAINER_PYPROJECT}"
elif [ "${DEVCONTAINER_DEV_KIND:-}" = "core" ]; then
  check_pyproject "/workspace/pyproject.toml"
else
  check_pyproject "/repositories/pulpcore/pyproject.toml"
fi
