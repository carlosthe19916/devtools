# Patch / bindings / version / populate helpers.

pulp-bindings() {
  bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/prepare-bindings.sh" --force \
    "${@:?Usage: pulp-bindings <component> [component2 ...]}"
}

pulp-patches() { bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/patches.sh" "$@"; }
pulp-check-versions() { bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/check-versions.sh" "$@"; }
pulp-populate() { bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/populate.sh" "$@"; }
