#!/usr/bin/env bash
# Content entrypoint — start from a neutral cwd so /workspace does not shadow packages.
set -euo pipefail

cd /home/vscode

reload_args=()
if [ "${PULP_GUNICORN_RELOAD:-false}" = "true" ]; then
  reload_args+=(--reload)
fi

access_logformat='%a %t "%r" %s %b "%{Referer}i" "%{User-Agent}i" cache:"%{X-PULP-CACHE}o" artifact_size:"%{X-PULP-ARTIFACT-SIZE}o"'

exec pulpcore-content \
  --bind 127.0.0.1:24816 \
  --timeout "${PULP_GUNICORN_TIMEOUT:-90}" \
  --workers "${PULP_CONTENT_WORKERS:-2}" \
  --access-logfile - \
  --access-logformat "$access_logformat" \
  "${reload_args[@]}"
