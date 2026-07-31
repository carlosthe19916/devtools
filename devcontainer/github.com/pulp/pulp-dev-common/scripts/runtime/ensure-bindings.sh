#!/usr/bin/env bash
# Regenerate OpenAPI bindings only when missing, unless FORCE_BINDINGS=1.
# Components from PULP_BINDINGS, or discover when PULP_DEV_KIND=core.
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
PULP_DEV_KIND="${PULP_DEV_KIND:-plugin}"

pkg_name_for() {
  local comp="$1"
  if [ "$comp" = "core" ]; then
    echo "pulpcore-client"
  else
    echo "pulp_${comp}-client"
  fi
}

discover_core_components() {
  local components=(core)
  if [ -d /workspace/pulpcore/app ]; then
    local plugin_app plugin_suffix
    for plugin_app in /workspace/pulp_*/app; do
      [ -d "$plugin_app" ] || continue
      plugin_suffix=$(basename "$(dirname "$plugin_app")" | sed 's/^pulp_//')
      components+=("$plugin_suffix")
    done
  fi
  local mod comp already c
  for pair in "pulp_maven:maven" "pulp_python:python"; do
    mod="${pair%%:*}"
    comp="${pair##*:}"
    if python3 -c "import ${mod}" 2>/dev/null; then
      already=false
      for c in "${components[@]}"; do
        [ "$c" = "$comp" ] && already=true && break
      done
      [ "$already" = false ] && components+=("$comp")
    fi
  done
  printf '%s\n' "${components[@]}"
}

if [ -n "${PULP_BINDINGS:-}" ]; then
  # shellcheck disable=SC2206
  BINDINGS_COMPONENTS=(${PULP_BINDINGS})
elif [ "${PULP_DEV_KIND}" = "core" ]; then
  mapfile -t BINDINGS_COMPONENTS < <(discover_core_components)
elif [ -n "${PULP_PLUGIN:-}" ]; then
  BINDINGS_COMPONENTS=(core "${PULP_PLUGIN}")
else
  echo "ERROR: set PULP_BINDINGS or PULP_PLUGIN (or PULP_DEV_KIND=core)" >&2
  exit 1
fi

need_bindings=false
if [ "${FORCE_BINDINGS:-0}" = "1" ]; then
  need_bindings=true
else
  local_comp=
  for local_comp in "${BINDINGS_COMPONENTS[@]}"; do
    pkg="$(pkg_name_for "$local_comp")"
    if [ ! -f "/opt/bindings/${local_comp}-client/setup.py" ] || ! pip show "${pkg}" &>/dev/null; then
      need_bindings=true
      break
    fi
  done
fi

if [ "$need_bindings" = true ]; then
  echo "==> Generating OpenAPI bindings: ${BINDINGS_COMPONENTS[*]}"
  bash "${PULP_DEV_SCRIPTS}/runtime/prepare-bindings.sh" --force "${BINDINGS_COMPONENTS[@]}"
else
  echo "==> OpenAPI bindings already present (set FORCE_BINDINGS=1 to regenerate)"
fi
