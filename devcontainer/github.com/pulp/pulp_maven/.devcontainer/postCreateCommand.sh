#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp

################################################################################
# Python dependencies
################################################################################

# Install local pulpcore checkout (if mounted) before the plugin so pip reuses it instead of pulling from PyPI
pulp-core-local() {
    if [ -f /repositories/pulpcore/pyproject.toml ] || [ -f /repositories/pulpcore/setup.cfg ]; then
        pip install -e /repositories/pulpcore
    else
        echo "No pulpcore checkout found at /repositories/pulpcore — using PyPI version"
    fi
}
pulp-core-pypi() { pip install pulpcore; }
pulp-core-local
pip install -e .
for req in lint_requirements.txt unittest_requirements.txt functest_requirements.txt test_requirements.txt doc_requirements.txt; do
    [ -f "$req" ] && pip install -r "$req"
done

# Install pulp-cli (base CLI) and its plugin-specific extension (e.g. pulp-cli-maven)
pip install httpie pulp-cli packaging
plugin_suffix=$(basename /workspace | sed 's/^pulp_//')
pip install "pulp-cli-${plugin_suffix}" 2>/dev/null || true
npm install -g concurrently

################################################################################
# OpenAPI Generator (binding generation tooling)
################################################################################

sudo curl -L -o /opt/openapi-generator-cli.jar \
    https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.10.0/openapi-generator-cli-7.10.0.jar

sudo mkdir -p /opt/templates
cd /opt/templates
sudo curl -sO https://raw.githubusercontent.com/pulp/pulp-openapi-generator/refs/heads/main/templates/python/v7.10.0/configuration.mustache
sudo curl -sO https://raw.githubusercontent.com/pulp/pulp-openapi-generator/refs/heads/main/templates/python/v7.10.0/partial_api_args.mustache
sudo curl -sO https://raw.githubusercontent.com/pulp/pulp-openapi-generator/refs/heads/main/templates/python/v7.10.0/requirements.mustache
sudo curl -sO https://raw.githubusercontent.com/pulp/pulp-openapi-generator/refs/heads/main/templates/python/v7.10.0/setup.mustache
sudo bash -c 'printf "from pkgutil import extend_path\n__path__ = extend_path(__path__, __name__)\n" > /opt/templates/__init__.py'
cd /workspace

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
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-worker"
}
pulp-bindings() {
  local component="${1:?Usage: pulp-bindings <component> [language]}"
  local language="${2:-python}"
  local api_root="${PULP_API_ROOT:-/api/pulp/}"
  local api_url="http://localhost:24817${api_root}api/v3/docs/api.json?bindings&component=${component}"
  local tmpspec
  tmpspec=$(mktemp)
  echo "Fetching API spec for ${component}..."
  curl -s "${api_url}" | jq . > "${tmpspec}"
  local pkg_name="pulp_${component}-client"
  echo "Generating ${language} bindings for ${component}..."
  java -jar /opt/openapi-generator-cli.jar generate \
    -i "${tmpspec}" \
    -g "${language}" \
    -o "${pkg_name}" \
    -t /opt/templates \
    --skip-validate-spec \
    --strict-spec=false \
    --additional-properties=packageName=pulpcore.client.${component},projectName="${pkg_name}",packageVersion=0.0.0.dev
  pip install -e "${pkg_name}"
  rm -f "${tmpspec}"
  echo "Installed ${pkg_name} (editable)"
}
PULP_FUNCTIONS

declare -f pulp-core-local >> ~/.bashrc
declare -f pulp-core-pypi >> ~/.bashrc

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

if [ -d /tmp/claude-skills ]; then
    mkdir -p ~/.claude/skills
    cp -r /tmp/claude-skills/* ~/.claude/skills/
fi
