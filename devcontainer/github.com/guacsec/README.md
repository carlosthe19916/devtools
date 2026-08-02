# Trustify

Environment variables:

| Environment variable | default value             |
|----------------------|---------------------------|
| DEVTOOLS_TSD_UI_PATH | ~/git/devtools            |
| TRUSTIFY_PATH        | ~/git/guacsec/trustify    |
| TRUSTIFY_UI_PATH     | ~/git/guacsec/trustify-ui |

Make sure the environment variables are defined at `~/.bashrc` or equivalent:

```shell
if [ -z "DEVTOOLS_TSD_UI_PATH" ]; then
  echo "export DEVTOOLS_TSD_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$TRUSTIFY_PATH" ]; then
  echo "export TRUSTIFY_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$TRUSTIFY_UI_PATH" ]; then
  echo "export TRUSTIFY_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

> `/cloned_repository_directory` should be replaced by the directory where you cloned the repository
