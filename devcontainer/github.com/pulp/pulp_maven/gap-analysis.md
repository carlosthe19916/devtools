# Gap Analysis: pulp_maven devcontainer vs pulp-service dev-container

## Context

The pulp-service dev-container (`pulp-service/dev-container/`) is a fully self-contained Pulp development environment: one container running PostgreSQL, Redis, and all Pulp services (API, content, worker) via supervisord, with an entrypoint that bootstraps the database, runs migrations, and sets the admin password.

The pulp_maven devcontainer (`devcontainer/github.com/pulp/pulp_maven/.devcontainer/`) uses a different architecture — separate PostgreSQL and Redis containers via docker-compose, no running Pulp services — but we should understand what's missing to make it a functional Pulp development environment.

> **Note:** The directory fix (`mkdir -p /var/lib/pulp/{media,tmp}`) was already applied to all three Pulp Dockerfiles (pulp_maven, pulpcore, pulp_python).

---

## Gap Summary

### 1. No database migrations (HIGH)

**pulp-service:** `entrypoint.sh` line 49 runs `pulpcore-manager migrate --noinput` on every container start.

**pulp_maven:** Neither the Dockerfile, docker-compose, nor postCreateCommand.sh runs migrations. You have to run them manually. This is why `django-admin makemigrations` fails with system check errors even after the directory fix — the database isn't initialized.

**Impact:** Without migrations, no Pulp Django commands work. You can't use `pulpcore-manager`, `django-admin`, or start any Pulp service.

### 2. No admin user creation (HIGH)

**pulp-service:** `entrypoint.sh` line 53 runs `pulpcore-manager reset-admin-password --password password`.

**pulp_maven:** No admin user is ever created.

**Impact:** Even after running migrations manually, there's no user to authenticate API requests with.

### 3. No pulpcore editable install (HIGH)

**pulp-service:** `entrypoint.sh` line 43 does `pip install -e /workspace/pulp-service/pulp_service`.

**pulp_maven:** `postCreateCommand.sh` installs `pip install -e .` (pulp_maven itself), but does NOT install pulpcore. The `pip install -e .` will pull pulpcore as a dependency from PyPI (released version), not from a local checkout.

**Impact:** If you need to develop against a local pulpcore checkout (e.g., at `~/git/pulp/pulpcore`), it won't be mounted or installed. For pure pulp_maven development against a released pulpcore, this may be acceptable.

### 4. No running Pulp services (MEDIUM)

**pulp-service:** supervisord manages 6 processes — PostgreSQL, Redis, pulp-api (port 24817), pulp-content (port 24816), pulp-worker, and alcove-shim. All auto-restart on crash.

**pulp_maven:** PostgreSQL and Redis run in separate containers (docker-compose), but no Pulp services run. There's no `pulp-api`, `pulp-content`, or `pulp-worker` process.

**Impact:** You can't interact with the Pulp REST API or test content serving. You'd need to manually start these services.

### 5. Redis URL override may not work (MEDIUM)

**pulp_maven settings.py:** `REDIS_URL = "redis://localhost:6379/0"` (full connection string)

**docker-compose env vars:** `PULP_REDIS_HOST=pulp-maven-redis` and `PULP_REDIS_PORT=6379` (separate atomic settings)

**Problem:** If Pulp/dynaconf resolves `REDIS_URL` from the settings file before checking the individual `REDIS_HOST`/`REDIS_PORT` env vars, Redis will try to connect to `localhost:6379` instead of `pulp-maven-redis:6379`. The safer approach would be `PULP_REDIS_URL=redis://pulp-maven-redis:6379/0` in docker-compose, or removing `REDIS_URL` from settings.py entirely.

### 6. Settings differences (LOW — intentional)

These are not bugs but design differences between the upstream pulp_maven and the Red Hat pulp-service:

| Setting | pulp-service | pulp_maven | Notes |
|---|---|---|---|
| `CONTENT_ORIGIN` | `http://localhost:24816` | `http://localhost:24817` | Different port conventions |
| `CONTENT_PATH_PREFIX` | `/api/pulp-content/` | `/pulp/content/` | RH vs upstream path |
| `API_ROOT` | `/api/pulp/` | `/pulp/` | RH vs upstream path |
| `DOMAIN_ENABLED` | `True` | absent (False) | Multi-tenancy is RH-specific |
| `WORKER_TYPE` | `"redis"` | absent | |
| `DEFAULT_FILE_STORAGE` | explicit `FileSystem` | absent (defaults) | |
| Auth backends | 3 backends incl. RH SAML | absent (Django defaults) | RH-specific auth stack |
| REST auth classes | 4 classes incl. RH cert auth | absent (defaults) | RH-specific |
| `ATTESTATION_VERIFICATION_KEY` | set | absent | RH-specific |

These are expected — pulp_maven is an upstream community plugin, not a Red Hat service.

### 7. No developer utility scripts (LOW)

**pulp-service:** Ships `pulp-restart`, `pulp-add-patch`, `pulp-remove-patch`, `pulp-test` in `/usr/local/bin/`.

**pulp_maven:** No utility scripts.

**Impact:** Minor convenience. These are mainly useful for the pulp-service multi-plugin environment.

### 8. No `PULP_GUNICORN_RELOAD` (LOW)

**pulp-service:** Sets `PULP_GUNICORN_RELOAD=true` so API/content gunicorn processes auto-reload on code changes.

**pulp_maven:** Not set (irrelevant since no Pulp services run).

---

## Architecture Decision

The pulp_maven devcontainer deliberately uses a **lightweight, services-separated architecture** (PostgreSQL and Redis as separate docker-compose services). This is a valid design choice — it's simpler to maintain and follows the other devcontainers in this repo (trustify, rhtas-console, etc.).

To make it functional for Pulp development, the critical missing pieces are gaps #1-3 (migrations, admin user, dependencies). These can be added to `postCreateCommand.sh` without changing the architecture. Gaps #4-5 (running services, Redis URL) would require more significant changes if needed.
