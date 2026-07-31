# pulp-profile (mount point)

Per-project skill overlay. pulp-service bind-mounts its
`.devcontainer/skills/pulp-profile/` over this directory.

This placeholder exists so Podman has a host path under the common `skills/`
bind; otherwise it creates an empty `nobody`-owned stub on every container start.
Do not put service-specific skill content here.
