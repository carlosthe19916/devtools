#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
# Apply optional overlays from /opt/pulp-dev/patches onto the workspace.
# Keep that directory empty for upstream CI parity — do not ship RH/pulp-service
# patches here (e.g. the old 0044 heartbeat patch breaks unit tests).
bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply /workspace
