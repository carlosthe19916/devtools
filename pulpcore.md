## What needs to be done:
Create / maintain devcontainer definitions for:
 - devcontainer/github.com/pulp/pulpcore
 - devcontainer/github.com/pulp/pulp_maven
 - devcontainer/github.com/pulp/pulp_python

## Rules
- Shared scripts live in `devcontainer/github.com/pulp/pulp-dev-common/` (bind-mounted; no symlinks)
- `pulp_maven` and `pulp_python` stay thin and nearly identical (plugin name / bindings / populate differ)
- New plugins: copy thin `.devcontainer/` from `pulp_maven`, set `PULP_PLUGIN` / populate

## Guideline
### Structure
Use `pulp-service` as the modular `/opt/pulp-dev` layout reference; scripts come from `pulp-dev-common`.

### Front door
- **pulpcore**: API smash/CLI on `:24817` (certguard); content via nginx `:80` + `/pulp/content/`
- **plugins / pulp-service**: clients via nginx `:80`

See `devcontainer/github.com/pulp/README.md` and `.claude/skills/pulp-plugin-devcontainer`.
