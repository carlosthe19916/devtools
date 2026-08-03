#!/bin/bash
set -euo pipefail

echo "devcontainerID ${1:-}"

mkdir -p "${HOME}/.config/gcloud"
