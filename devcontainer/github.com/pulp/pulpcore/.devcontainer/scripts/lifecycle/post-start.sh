#!/usr/bin/env bash
# Runs on every container start.
set -euo pipefail

ROOT="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
bash "${ROOT}/runtime/start-nginx.sh"
bash "${ROOT}/runtime/ensure-bindings.sh"
