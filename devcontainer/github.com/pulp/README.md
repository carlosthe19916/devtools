# Pulp

Environment variables:

| Environment variable | default value           |
|----------------------|-------------------------|
| DEVTOOLS_CARLOSTHE19916_PATH | ~/git/devtools          |
| PULPCORE_PATH        | ~/git/pulp/pulpcore     |
| PULP_MAVEN_PATH      | ~/git/pulp/pulp_maven   |
| PULP_PYTHON_PATH     | ~/git/pulp/pulp_python  |

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
