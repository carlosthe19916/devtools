# Sourced from ~/.bashrc — interactive helpers for Pulp .devcontainer trees.

export PYTHONSAFEPATH=1
export DEVCONTAINER_PATCH_DIR="${DEVCONTAINER_PATCH_DIR:-/opt/pulp-dev/patches}"
export DEVCONTAINER_DEV_SCRIPTS="${DEVCONTAINER_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
export DEVCONTAINER_POPULATE_ROOT="${DEVCONTAINER_POPULATE_ROOT:-/opt/pulp-dev/populate}"

# shellcheck source=/dev/null
source "${DEVCONTAINER_DEV_SCRIPTS}/runtime/uv-env.sh"
pulp_uv_env_activate

_SHELL_DIR="${DEVCONTAINER_DEV_SCRIPTS}/shell"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/packages.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/services.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/db.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/tools.sh"
