#!/bin/bash

sudo service nginx start

################################################################################
# Regenerate OpenAPI client bindings
# Match pulp-service pulp-test components + installed content plugins.
# domainEnabled=true via service prepare-bindings.sh
################################################################################

# Align with pulp-service pulp-test COMPONENTS plus installed plugins:
#   pulpcore pulp_python pulp_npm pulp_rpm pulp_maven pulp_file pulp_service
# also installed via requirements: pulp_container, pulp_hugging_face
bash /tmp/prepare-bindings.sh --force \
    core python npm rpm maven file service container hugging_face
