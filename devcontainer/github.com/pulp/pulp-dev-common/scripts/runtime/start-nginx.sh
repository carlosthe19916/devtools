#!/usr/bin/env bash
# Optionally remount nginx config from /opt/pulp-dev/config, then start.
# Set PULP_NGINX_REMOUNT=0 for images that already bake the correct nginx.conf
# (pulp-service).
set -euo pipefail

PULP_DEV_CONFIG="${PULP_DEV_CONFIG:-/opt/pulp-dev/config}"
PULP_NGINX_REMOUNT="${PULP_NGINX_REMOUNT:-1}"

if [ "${PULP_NGINX_REMOUNT}" = "1" ]; then
  if [ -f "${PULP_DEV_CONFIG}/nginx.conf" ]; then
    sudo cp "${PULP_DEV_CONFIG}/nginx.conf" /etc/nginx/nginx.conf
  fi
  if [ -f "${PULP_DEV_CONFIG}/nginx-proxy-params.conf" ]; then
    sudo cp "${PULP_DEV_CONFIG}/nginx-proxy-params.conf" /etc/nginx/pulp-proxy-params.conf
  fi
  sudo nginx -t
fi

sudo service nginx start || sudo nginx -s reload
