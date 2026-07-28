#!/usr/bin/env bash
# Compare installed package pins to workspace pulp-service requirements.txt.
set -euo pipefail

REQ_FILE="${1:-/workspace/pulp_service/requirements.txt}"

if [ ! -f "$REQ_FILE" ]; then
  echo "ERROR: requirements file not found: ${REQ_FILE}" >&2
  exit 1
fi

echo "==> Checking installed versions against ${REQ_FILE}..."
installed="$(pip list --format=freeze 2>/dev/null)"

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
