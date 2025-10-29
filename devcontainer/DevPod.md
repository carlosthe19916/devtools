- Setup Podman:

```shell
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

- General command:

```shell
sudo chown vscode:vscode ~/.local
```

- Trustify-ui:

```shell
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/trustify-ui/.devcontainer/vscode \
--devcontainer-path devcontainer.json --id trustify-ui --provider docker --ide vscode
```

- Trustify

```shell
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/trustify/.devcontainer/vscode \
--devcontainer-path devcontainer.json --id trustify --provider docker --ide vscode
```
