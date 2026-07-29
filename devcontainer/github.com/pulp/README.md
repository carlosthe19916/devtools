# Pulp

## Devcontainers

| Project | Location | Maintained how |
|---------|----------|----------------|
| **pulpcore** | [`pulpcore/.devcontainer/`](pulpcore/.devcontainer/) | Hand-maintained (tracked in git) |
| **pulp-service** | [`pulp-service/.devcontainer/`](pulp-service/.devcontainer/) | Hand-maintained (tracked in git) |
| **plugins** (maven, python, …) | `pulp_<name>/.devcontainer/` | Generated via [`pulp_plugin_template/generate.sh`](pulp_plugin_template/generate.sh) |

Regenerate plugin devcontainers after template edits:

```bash
cd pulp_plugin_template
./generate.sh maven python
```

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
