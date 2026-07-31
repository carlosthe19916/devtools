#!/usr/bin/env bash
set -euo pipefail

PULP_DEV_CONFIG="${PULP_DEV_CONFIG:-/opt/pulp-dev/config}"

sudo mkdir -p /etc/xdg/pulp_smash
sudo cp "${PULP_DEV_CONFIG}/smash.json" /etc/xdg/pulp_smash/settings.json
