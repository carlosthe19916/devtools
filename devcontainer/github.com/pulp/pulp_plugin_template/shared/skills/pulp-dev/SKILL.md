---
name: pulp-dev
description: Pulp plugin development — services, tests, CLI, and bindings. Use when starting Pulp, running tests, or configuring the local CLI.
---

# Pulp Development

## Services

```bash
pulp-services    # API :24817, content :24816, worker
# or: pulp-api | pulp-content | pulp-worker
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'  # stop all
```

API admin: `admin` / `password`

## Tests

```bash
pytest pulp_*/tests/unit/ -v
pytest pulp_*/tests/functional/ -v                    # needs pulp-services
pytest pulp_*/tests/functional/{path}.py -v           # one file
```

## CLI

```bash
pulp config create --base-url http://localhost:24817 --username admin --password password --no-verify-ssl
```

## Bindings

OpenAPI clients (`pulpcore.client.*`) are generated at setup into `/opt/bindings/`. Regenerate after schema changes:

```bash
pulp-bindings <component> [...]   # e.g. pulp-bindings maven, pulp-bindings core
```

## Local pulpcore

If mounted at `/repositories/pulpcore`:

```bash
pulp-core-local   # editable install
pulp-core-pypi    # back to PyPI
```

## DB / Redis

| | |
|---|---|
| Postgres | `pulp`/`pulp` @ `$DB_HOST`:5432 — `pulp-migrate`, `psql -h "$DB_HOST" -U pulp -d pulp` |
| Redis | `$REDIS_URL` — `redis-cli -u "$REDIS_URL"` |
