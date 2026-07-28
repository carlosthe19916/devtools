#!/usr/bin/env bash
# Host-side prep before the container starts (runs outside the container).
set -euo pipefail

echo "devcontainerID ${1:-}"

mkdir -p "${HOME}/.config/gcloud"
mkdir -p "${HOME}/.ssh"
[ -f "${HOME}/.gitconfig" ] || touch "${HOME}/.gitconfig"
