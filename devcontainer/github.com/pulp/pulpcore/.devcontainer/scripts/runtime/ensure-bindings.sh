#!/usr/bin/env bash
# Regenerate OpenAPI bindings only when missing, unless FORCE_BINDINGS=1.
# Mirrors pulp_plugin_template shared/postStartCommand.sh discovery for pulpcore.
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"

discover_components() {
  local components=(core)
  # pulpcore checkout as /workspace: include every in-tree pulp_* plugin (file, certguard, …)
  if [ -d /workspace/pulpcore/app ]; then
    local plugin_app plugin_suffix
    for plugin_app in /workspace/pulp_*/app; do
      [ -d "$plugin_app" ] || continue
      plugin_suffix=$(basename "$(dirname "$plugin_app")" | sed 's/^pulp_//')
      components+=("$plugin_suffix")
    done
  fi
  # Optional sibling plugins mounted under /repositories
  local mod comp
  for pair in "pulp_maven:maven" "pulp_python:python"; do
    mod="${pair%%:*}"
    comp="${pair##*:}"
    if python3 -c "import ${mod}" 2>/dev/null; then
      local already=false
      local c
      for c in "${components[@]}"; do
        [ "$c" = "$comp" ] && already=true && break
      done
      [ "$already" = false ] && components+=("$comp")
    fi
  done
  printf '%s\n' "${components[@]}"
}

mapfile -t BINDINGS_COMPONENTS < <(discover_components)

pkg_name_for() {
  local comp="$1"
  if [ "$comp" = "core" ]; then
    echo "pulpcore-client"
  else
    echo "pulp_${comp}-client"
  fi
}

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
