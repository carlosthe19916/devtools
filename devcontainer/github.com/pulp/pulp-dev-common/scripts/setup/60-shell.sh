#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
SHELL_SRC="source ${PULP_DEV_SCRIPTS}/shell/pulp-shell.sh"
MARKER="${PULP_SHELL_MARKER:-# pulp-devcontainer helpers}"

# Drop any previous helper block / old pulp-shell path, then append the current one.
if [ -f ~/.bashrc ]; then
  sed -i \
    -e "/^${MARKER}$/d" \
    -e "\|source ${PULP_DEV_SCRIPTS}/pulp-shell.sh|d" \
    -e "\|source ${PULP_DEV_SCRIPTS}/shell/pulp-shell.sh|d" \
    ~/.bashrc
fi
{
  echo ""
  echo "$MARKER"
  echo "$SHELL_SRC"
} >> ~/.bashrc
