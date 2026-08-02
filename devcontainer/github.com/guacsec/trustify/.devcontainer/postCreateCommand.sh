#!/bin/bash

sudo chown -R "$(id -u):$(id -g)" ~/.claude 2>/dev/null || true

################################################################################
# Bash aliases
################################################################################

echo "alias start:dev='cargo run --bin trustd db migrate && cargo run --bin trustd api'" >> ~/.bashrc
echo "alias psql:postgres='env PGPASSWORD=trustify psql -U postgres -d postgres -h trustify-db -p 5432'" >> ~/.bashrc

################################################################################
# Claude Code: MCP servers and plugins
################################################################################

claude mcp add --transport http --scope user atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null || true
claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true
