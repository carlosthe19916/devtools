#!/bin/bash
set -euo pipefail

echo "devcontainerID ${1:-}"

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

################################################################################
# Wait for Pulp API (docker.io/pulp/pulp sibling service)
################################################################################

echo "==> Waiting for Pulp at http://pulp/api/pulp/api/v3/status/"
ATTEMPTS=0
MAX_ATTEMPTS=120
until curl -sf "http://pulp/api/pulp/api/v3/status/" >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "${ATTEMPTS}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: Pulp did not become ready within $((MAX_ATTEMPTS * 5))s" >&2
    echo "Check the pulp service logs (docker.io/pulp/pulp)." >&2
    exit 1
  fi
  sleep 5
done
echo "==> Pulp is ready"

################################################################################
# Verify admin credentials (set via PULP_DEFAULT_ADMIN_PASSWORD on pulp service)
# Fall back to docker/podman exec when the socket/CLI is available.
################################################################################

if curl -sf -u admin:password "http://pulp/api/pulp/api/v3/groups/?limit=0" >/dev/null 2>&1; then
  echo "==> Admin credentials OK (admin / password)"
else
  echo "==> Admin login failed; attempting reset-admin-password via container runtime"
  RESET_OK=0
  if command -v docker >/dev/null 2>&1 && docker exec pulp-ui-2-backend \
       pulpcore-manager reset-admin-password --password password; then
    RESET_OK=1
  elif command -v podman >/dev/null 2>&1 && podman exec pulp-ui-2-backend \
       pulpcore-manager reset-admin-password --password password; then
    RESET_OK=1
  fi
  if [ "${RESET_OK}" -ne 1 ]; then
    echo "WARNING: Could not set admin password from this container." >&2
    echo "From the host, run:" >&2
    echo "  docker/podman exec -it pulp-ui-2-backend pulpcore-manager reset-admin-password --password password" >&2
  fi
fi

################################################################################
# Optional pulp-cli (README / smoke tool)
################################################################################

echo "==> Installing pulp-cli"
pip install --user "pulp-cli[pygments]" >/dev/null
export PATH="${HOME}/.local/bin:${PATH}"
if [ ! -f "${HOME}/.config/pulp/cli.toml" ] && [ ! -f "${HOME}/.config/pulp/settings.toml" ]; then
  pulp config create --username admin --base-url http://pulp --api-root /api/pulp/ --password password || true
fi

echo "==> pulp-ui-2 postCreate complete"
echo "    Then:  npm ci && npm run start:dev"
echo "    From host browser:  UI http://localhost:3000/  API http://localhost:8089/"
echo "    From this container: API ${PULP_API_URL:-http://pulp}/  (compose service name, not localhost)"
echo "    Login: admin / password"
