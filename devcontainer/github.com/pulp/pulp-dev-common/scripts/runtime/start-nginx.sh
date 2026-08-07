#!/usr/bin/env bash
# Optionally remount nginx config from /opt/pulp-dev/config, then start.
# Set DEVCONTAINER_NGINX_REMOUNT=0 for images that already bake the correct nginx.conf
# (pulp-service).
set -euo pipefail

DEVCONTAINER_DEV_CONFIG="${DEVCONTAINER_DEV_CONFIG:-/opt/pulp-dev/config}"
DEVCONTAINER_NGINX_REMOUNT="${DEVCONTAINER_NGINX_REMOUNT:-1}"

if [ "${DEVCONTAINER_NGINX_REMOUNT}" = "1" ]; then
  if [ -f "${DEVCONTAINER_DEV_CONFIG}/nginx.conf" ]; then
    sudo cp "${DEVCONTAINER_DEV_CONFIG}/nginx.conf" /etc/nginx/nginx.conf
  fi
  if [ -f "${DEVCONTAINER_DEV_CONFIG}/nginx-proxy-params.conf" ]; then
    sudo cp "${DEVCONTAINER_DEV_CONFIG}/nginx-proxy-params.conf" /etc/nginx/pulp-proxy-params.conf
  fi
  sudo nginx -t
fi

sudo service nginx start || sudo nginx -s reload
