#!/usr/bin/env bash
# API entrypoint — start from a neutral cwd so /workspace does not shadow packages.
set -euo pipefail

cd /home/vscode
exec pulpcore-api \
  --bind 127.0.0.1:24817 \
  --timeout "${DEVCONTAINER_GUNICORN_TIMEOUT:-90}" \
  --workers "${DEVCONTAINER_API_WORKERS:-2}" \
  --access-logfile -
