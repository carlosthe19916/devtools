#!/bin/bash

sudo service nginx start

################################################################################
# Regenerate OpenAPI client bindings
################################################################################

workspace_name=$(basename /workspace)
if [ "$workspace_name" = "pulpcore" ]; then
    bash /tmp/prepare-bindings.sh --force core
else
    plugin_suffix=$(echo "$workspace_name" | sed 's/^pulp_//')
    bash /tmp/prepare-bindings.sh --force core "$plugin_suffix"
fi
