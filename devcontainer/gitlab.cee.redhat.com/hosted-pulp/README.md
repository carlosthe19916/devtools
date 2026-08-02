# Trustify

Environment variables:

| Environment variable | default value             |
|----------------------|---------------------------|
| DEVTOOLS_TSD_UI_PATH | ~/git/devtools            |
| PULP_PACKAGES_UI     | ~/git/guacsec/trustify-ui |

Make sure the environment variables are defined at `~/.bashrc` or equivalent:

```shell
if [ -z "DEVTOOLS_TSD_UI_PATH" ]; then
  echo "export DEVTOOLS_TSD_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$PULP_PACKAGES_UI" ]; then
  echo "export PULP_PACKAGES_UI=/cloned_repository_directory" >> ~/.bashrc;
fi
```

> `/cloned_repository_directory` should be replaced by the directory where you cloned the repository
