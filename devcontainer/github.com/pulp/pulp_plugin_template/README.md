# pulp_plugin_template

Shared devcontainer files and templates for Pulp plugin projects. A `generate.sh` script renders per-plugin devcontainer configs from templates and copies shared files.

## Structure

```
pulp_plugin_template/
├── .devcontainer/
│   ├── Dockerfile              # Shared: base image with build tools and Pulp dirs
│   ├── initializeCommand.sh    # Shared: host-side setup before container starts
│   ├── postCreateCommand.sh    # Shared: installs deps, runs migrations, shell helpers
│   ├── settings.py             # Shared: Django/Pulp settings for dev
│   ├── devcontainer.json       # Template: uses __PLUGIN__ placeholders
│   └── docker-compose.yml      # Template: uses __PLUGIN__ placeholders
├── generate.sh                 # Renders templates + copies shared files
└── README.md
```

## Adding a new plugin

```bash
cd devcontainer/github.com/pulp/pulp_plugin_template
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

After modifying templates or shared files, regenerate all plugins:

```bash
./generate.sh maven python
```
