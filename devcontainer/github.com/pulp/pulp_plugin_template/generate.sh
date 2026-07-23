#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/.devcontainer"

TEMPLATES=(devcontainer.json docker-compose.yml)
SHARED=(Dockerfile initializeCommand.sh postCreateCommand.sh settings.py)

if [ $# -lt 1 ]; then
    echo "Usage: $0 <plugin_name> [plugin_name2 ...]"
    echo "Example: $0 maven python"
    exit 1
fi

for PLUGIN in "$@"; do
    PLUGIN_UPPER="$(echo "${PLUGIN}" | tr '[:lower:]' '[:upper:]')"
    TARGET_DIR="${SCRIPT_DIR}/../pulp_${PLUGIN}/.devcontainer"

    echo "Generating pulp_${PLUGIN} -> ${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"

    # Remove old symlinks if present
    for f in "${SHARED[@]}"; do
        if [ -L "${TARGET_DIR}/${f}" ]; then
            rm "${TARGET_DIR}/${f}"
        fi
    done

    # Render templates (sed replaces __PLUGIN__ and __PLUGIN_UPPER__)
    for f in "${TEMPLATES[@]}"; do
        sed -e "s/__PLUGIN_UPPER__/${PLUGIN_UPPER}/g" \
            -e "s/__PLUGIN__/${PLUGIN}/g" \
            "${SOURCE_DIR}/${f}" > "${TARGET_DIR}/${f}"
    done

    # Copy shared files
    for f in "${SHARED[@]}"; do
        cp "${SOURCE_DIR}/${f}" "${TARGET_DIR}/${f}"
    done

    echo "  Done: pulp_${PLUGIN}"
done
