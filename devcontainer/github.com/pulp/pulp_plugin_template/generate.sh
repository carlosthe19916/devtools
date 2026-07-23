#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="${SCRIPT_DIR}/shared"

if [ $# -lt 1 ]; then
    echo "Usage: $0 core | <plugin_name> [plugin_name2 ...]"
    echo ""
    echo "Examples:"
    echo "  $0 core          # Generate devcontainer for pulpcore"
    echo "  $0 maven         # Generate devcontainer for pulp_maven"
    echo "  $0 maven python  # Generate devcontainers for pulp_maven and pulp_python"
    exit 1
fi

if [ "$1" = "core" ]; then
    TEMPLATE_DIR="${SCRIPT_DIR}/core"
    TARGET_DIR="${SCRIPT_DIR}/../pulpcore/.devcontainer"

    echo "Generating pulpcore -> ${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"

    # Render templates
    for f in devcontainer.json docker-compose.yml; do
        sed -e "s/__NAME_UPPER__/PULPCORE/g" \
            -e "s/__NAME__/pulpcore/g" \
            "${TEMPLATE_DIR}/${f}" > "${TARGET_DIR}/${f}"
    done

    # Copy template-specific files
    cp "${TEMPLATE_DIR}/postCreateCommand.sh" "${TARGET_DIR}/postCreateCommand.sh"

    # Copy shared files
    for f in Dockerfile initializeCommand.sh settings.py prepare-bindings.sh nginx.conf postStartCommand.sh; do
        cp "${SHARED_DIR}/${f}" "${TARGET_DIR}/${f}"
    done

    # Copy skills
    if [ -d "${SHARED_DIR}/skills" ]; then
        rm -rf "${TARGET_DIR}/skills"
        cp -r "${SHARED_DIR}/skills" "${TARGET_DIR}/skills"
    fi

    # Copy patches
    if [ -d "${SHARED_DIR}/patches" ]; then
        rm -rf "${TARGET_DIR}/patches"
        cp -r "${SHARED_DIR}/patches" "${TARGET_DIR}/patches"
    fi

    echo "  Done: pulpcore"
else
    TEMPLATE_DIR="${SCRIPT_DIR}/plugin"

    for PLUGIN in "$@"; do
        PLUGIN_UPPER="$(echo "${PLUGIN}" | tr '[:lower:]' '[:upper:]')"
        TARGET_DIR="${SCRIPT_DIR}/../pulp_${PLUGIN}/.devcontainer"

        echo "Generating pulp_${PLUGIN} -> ${TARGET_DIR}"
        mkdir -p "${TARGET_DIR}"

        # Render templates
        for f in devcontainer.json docker-compose.yml; do
            sed -e "s/__PLUGIN_UPPER__/${PLUGIN_UPPER}/g" \
                -e "s/__PLUGIN__/${PLUGIN}/g" \
                "${TEMPLATE_DIR}/${f}" > "${TARGET_DIR}/${f}"
        done

        # Copy template-specific files
        cp "${TEMPLATE_DIR}/postCreateCommand.sh" "${TARGET_DIR}/postCreateCommand.sh"

        # Copy shared files
        for f in Dockerfile initializeCommand.sh settings.py prepare-bindings.sh nginx.conf postStartCommand.sh; do
            cp "${SHARED_DIR}/${f}" "${TARGET_DIR}/${f}"
        done

        # Copy skills
        if [ -d "${SHARED_DIR}/skills" ]; then
            rm -rf "${TARGET_DIR}/skills"
            cp -r "${SHARED_DIR}/skills" "${TARGET_DIR}/skills"
        fi

        # Copy patches
        if [ -d "${SHARED_DIR}/patches" ]; then
            rm -rf "${TARGET_DIR}/patches"
            cp -r "${SHARED_DIR}/patches" "${TARGET_DIR}/patches"
        fi

        echo "  Done: pulp_${PLUGIN}"
    done
fi
