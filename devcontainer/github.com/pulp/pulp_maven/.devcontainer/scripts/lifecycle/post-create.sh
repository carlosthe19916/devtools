#!/usr/bin/env bash
# First-boot orchestrator — runs setup steps in order.
set -euo pipefail

ROOT="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
for step in \
  10-dirs.sh \
  20-python-deps.sh \
  30-patches.sh \
  40-database.sh \
  50-smash.sh \
  60-shell.sh \
  70-claude.sh
do
  echo "==> setup/${step}"
  bash "${ROOT}/setup/${step}"
done
