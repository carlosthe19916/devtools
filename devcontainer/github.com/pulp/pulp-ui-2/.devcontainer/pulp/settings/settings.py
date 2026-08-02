"""Pulp settings for pulp-ui-2 devcontainer against docker.io/pulp/pulp.

Paths match the OpenAPI client used by pulp-ui-2 (`API_ROOT=/api/pulp/` with domains).

Hostname notes
--------------
- Compose service DNS name for the backend is ``pulp`` (container_name
  ``pulp-ui-2-backend``). In-container clients (UI proxy, pulp-cli, curl
  from postCreate) must use ``http://pulp``, not localhost.
- ``CONTENT_ORIGIN`` and ``CSRF_TRUSTED_ORIGINS`` use localhost because they
  describe URLs as seen by the *browser on the host* via published ports
  (``8089`` → pulp nginx, ``3000`` → Vite). Browsers cannot resolve compose
  DNS names.
"""

SECRET_KEY = "devcontainer-secret-key-not-for-production"
# Browser / host port-forward URL for content (published as host 8089 → pulp:80).
CONTENT_ORIGIN = "http://localhost:8089"
CONTENT_PATH_PREFIX = "/api/pulp-content/"
API_ROOT = "/api/pulp/"
DOMAIN_ENABLED = True
TOKEN_AUTH_DISABLED = True
ANALYTICS = False
ALLOWED_IMPORT_PATHS = ["/tmp"]
ALLOWED_EXPORT_PATHS = ["/tmp"]
# Browser Origin when opening the Vite UI via the published host port.
CSRF_TRUSTED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]
