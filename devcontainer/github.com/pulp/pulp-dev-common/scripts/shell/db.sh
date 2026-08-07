# Database helpers.

pulp-migrate() { pulpcore-manager migrate --noinput; }
pulp-psql() { env PGPASSWORD=pulp psql -U pulp -d pulp -h "$DB_HOST" -p 5432 "$@"; }
postgres-psql() { env PGPASSWORD=pulp psql -U pulp -d postgres -h "$DB_HOST" -p 5432 "$@"; }
pulp-reset() { bash "${DEVCONTAINER_DEV_SCRIPTS}/runtime/reset.sh" "$@"; }
