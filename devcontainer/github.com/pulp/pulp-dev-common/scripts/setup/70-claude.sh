#!/usr/bin/env bash
set -euo pipefail

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true

SKILLS_SRC="${DEVCONTAINER_DEV_SKILLS:-/opt/pulp-dev/skills}"
if [ -d "${SKILLS_SRC}" ]; then
  mkdir -p ~/.claude/skills
  cp -r "${SKILLS_SRC}"/* ~/.claude/skills/
fi
