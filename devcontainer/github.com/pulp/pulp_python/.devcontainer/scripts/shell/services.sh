# Pulp process helpers — API :24817, content :24816, worker.
# Start from a neutral cwd via runtime/run-*.sh so /workspace does not shadow packages.

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
