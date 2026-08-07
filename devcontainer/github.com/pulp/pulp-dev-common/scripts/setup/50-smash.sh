#!/usr/bin/env bash
set -euo pipefail

DEVCONTAINER_DEV_CONFIG="${DEVCONTAINER_DEV_CONFIG:-/opt/pulp-dev/config}"

sudo mkdir -p /etc/xdg/pulp_smash
sudo cp "${DEVCONTAINER_DEV_CONFIG}/smash.json" /etc/xdg/pulp_smash/settings.json
