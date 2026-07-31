#!/usr/bin/env bash
# Install mounted nginx config (image COPY is stale across rebuilds) then start.
set -euo pipefail

PULP_DEV_CONFIG="${PULP_DEV_CONFIG:-/opt/pulp-dev/config}"
if [ -f "${PULP_DEV_CONFIG}/nginx.conf" ]; then
  sudo cp "${PULP_DEV_CONFIG}/nginx.conf" /etc/nginx/nginx.conf
fi
if [ -f "${PULP_DEV_CONFIG}/nginx-proxy-params.conf" ]; then
  sudo cp "${PULP_DEV_CONFIG}/nginx-proxy-params.conf" /etc/nginx/pulp-proxy-params.conf
fi

sudo nginx -t
sudo service nginx start || sudo nginx -s reload
