#!/usr/bin/env bash
set -euo pipefail

DEVCONTAINER_DEV_SCRIPTS="${DEVCONTAINER_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
TREE="${DEVCONTAINER_PATCH_TREE:-/repositories/pulpcore}"
# Optional overlays onto pulpcore. Keep patches/ empty for upstream CI parity
# (do not ship RH/pulp-service patches that diverge from pulpcore unit tests).
bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/patches.sh" apply "${TREE}"
