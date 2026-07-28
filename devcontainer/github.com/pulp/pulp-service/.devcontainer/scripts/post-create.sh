#!/usr/bin/env bash
# First-boot setup inside the pulp-service devcontainer.
set -euo pipefail

PULP_DEV_SCRIPTS="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"
PULP_DEV_CONFIG="${PULP_DEV_CONFIG:-/opt/pulp-dev/config}"

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true
# /etc/pulp/certs/*.pem may be bind-mounted :ro — ignore chown failures there.
sudo chown -R "$(id -u):$(id -g)" /var/lib/pulp /etc/pulp 2>/dev/null || true
sudo mkdir -p /etc/nginx/pulp /etc/pki/sigstore

################################################################################
# Dependencies
################################################################################

pip install -e /workspace/pulp_service
for req in /workspace/pulp_service/functest_requirements.txt \
           /workspace/pulp_service/lint_requirements.txt \
           /workspace/pulp_service/unittest_requirements.txt \
           /workspace/pulp_service/test_requirements.txt \
           /workspace/pulp_service/doc_requirements.txt; do
  [ -f "$req" ] && pip install -r "$req"
done

# Used by pulpcore/pulp_service functional fixtures even though not in requirements.txt
pip install pulp-file
pip install httpie pulp-cli packaging setproctitle pytest-asyncio
npm install -g concurrently

################################################################################
# Keys + RH patches (canonical: /workspace/images/assets/patches)
################################################################################

if [ -f /workspace/images/assets/keys/SIGSTORE-redhat-release3.pem ]; then
  sudo cp /workspace/images/assets/keys/SIGSTORE-redhat-release3.pem \
    /etc/pki/sigstore/SIGSTORE-redhat-release3
  sudo chmod 644 /etc/pki/sigstore/SIGSTORE-redhat-release3
fi

bash "${PULP_DEV_SCRIPTS}/patches.sh" apply

################################################################################
# Database
################################################################################

python3 -c "import redis; redis.from_url('$REDIS_URL').flushall(); print('Redis flushed')" 2>/dev/null || true
pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password
pulpcore-manager collectstatic --clear --noinput --link 2>/dev/null || true

################################################################################
# pulp-smash (nginx :80 front door)
################################################################################

sudo mkdir -p /etc/xdg/pulp_smash
sudo cp "${PULP_DEV_CONFIG}/smash.json" /etc/xdg/pulp_smash/settings.json

################################################################################
# Shell helpers
################################################################################

MARKER="# pulp-service devcontainer helpers"
if ! grep -qF "$MARKER" ~/.bashrc 2>/dev/null; then
  {
    echo ""
    echo "$MARKER"
    echo "source ${PULP_DEV_SCRIPTS}/pulp-shell.sh"
  } >> ~/.bashrc
fi

################################################################################
# Claude Code
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

if [ -d /tmp/claude-skills ]; then
  mkdir -p ~/.claude/skills
  cp -r /tmp/claude-skills/* ~/.claude/skills/
fi
