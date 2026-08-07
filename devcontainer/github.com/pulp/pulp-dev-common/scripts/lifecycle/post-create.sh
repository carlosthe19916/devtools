#!/usr/bin/env bash
# First-boot orchestrator — runs setup steps in order.
set -euo pipefail

ROOT="${DEVCONTAINER_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
SETUP_30="${DEVCONTAINER_SETUP_30:-30-patches.sh}"

for step in \
  10-dirs.sh \
  20-python-deps.sh \
  "${SETUP_30}" \
  40-database.sh \
  50-smash.sh \
  60-shell.sh \
  70-claude.sh
do
  echo "==> setup/${step}"
  bash "${ROOT}/setup/${step}"
done
