#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
# Editable pulpcore checkout is the workspace.
bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply /workspace
