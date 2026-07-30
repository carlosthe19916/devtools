#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
# Patches target the mounted pulpcore checkout.
bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" apply /repositories/pulpcore
