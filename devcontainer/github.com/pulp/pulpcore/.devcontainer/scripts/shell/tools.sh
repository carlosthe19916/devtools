# Patch / bindings helpers.

pulp-bindings() {
  bash "${PULP_DEV_SCRIPTS}/runtime/prepare-bindings.sh" --force \
    "${@:?Usage: pulp-bindings <component> [component2 ...]}"
}

pulp-patches() { bash "${PULP_DEV_SCRIPTS}/runtime/patches.sh" "$@"; }
