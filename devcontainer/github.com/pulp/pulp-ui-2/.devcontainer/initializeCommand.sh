#!/bin/bash
set -euo pipefail

echo "devcontainerID ${1:-}"

mkdir -p "${HOME}/.config/gcloud"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${SCRIPT_DIR}/pulp/settings/certs"
