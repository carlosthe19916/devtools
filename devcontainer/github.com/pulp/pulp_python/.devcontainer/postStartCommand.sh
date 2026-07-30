#!/usr/bin/env bash
# Compatibility shim for older container mounts that bind this path to /tmp.
set -euo pipefail
exec bash "${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}/lifecycle/post-start.sh" "$@"

