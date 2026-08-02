# RHTAS Console

Environment variables:

| Environment variable   | default value                       |
|------------------------|-------------------------------------|
| DEVTOOLS_TSD_UI_PATH   | ~/git/devtools                      |
| RHTAS_CONSOLE_PATH     | ~/git/securesign/rhtas-console      |
| RHTAS_CONSOLE_UI_PATH  | ~/git/securesign/rhtas-console-ui   |

Make sure the environment variables are defined at `~/.bashrc` or equivalent:

```shell
if [ -z "$DEVTOOLS_TSD_UI_PATH" ]; then
  echo "export DEVTOOLS_TSD_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$RHTAS_CONSOLE_PATH" ]; then
  echo "export RHTAS_CONSOLE_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

```shell
if [ -z "$RHTAS_CONSOLE_UI_PATH" ]; then
  echo "export RHTAS_CONSOLE_UI_PATH=/cloned_repository_directory" >> ~/.bashrc;
fi
```

> `/cloned_repository_directory` should be replaced by the directory where you cloned the repository
