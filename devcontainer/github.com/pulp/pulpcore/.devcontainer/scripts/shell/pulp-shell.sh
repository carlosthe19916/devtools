# Sourced from ~/.bashrc — interactive helpers for the pulpcore devcontainer.

export PYTHONSAFEPATH=1
export PULP_PATCH_DIR="${PULP_PATCH_DIR:-/opt/pulp-dev/patches}"
export PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
export PULP_POPULATE_ROOT="${PULP_POPULATE_ROOT:-/opt/pulp-dev/populate}"

_SHELL_DIR="${PULP_DEV_SCRIPTS}/shell"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/packages.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/services.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/db.sh"
# shellcheck source=/dev/null
source "${_SHELL_DIR}/tools.sh"
