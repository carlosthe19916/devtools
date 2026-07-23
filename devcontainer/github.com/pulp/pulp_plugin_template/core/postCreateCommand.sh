#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp

################################################################################
# Python dependencies
################################################################################

pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt test_requirements.txt doc_requirements.txt; do
    [ -f "$req" ] && pip install -r "$req"
done

pip install httpie pulp-cli packaging
npm install -g concurrently

################################################################################
# Apply patches to pulpcore
################################################################################

if [ -d /tmp/patches ]; then
    for p in /tmp/patches/*.patch; do
        [ -f "$p" ] || continue
        patch -p1 --forward --no-backup-if-mismatch -d /workspace < "$p" || true
    done
fi

################################################################################
# Database initialization
################################################################################

python3 -c "import redis; redis.from_url('$PULP_REDIS_URL').flushall(); print('Redis flushed')" 2>/dev/null || true
pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password

################################################################################
# Generate OpenAPI client bindings
################################################################################

bash /tmp/prepare-bindings.sh core

################################################################################
# pulp-smash configuration
################################################################################

sudo mkdir -p /etc/xdg/pulp_smash
sudo tee /etc/xdg/pulp_smash/settings.json > /dev/null << 'SMASH_CONFIG'
{
  "pulp": {
    "auth": ["admin", "password"],
    "selinux enabled": false,
    "version": "3"
  },
  "hosts": [
    {
      "hostname": "localhost",
      "roles": {
        "api": {
          "port": 24817,
          "scheme": "http",
          "service": "pulpcore-api"
        },
        "content": {
          "port": 24816,
          "scheme": "http",
          "service": "pulp_content_app"
        },
        "pulp resource manager": {},
        "pulp workers": {},
        "redis": {},
        "shell": {
          "transport": "local"
        }
      }
    }
  ]
}
SMASH_CONFIG

################################################################################
# Shell aliases
################################################################################

cat >> ~/.bashrc << 'PULP_FUNCTIONS'
pulp-migrate() { pulpcore-manager migrate --noinput; }
pulp-api() { pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -; }
pulp-content() { pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -; }
pulp-worker() { pulpcore-worker; }
pulp-services() {
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-worker"
}
pulp-bindings() {
  bash /tmp/prepare-bindings.sh --force "${@:?Usage: pulp-bindings <component> [component2 ...]}"
}
PULP_FUNCTIONS

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

if [ -d /tmp/claude-skills ]; then
    mkdir -p ~/.claude/skills
    cp -r /tmp/claude-skills/* ~/.claude/skills/
fi
