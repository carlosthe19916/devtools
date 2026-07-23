---
description: Pulp development environment — services, testing, and CLI usage
---

# Pulp Development

## Starting services

Run all Pulp services (API, content, worker) in one terminal:

```bash
pulp-services
```

Or start them individually:

```bash
pulp-api        # API server on 127.0.0.1:24817
pulp-content    # Content server on 127.0.0.1:24816
pulp-worker     # Background task worker
```

## PostgreSQL database

- Database: `pulp`, User: `pulp`, Password: `pulp`, Port: `5432`
- Host: set via `PULP_DATABASES__default__HOST` env var (the docker service name, e.g., `pulpcore-db` or `pulp-maven-db`)
- The SQLTools VS Code extension is pre-configured with these credentials

```bash
pulp-migrate    # Run Django migrations
```

Connect directly with psql:

```bash
psql -h "$PULP_DATABASES__default__HOST" -U pulp -d pulp
```

Pulp admin credentials (for the API, not the database): `admin` / `password`

## Redis

- Host: set via `PULP_REDIS_URL` env var (e.g., `redis://pulpcore-redis:6379/0` or `redis://pulp-maven-redis:6379/0`)
- Port: `6379`, database `0`
- Used for task queueing (Pulp workers) and caching

Connect directly:

```bash
redis-cli -u "$PULP_REDIS_URL"
```

## Client bindings

OpenAPI Python client bindings (`pulpcore.client.*`) are **auto-generated during container setup** for `core` and the current plugin. They are installed to `/opt/bindings/`.

To regenerate bindings (e.g., after changing the API schema):

```bash
pulp-bindings <component> [component2 ...]   # e.g., pulp-bindings maven, pulp-bindings core
```

This forces regeneration regardless of whether bindings already exist.

## Running tests

Unit tests:

```bash
pytest pulp_*/tests/unit/ -v
```

Functional tests (requires services running):

```bash
pytest pulp_*/tests/functional/ -v ## Execute all tests
pytest pulp_*/tests/functional/{myFilePath}.py -v ## Execute one file test
```

## Pulp CLI

The `pulp` CLI is pre-installed. Configure it to point at the local API:

```bash
pulp config create --base-url http://localhost:24817 --username admin --password password --no-verify-ssl
```

## Using local pulpcore checkout

If a local pulpcore is mounted at `/repositories/pulpcore`:

```bash
pulp-core-local   # Install from local checkout
pulp-core-pypi    # Switch back to PyPI version
```

## Kill all services

```shell
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'
```