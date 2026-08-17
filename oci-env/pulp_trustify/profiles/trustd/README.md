# trustd profile

Runs a local [Trustify](https://github.com/trustification/trustd) backend
alongside Pulp so `pulp_trustify` has a live vulnerability service to query
during development.

## What it starts

| Container | Role |
|-----------|------|
| `pulp-trustify-trustd-db` | `postgres:15` backing trustd |
| `pulp-trustify-trustd` | trustd API (auth disabled) |

On startup, trustd runs DB migrations, then serves the API with
`--auth-disabled`.

Both join the compose project's default network (no custom `networks:` block),
so the `pulp` container reaches trustd by service name at
`http://pulp-trustify-trustd:8080`. The API is also published to the host on
port **9010** for debugging.

## Auto-configuration

`pulp_config.env` sets `PULP_TRUSTIFY_URL=http://pulp-trustify-trustd:8080`, so
Pulp is pointed at the in-network trustd automatically. trustd runs with auth
disabled, so no client id/secret or issuer is needed. The default
`PULP_TRUSTIFY_API_VERSION` (`v2`) matches trustd.

This profile also sets `PULP_TRUSTIFY_GATE_UPLOADS=False`, so vulnerable
packages can be uploaded and then found by the scanner.

## Usage

Bring the stack up:

```bash
oci-env -e compose.env compose up
```

Set shell variables (run once per terminal):

```bash
export TRUSTIFY_URL=http://localhost:9010
export PULP=http://localhost:5002
export PULP_API="$PULP/api/pulp/default/api/v3"
export AUTH="-u admin:password"
export PULP_API="$PULP/api/pulp/public-rhai/api/v3"
```

Verify trustd from the host:

```bash
curl -sS "$TRUSTIFY_URL/.well-known/trustify" | jq
```

Verify plugins are installed:

```bash
curl -sS $AUTH "$PULP_API/status/" \
  | jq '.versions[] | select(.component=="trustify" or .component=="python" or .component=="npm")'
```

## Seed advisories

```bash
python tests/workflow.py seed
```

`workflow.py` uploads the PYSEC fixtures. Seed the NPM advisory as well:

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d @tests/e2e/fixtures/NPM-GHSA-7r28.json \
  "$TRUSTIFY_URL/api/v2/advisory?format=osv" | jq '{id: .document_id}'
```

Verify advisories are stored:

```bash
curl -sS "$TRUSTIFY_URL/api/v2/advisory?q=urllib3" | jq '.items[].identifier'
curl -sS "$TRUSTIFY_URL/api/v2/advisory?q=GHSA-7r28" | jq '.items[].identifier'
```

## Create Pulp resources

Paste this into your code agent (invokes the `pulp-populate` skill):

```bash
/pulp-populate --url http://localhost:5002 --no-auth create pulp resources:
- Domain: public-rhai
- Repositories:
  - type: python, name: urllib3-repo
  - type: npm, name: is-svg-repo
- Distributions (attach each repository to its distribution):
  - type: python, name: my-python-distribution, repositories: [urllib3-repo]
  - type: npm, name: my-npm-distribution, repositories: [is-svg-repo]

Then attach each repository to its distribution (PATCH the distribution
with the repository href).
```

`pulp-populate` creates domains, repositories, and distributions only.
**Attach links a distribution to a repository — it does not upload
packages.**

## Upload packages

- Python packages (upload both wheels into the same repo):

```bash
URLLIB3_REPO=$(curl -sS $AUTH "$PULP_API/repositories/python/python/?name=urllib3-repo" | jq -r '.results[0].pulp_href')

# Vulnerable: urllib3 2.6.2 (CVE-2026-21441, flagged by the scanner)
TASK=$(curl -sS $AUTH -X POST "$PULP_API/content/python/packages/" \
  -F "repository=$URLLIB3_REPO" \
  -F "relative_path=urllib3-2.6.2-py3-none-any.whl" \
  -F "file=@tests/e2e/fixtures/urllib3-2.6.2-py3-none-any.whl" | jq -r '.task')

echo "Task (2.6.2): $TASK"; sleep 5
curl -sS $AUTH "$PULP$TASK" | jq '{state, error}'

# Clean: urllib3 2.7.0 (fixed version, not flagged)
TASK=$(curl -sS $AUTH -X POST "$PULP_API/content/python/packages/" \
  -F "repository=$URLLIB3_REPO" \
  -F "relative_path=urllib3-2.7.0-py3-none-any.whl" \
  -F "file=@tests/e2e/fixtures/urllib3-2.7.0-py3-none-any.whl" | jq -r '.task')

echo "Task (2.7.0): $TASK"; sleep 5
curl -sS $AUTH "$PULP$TASK" | jq '{state, error}'
```

- NPM package:

```bash
NPM_REPO=$(curl -sS $AUTH "$PULP_API/repositories/npm/npm/?name=is-svg-repo" | jq -r '.results[0].pulp_href')

TASK=$(curl -sS $AUTH -X POST "$PULP_API/content/npm/packages/" \
  -F "repository=$NPM_REPO" \
  -F "name=is-svg" \
  -F "version=4.2.1" \
  -F "file=@tests/e2e/fixtures/is-svg-4.2.1.tgz" | jq -r '.task')

echo "Task: $TASK"; sleep 5
curl -sS $AUTH "$PULP$TASK" | jq '{state, error}'
```

Both complete with `state: "completed"` because the upload gate is off.

## Scan repositories

**Python**

```bash
SCAN_TASK=$(curl -sS $AUTH -X POST -H "Content-Type: application/json" \
  -d "{\"repository\": \"$URLLIB3_REPO\"}" "$PULP_API/trustify/scan/" | jq -r '.task')
echo "PyPI scan: $SCAN_TASK"; sleep 10
curl -sS $AUTH "$PULP$SCAN_TASK" | jq '{state}'
```

**NPM**

```bash
SCAN_TASK=$(curl -sS $AUTH -X POST -H "Content-Type: application/json" \
  -d "{\"repository\": \"$NPM_REPO\"}" "$PULP_API/trustify/scan/" | jq -r '.task')
echo "NPM scan: $SCAN_TASK"; sleep 10
curl -sS $AUTH "$PULP$SCAN_TASK" | jq '{state}'
```

## Check scan results

**Scan advisories** (one per vulnerable item):

```bash
curl -sS $AUTH "$PULP_API/trustify/advisories/" \
  | jq '.results[] | {purl, cve_ids, severity, action}'
```

`urllib3` **2.6.2** appears with `CVE-2026-21441`. `urllib3` **2.7.0** does not:
`2.7.0` is the fixed version (the advisory's affected range is `2.0.0` to before
`2.7.0`), so it clears the CVE and stays absent from this list. `is-svg` also does
not appear (severity=high, below the critical threshold).

**Vulnerable content labels:**

```bash
curl -sS $AUTH "$PULP_API/content/python/packages/?pulp_label_select=trustify.vulnerable=true" \
  | jq '.results[] | {filename, pulp_labels}'
```

Only `urllib3-2.6.2-py3-none-any.whl` is labeled `trustify.vulnerable=true` with
CVE details, severity, and detection mode. `urllib3-2.7.0-py3-none-any.whl` is
not returned — the scanner only labels **vulnerable** content.

## Gate advisories

With the upload gate off, this list is typically empty. Records appear only
for packages that passed the gate while it was enabled:

```bash
curl -sS $AUTH "$PULP_API/trustify/gate-advisories/" \
  | jq '.results[] | {purl, cve_ids, action}'
```
