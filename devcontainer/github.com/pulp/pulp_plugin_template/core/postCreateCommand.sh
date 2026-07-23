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

pip install httpie pulp-cli

################################################################################
# Database initialization
################################################################################

pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password

################################################################################
# pulp-smash configuration
################################################################################

mkdir -p ~/.config/pulp_smash
cat > ~/.config/pulp_smash/settings.json << 'SMASH_CONFIG'
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
  local pids=()
  pulp-api 2>&1 | sed -u "s/^/$(printf '\033[32m')[api]$(printf '\033[0m') /" &
  pids+=($!)
  pulp-content 2>&1 | sed -u "s/^/$(printf '\033[34m')[content]$(printf '\033[0m') /" &
  pids+=($!)
  pulp-worker 2>&1 | sed -u "s/^/$(printf '\033[35m')[worker]$(printf '\033[0m') /" &
  pids+=($!)
  _pulp_cleanup() {
    for pid in "${pids[@]}"; do
      pkill -P "$pid" 2>/dev/null
      kill "$pid" 2>/dev/null
    done
    wait 2>/dev/null
    echo "Pulp services stopped."
  }
  trap '_pulp_cleanup; return 0' INT TERM
  wait
}
PULP_FUNCTIONS

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true
