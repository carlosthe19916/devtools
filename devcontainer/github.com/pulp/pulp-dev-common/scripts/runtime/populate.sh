#!/usr/bin/env bash
# Upload sample packages (requires pulp-services).
set -euo pipefail

ROOT="${DEVCONTAINER_POPULATE_ROOT:-/opt/pulp-dev/populate}"
SCRIPT="${ROOT}/setup_pulp.py"

if [[ ! -f "${SCRIPT}" ]]; then
  echo "error: populate script not found at ${SCRIPT}" >&2
  echo "hint: ensure .devcontainer/populate is mounted at /opt/pulp-dev/populate" >&2
  exit 1
fi

exec python3 "${SCRIPT}" "$@"
