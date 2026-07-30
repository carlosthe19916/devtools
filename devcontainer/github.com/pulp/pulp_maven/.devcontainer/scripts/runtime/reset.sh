#!/usr/bin/env bash
# Drop/recreate the pulp database, then reuse setup/40-database.sh
# (redis flush, migrate, admin password, collectstatic).
# Prefer stopping pulp-services first so no API/worker holds connections.
set -euo pipefail

DB_HOST="${DB_HOST:-pulp-maven-db}"
DB_USER="${DB_USER:-pulp}"
DB_PASSWORD="${DB_PASSWORD:-pulp}"
DB_NAME="${DB_NAME:-pulp}"
ROOT="${PULP_DEV_SCRIPTS:-/opt/pulp-dev/scripts}"

echo "warning: stop pulp-services (api/content/worker) before reset for a clean migrate" >&2

echo "==> Recreating database '${DB_NAME}' on ${DB_HOST}"
env PGPASSWORD="${DB_PASSWORD}" psql -U "${DB_USER}" -d postgres -h "${DB_HOST}" -p 5432 -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
SQL

echo "==> Running setup/40-database.sh"
bash "${ROOT}/setup/40-database.sh"

echo "Done. Start services with: pulp-services"
