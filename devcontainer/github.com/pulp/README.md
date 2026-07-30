# Pulp

## Devcontainers

| Project | Location | Maintained how |
|---------|----------|----------------|
| **pulpcore** | [`pulpcore/.devcontainer/`](pulpcore/.devcontainer/) | Hand-maintained (tracked in git) |
| **pulp_maven** | [`pulp_maven/.devcontainer/`](pulp_maven/.devcontainer/) | Hand-maintained (tracked in git) |
| **pulp_python** | [`pulp_python/.devcontainer/`](pulp_python/.devcontainer/) | Hand-maintained (tracked in git) |
| **pulp-service** | [`pulp-service/.devcontainer/`](pulp-service/.devcontainer/) | Hand-maintained (tracked in git) |
| **new plugins** | `pulp_<name>/.devcontainer/` | Copy from `pulp_maven` / `pulp_python`, then customize |

All `pulp_<plugin>` trees must follow the modular `/opt/pulp-dev` layout (see `.claude/skills/pulp-plugin-devcontainer`). Reference implementations: **pulp_maven**, **pulp_python**. Structure follows **pulp-service** (`scripts/{lifecycle,setup,runtime,shell}`, mounts under `/opt/pulp-dev`).

Do **not** modify [`pulp_plugin_template/`](pulp_plugin_template/) for these hand-maintained containers, and do **not** run `generate.sh` into `pulpcore` / `pulp_maven` / `pulp_python` — that still emits the old flat `/tmp` layout and would overwrite the modular trees.

### Client front door

| Container | Clients (CLI / smash / populate) | Processes |
|-----------|----------------------------------|-----------|
| **pulpcore** | Direct `:24817` (API) / `:24816` (content) — intentional for certguard / client-cert functional tests | Same ports on localhost |
| **pulp_maven**, **pulp_python**, **pulp-service** | Nginx `:80` | API `:24817` / content `:24816` behind nginx |

## Environment variables

| Environment variable | default value           |
|----------------------|-------------------------|
| DEVTOOLS_CARLOSTHE19916_PATH | ~/git/devtools          |
| PULPCORE_PATH        | ~/git/pulp/pulpcore     |
| PULP_MAVEN_PATH      | ~/git/pulp/pulp_maven   |
| PULP_PYTHON_PATH     | ~/git/pulp/pulp_python  |
| PULP_SERVICE_PATH    | ~/git/pulp/pulp-service |

Make sure the environment variables are defined at `~/.bashrc` or equivalent:

```shell
if [ -z "$DEVTOOLS_CARLOSTHE19916_PATH" ]; then
  echo "export DEVTOOLS_CARLOSTHE19916_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$PULPCORE_PATH" ]; then
  echo "export PULPCORE_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$PULP_MAVEN_PATH" ]; then
  echo "export PULP_MAVEN_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$PULP_PYTHON_PATH" ]; then
  echo "export PULP_PYTHON_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

> `/cloned_repository_directory` should be replaced by the directory where you cloned the repository
