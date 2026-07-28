#!/usr/bin/env bash
# Content entrypoint aligned with pulp-docs init-pulpcore-content.
set -euo pipefail

cd /home/vscode

reload_args=()
if [ "${PULP_GUNICORN_RELOAD:-false}" = "true" ]; then
  reload_args+=(--reload)
fi

access_logformat='%a %t "%r" %s %b "%{Referer}i" "%{User-Agent}i" cache:"%{X-PULP-CACHE}o" artifact_size:"%{X-PULP-ARTIFACT-SIZE}o" rh_org_id:"%{X-RH-ORG-ID}o"'

exec pulpcore-content \
  --bind 127.0.0.1:24816 \
  --timeout "${PULP_GUNICORN_TIMEOUT:-90}" \
  --workers "${PULP_CONTENT_WORKERS:-2}" \
  --access-logfile - \
  --access-logformat "$access_logformat" \
  "${reload_args[@]}"
