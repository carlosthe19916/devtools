#!/usr/bin/env bash
# Runs on every container start.
set -euo pipefail

ROOT="${DEVCONTAINER_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"

# shellcheck source=/dev/null
source "${ROOT}/runtime/uv-env.sh"
pulp_uv_env_ensure

bash "${ROOT}/runtime/start-nginx.sh"
bash "${ROOT}/runtime/ensure-bindings.sh"
