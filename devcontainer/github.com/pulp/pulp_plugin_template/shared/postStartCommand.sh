#!/bin/bash

sudo service nginx start

################################################################################
# Regenerate OpenAPI client bindings
################################################################################

if [ -d /workspace/pulpcore/app ]; then
    bash /tmp/prepare-bindings.sh --force core
else
    plugin_dir=$(ls -d /workspace/pulp_*/app 2>/dev/null | head -1 | xargs dirname | xargs basename)
    plugin_suffix=$(echo "$plugin_dir" | sed 's/^pulp_//')
    bash /tmp/prepare-bindings.sh --force core "$plugin_suffix"
fi
