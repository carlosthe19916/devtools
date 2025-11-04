# Podman

Start Podman service for a regular user (rootless) and make it listen to a socket:

```shell
systemctl --user enable --now podman.socket
```

Restart your OS if necessary and verify that podman listens:

```shell
systemctl --user status podman.socket
```

# VSCode

Install the Dev Container
extension <https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers>

Go to the Extension Settings and
configure [Alternative: Repository configuration folders](https://code.visualstudio.com/docs/devcontainers/create-dev-container#_alternative-repository-configuration-folders):

- `Dev › Containers: Repository Configuration Paths` add the directory where you downloaded this repo E.g.
  `/home/cferiavi/git/devtools/devcontainer/`

If you are using Podman then also:

- `Dev › Containers: Docker Compose Path` set `podman-compose`
- `Dev › Containers: Docker Path` set `podman`
- `Dev › Containers: Docker Socket Path` set `/run/podman/podman.sock`

# JetBrains

# DevPod

- Trustify

```shell
podman network create trustify || true && \
podman volume create cargo-cache || true && \
podman volume create nvim-cache || true && \
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/trustify/.devcontainer/vscode \
--devcontainer-path devcontainer.json \
--dotfiles https://github.com/carlosthe19916/dotfiles.git \
--dotfiles-script devcontainer/install.sh \
--id trustify \
--provider docker \
--ide vscode
```

- Trustify -ui

```shell
podman network create trustify || true && \
podman volume create npm-cache || true && \
podman volume create nvim-cache || true && \
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/trustify-ui/.devcontainer/vscode \
--devcontainer-path devcontainer.json \
--dotfiles https://github.com/carlosthe19916/dotfiles.git \
--dotfiles-script devcontainer/install.sh \
--id trustify-ui \
--provider docker \
--ide vscode
```

- Rhtas

```shell
podman network create rhtas || true && \
podman volume create go-cache || true && \
podman volume create nvim-cache || true && \
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/rhtas-console/.devcontainer/vscode \
--devcontainer-path devcontainer.json \
--dotfiles https://github.com/carlosthe19916/dotfiles.git \
--dotfiles-script devcontainer/install.sh \
--id rhtas-console \
--provider docker 
--ide vscode
```

- Rhtas-ui

```shell
podman network create rhtas || true && \
podman volume create npm-cache || true && \
podman volume create nvim-cache || true && \
devpod up \
~/git/devtools/devcontainer/github.com/carlosthe19916/rhtas-console-ui/.devcontainer/vscode \
--devcontainer-path devcontainer.json \
--dotfiles https://github.com/carlosthe19916/dotfiles.git \
--dotfiles-script devcontainer/install.sh \
--id rhtas-console-ui \
--provider docker \
--ide vscode
```
