# Pulp process helpers. Start from a neutral cwd via runtime/run-*.sh so
# /workspace does not shadow the editable pulp_service package.

pulp-api() { bash "${PULP_DEV_SCRIPTS}/runtime/run-api.sh"; }
pulp-content() { bash "${PULP_DEV_SCRIPTS}/runtime/run-content.sh"; }
pulp-worker() { pulpcore-worker; }

pulp-services() {
  export PYTHONSAFEPATH=1
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "env PYTHONSAFEPATH=1 bash ${PULP_DEV_SCRIPTS}/runtime/run-api.sh" \
    "env PYTHONSAFEPATH=1 bash ${PULP_DEV_SCRIPTS}/runtime/run-content.sh" \
    "env PYTHONSAFEPATH=1 pulpcore-worker"
}
