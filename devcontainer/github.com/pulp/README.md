# Pulp

## Devcontainers

| Project | Location | Maintained how |
|---------|----------|----------------|
| **pulp-dev-common** | [`pulp-dev-common/`](pulp-dev-common/) | Shared scripts/config (single source of truth) |
| **pulpcore** | [`pulpcore/.devcontainer/`](pulpcore/.devcontainer/) | Thin tree + overlays; mounts common scripts |
| **pulp_maven** | [`pulp_maven/.devcontainer/`](pulp_maven/.devcontainer/) | Thin plugin tree; mounts common scripts |
| **pulp_python** | [`pulp_python/.devcontainer/`](pulp_python/.devcontainer/) | Thin plugin tree; mounts common scripts |
| **pulp-service** | [`pulp-service/.devcontainer/`](pulp-service/.devcontainer/) | Thin + RH overlays; mounts common scripts |
| **pulp-ui** | [`pulp-ui/.devcontainer/`](pulp-ui/.devcontainer/) | UI workspace + sibling `docker.io/pulp/pulp` backend |
| **new plugins** | `pulp_<name>/.devcontainer/` | Copy thin skeleton from `pulp_maven`, set `PULP_PLUGIN` / populate |

Shared logic lives in [`pulp-dev-common/`](pulp-dev-common/) (scripts, config, populate, skills, Dockerfile, settings) and is bind-mounted under `/opt/pulp-dev/*` (real directories, **no symlinks**). Edit common first; keep per-project only compose, `pulp-dev.env`, patches, and overlays (e.g. pulpcore smash, RH nginx/scripts).

Do **not** symlink under `.devcontainer/` (Podman/`COPY`/`:Z` break).

See `.claude/skills/pulp-plugin-devcontainer` and [`pulp-dev-common/README.md`](pulp-dev-common/README.md).

### Client front door

| Container | Clients (CLI / smash / populate) | Processes |
|-----------|----------------------------------|-----------|
| **pulpcore** | API smash/CLI on `:24817` (certguard client certs); content via nginx `:80` + `/pulp/content/` (CI parity) | API `:24817` / content `:24816` |
| **pulp_maven**, **pulp_python**, **pulp-service** | Nginx `:80` | API `:24817` / content `:24816` behind nginx |
| **pulp-ui** | UI webpack-dev-server `:8002` (`API_PROXY=http://pulp:80`); host API `:8088` → pulp nginx `:80` | Sibling `docker.io/pulp/pulp` (api/content/workers + postgres/redis/nginx) |

## Environment variables

| Environment variable | default value           |
|----------------------|-------------------------|
| DEVTOOLS_CARLOSTHE19916_PATH | ~/git/devtools          |
| PULPCORE_PATH        | ~/git/pulp/pulpcore     |
| PULP_MAVEN_PATH      | ~/git/pulp/pulp_maven   |
| PULP_PYTHON_PATH     | ~/git/pulp/pulp_python  |
| PULP_SERVICE_PATH    | ~/git/pulp/pulp-service |
| PULP_UI_PATH         | ~/git/pulp/pulp-ui     |

`DEVTOOLS_CARLOSTHE19916_PATH` must resolve so compose can mount `pulp-dev-common/scripts` (backend stacks) and so pulp-ui `initializeCommand` can locate its scripts.

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

```shell
if [ -z "$PULP_UI_PATH" ]; then
  echo "export PULP_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

> `/cloned_repository_directory` should be replaced by the directory where you cloned the repository

### pulp-ui

Self-contained UI stack: Node workspace plus `docker.io/pulp/pulp` as the API backend.

1. Set `PULP_UI_PATH` (and `DEVTOOLS_CARLOSTHE19916_PATH` for `initializeCommand`).
2. Open [`pulp-ui/.devcontainer/`](pulp-ui/.devcontainer/) in the editor.
3. After create: `npm install && npm run start` → http://localhost:8002/ (proxies to Pulp via `API_PROXY`).
4. Login `admin` / `admin`. Host API also on http://localhost:8088/.

Admin password is set on first boot via `PULP_DEFAULT_ADMIN_PASSWORD`. If login fails (e.g. reused volumes), from the host:

```shell
docker/podman exec -it pulp-ui-backend pulpcore-manager reset-admin-password --password admin
```
