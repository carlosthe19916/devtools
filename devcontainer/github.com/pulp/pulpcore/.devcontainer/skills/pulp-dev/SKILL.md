---
name: pulp-dev
description: Pulpcore development — services, tests, CLI, and bindings. Use when starting Pulp, running tests, or configuring the local CLI.
---

# Pulpcore Development

Helpers live under `/opt/pulp-dev/scripts` and are sourced into the shell via `pulp-shell.sh`.

## Services

```bash
pulp-services    # API :24817, content :24816, worker
# or: pulp-api | pulp-content | pulp-worker
pkill -f 'pulpcore-(api|content|worker)|concurrently.*pulpcore'  # stop all
```

API admin: `admin` / `password`

Nginx also proxies on `:80` (`/pulp/`, `/api/pulp-content/`).

## Tests

```bash
pytest pulpcore/tests/unit/ -v
pytest pulpcore/tests/functional/ -v                    # needs pulp-services
pytest pulpcore/tests/functional/{path}.py -v           # one file
```

## CLI

```bash
pulp config create --base-url http://localhost:24817 --username admin --password password --no-verify-ssl
```

## Bindings

OpenAPI clients (`pulpcore.client.*`) are generated at start into `/opt/bindings/`. Regenerate after schema changes:

```bash
pulp-bindings core
FORCE_BINDINGS=1 bash /opt/pulp-dev/scripts/runtime/ensure-bindings.sh
```

## Patches

Dev overlays in `/opt/pulp-dev/patches` are applied to `/workspace` at create time:

```bash
pulp-patches apply
pulp-patches remove
pulp-patches reapply
```

## DB / Redis

| | |
|---|---|
| Postgres | `pulp`/`pulp` @ `$DB_HOST`:5432 — `pulp-migrate`, `pulp-psql` |
| Redis | `$REDIS_URL` — `redis-cli -u "$REDIS_URL"` |
