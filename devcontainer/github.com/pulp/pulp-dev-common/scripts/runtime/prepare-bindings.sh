#!/usr/bin/env bash
# Generate OpenAPI Python clients. domainEnabled from DEVCONTAINER_BINDINGS_DOMAIN_ENABLED.
set -euo pipefail

GENERATOR_VERSION="7.10.0"
GENERATOR_JAR="/opt/openapi-generator-cli.jar"
TEMPLATES_DIR="/opt/templates"
BINDINGS_DIR="/opt/bindings"
NAMESPACE_INIT='from pkgutil import extend_path\n__path__ = extend_path(__path__, __name__)\n'

force=false
components=()

for arg in "$@"; do
  if [ "$arg" = "--force" ]; then
    force=true
  else
    components+=("$arg")
  fi
done

if [ ${#components[@]} -eq 0 ]; then
  echo "Usage: prepare-bindings.sh <component1> [component2 ...] [--force]"
  echo "Example: prepare-bindings.sh core"
  exit 1
fi

if [ ! -f "${GENERATOR_JAR}" ]; then
  echo "Downloading OpenAPI Generator CLI ${GENERATOR_VERSION}..."
  sudo curl -L -o "${GENERATOR_JAR}" \
    "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/${GENERATOR_VERSION}/openapi-generator-cli-${GENERATOR_VERSION}.jar"
fi

if [ ! -d "${TEMPLATES_DIR}" ] || [ ! -f "${TEMPLATES_DIR}/configuration.mustache" ]; then
  echo "Downloading Pulp OpenAPI templates..."
  sudo mkdir -p "${TEMPLATES_DIR}"
  for tmpl in configuration.mustache partial_api_args.mustache requirements.mustache setup.mustache; do
    sudo curl -sL -o "${TEMPLATES_DIR}/${tmpl}" \
      "https://raw.githubusercontent.com/pulp/pulp-openapi-generator/refs/heads/main/templates/python/v${GENERATOR_VERSION}/${tmpl}"
  done
  sudo bash -c "printf '${NAMESPACE_INIT}' > ${TEMPLATES_DIR}/__init__.py"
fi

sudo mkdir -p "${BINDINGS_DIR}"
sudo chown "$(id -u):$(id -g)" "${BINDINGS_DIR}"

for comp in "${components[@]}"; do
  if [ "$comp" = "core" ]; then
    python_pkg="pulpcore"
    pkg_name="pulpcore-client"
  else
    python_pkg="pulp_${comp}"
    pkg_name="pulp_${comp}-client"
  fi

  if [ "$force" = false ] && [ -f "${BINDINGS_DIR}/${comp}-client/setup.py" ] && uv pip show "${pkg_name}" &>/dev/null; then
    echo "Bindings for ${comp} already installed (use --force to regenerate)"
    continue
  fi

  echo "Generating OpenAPI spec for ${comp}..."
  tmpspec=$(mktemp)
  pulpcore-manager openapi --bindings --component "${comp}" --file "${tmpspec}"

  echo "Generating Python bindings for ${comp}..."
  rm -rf "${BINDINGS_DIR}/${comp}-client"
  java -jar "${GENERATOR_JAR}" generate \
    -i "${tmpspec}" \
    -g python \
    -o "${BINDINGS_DIR}/${comp}-client" \
    -t "${TEMPLATES_DIR}" \
    --skip-validate-spec \
    --strict-spec=false \
    --additional-properties=packageName=pulpcore.client.${python_pkg},projectName="${pkg_name}",packageVersion=0.0.0.dev,domainEnabled=${DEVCONTAINER_BINDINGS_DOMAIN_ENABLED:-false}

  cp "${TEMPLATES_DIR}/__init__.py" "${BINDINGS_DIR}/${comp}-client/pulpcore/__init__.py"
  cp "${TEMPLATES_DIR}/__init__.py" "${BINDINGS_DIR}/${comp}-client/pulpcore/client/__init__.py"

  uv pip install "${pkg_name} @ ${BINDINGS_DIR}/${comp}-client"
  rm -f "${tmpspec}"
  echo "Installed ${pkg_name}"
done

echo "Binding generation complete."
