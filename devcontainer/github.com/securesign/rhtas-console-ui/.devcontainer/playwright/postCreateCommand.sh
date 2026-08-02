#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true

################################################################################
# Claude Code: MCP servers, marketplaces, and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin marketplace add patternfly/ai-helpers 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true
claude plugin install react@patternfly-ai-helpers --scope user 2>/dev/null || true
