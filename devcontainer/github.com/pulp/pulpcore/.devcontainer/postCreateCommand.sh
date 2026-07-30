#!/usr/bin/env bash
# Compatibility shim for older container mounts that bind this path to /tmp.
# Prefer lifecycle hooks in devcontainer.json → /opt/pulp-dev/scripts/...
set -euo pipefail
exec bash "${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}/lifecycle/post-create.sh" "$@"

