# pulp_plugin_template

Shared devcontainer templates for Pulp **plugins**. A `generate.sh` script renders per-plugin devcontainer configs.

- **plugin/** — templates for Pulp plugins (mounts pulpcore as a dependency under `/repositories`)
- **shared/** — files identical across plugins (Dockerfile, initializeCommand.sh, settings.py, …)

**pulpcore** is not generated here. Its definition is hand-maintained at [`../pulpcore/.devcontainer/`](../pulpcore/.devcontainer/) (same pattern as pulp-service).

## Structure

```
pulp_plugin_template/
├── plugin/
│   ├── devcontainer.json         # Template: uses __PLUGIN__ placeholders
│   ├── docker-compose.yml        # Template: uses __PLUGIN__, __PLUGIN_UPPER__ placeholders
│   └── postCreateCommand.sh      # Plugin: adds pulpcore install, CLI extension
├── shared/
│   ├── Dockerfile                # Base image with build tools and Pulp dirs
│   ├── initializeCommand.sh      # Host-side setup before container starts
│   ├── settings.py               # Django/Pulp settings for dev
│   ├── prepare-bindings.sh
│   ├── nginx.conf
│   ├── postStartCommand.sh
│   ├── skills/
│   └── patches/
├── generate.sh                   # Renders templates + copies shared files
└── README.md
```

## Adding a new plugin

```bash
./generate.sh <plugin_name>
```

For example, to add `pulp_rpm`:

```bash
./generate.sh rpm
```

This creates `../pulp_rpm/.devcontainer/` with all necessary files. Then copy the `devcontainer-lock.json` from an existing plugin:

```bash
cp ../pulp_maven/.devcontainer/devcontainer-lock.json ../pulp_rpm/.devcontainer/
```

## Regenerating existing plugins

After modifying templates or shared files, regenerate plugins:

```bash
./generate.sh maven python
```
