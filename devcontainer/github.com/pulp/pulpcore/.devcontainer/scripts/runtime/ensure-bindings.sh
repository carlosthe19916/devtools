#!/usr/bin/env bash
# Regenerate OpenAPI bindings only when missing, unless FORCE_BINDINGS=1.
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
BINDINGS_COMPONENTS=(core)

need_bindings=false
if [ "${FORCE_BINDINGS:-0}" = "1" ]; then
  need_bindings=true
elif [ ! -f /opt/bindings/core-client/setup.py ] || ! pip show pulpcore-client &>/dev/null; then
  need_bindings=true
fi

if [ "$need_bindings" = true ]; then
  echo "==> Generating OpenAPI bindings..."
  bash "${PULP_DEV_SCRIPTS}/runtime/prepare-bindings.sh" --force "${BINDINGS_COMPONENTS[@]}"
else
  echo "==> OpenAPI bindings already present (set FORCE_BINDINGS=1 to regenerate)"
fi
