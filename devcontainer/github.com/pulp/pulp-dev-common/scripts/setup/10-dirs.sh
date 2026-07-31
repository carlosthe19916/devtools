#!/usr/bin/env bash
set -euo pipefail

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp 2>/dev/null || true
sudo mkdir -p /etc/nginx/pulp
