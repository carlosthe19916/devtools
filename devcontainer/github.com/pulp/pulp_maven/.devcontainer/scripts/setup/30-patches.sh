#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
# Optional overlays onto mounted pulpcore. Keep patches/ empty for upstream CI
# parity (do not ship RH/pulp-service patches that diverge from pulpcore unit tests).
bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply /repositories/pulpcore
