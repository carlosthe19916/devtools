#!/usr/bin/env bash
# API entrypoint — start from a neutral cwd so /workspace does not shadow pulp_service.
set -euo pipefail

cd /home/vscode
exec pulpcore-api \
  --bind 127.0.0.1:24817 \
  --timeout "${PULP_GUNICORN_TIMEOUT:-90}" \
  --workers "${PULP_API_WORKERS:-2}" \
  --access-logfile -
