# pulp_plugin_template

Shared devcontainer templates for Pulp projects. A `generate.sh` script renders per-project devcontainer configs from two template layers:

- **core/** — base templates for pulpcore (no external Pulp dependencies)
- **plugin/** — templates for Pulp plugins (mounts pulpcore as a dependency under `/repositories`)
- **shared/** — files identical for both (Dockerfile, initializeCommand.sh, settings.py)

## Structure

```
pulp_plugin_template/
├── core/
│   ├── devcontainer.json         # Template: uses __NAME__ placeholders
│   ├── docker-compose.yml        # Template: uses __NAME__, __NAME_UPPER__ placeholders
│   └── postCreateCommand.sh      # Core: no pulpcore-as-dependency logic
├── plugin/
│   ├── devcontainer.json         # Template: uses __PLUGIN__ placeholders
│   ├── docker-compose.yml        # Template: uses __PLUGIN__, __PLUGIN_UPPER__ placeholders
│   └── postCreateCommand.sh      # Plugin: adds pulpcore install, CLI extension
├── shared/
│   ├── Dockerfile                # Base image with build tools and Pulp dirs
│   ├── initializeCommand.sh      # Host-side setup before container starts
│   └── settings.py               # Django/Pulp settings for dev
├── generate.sh                   # Renders templates + copies shared files
└── README.md
```

## Generating pulpcore

```bash
cd devcontainer/github.com/pulp/pulp_plugin_template
./generate.sh core
```

This creates `../pulpcore/.devcontainer/` with all necessary files.

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

## Regenerating existing projects

After modifying templates or shared files, regenerate all:

```bash
./generate.sh core
./generate.sh maven python
```
