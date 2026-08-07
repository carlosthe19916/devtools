#!/usr/bin/env python3
"""Bootstrap repos/dists and upload local packages from assets/.

Readable top-to-bottom flow (same shape as the original pulp-service script).
Compose selects behavior via:

  DEVCONTAINER_POPULATE_MODE=plugin|service
  DEVCONTAINER_POPULATE_TYPES=file,pypi,maven,...   (subset of CONTENT_TYPES)
  DEVCONTAINER_POPULATE_BASE_URL / DOMAIN / USER / PASSWORD
"""
from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

import requests

POPULATE_ROOT = Path(os.environ.get("DEVCONTAINER_POPULATE_ROOT", "/opt/pulp-dev/populate"))
ASSETS_ROOT = Path(os.environ.get("DEVCONTAINER_POPULATE_ASSETS", str(POPULATE_ROOT / "assets")))
MODE = os.environ.get("DEVCONTAINER_POPULATE_MODE", "plugin")  # plugin | service
DOMAIN = os.environ.get("DEVCONTAINER_POPULATE_DOMAIN", "my-public-domain")
API_ROOT = os.environ.get("DEVCONTAINER_POPULATE_API_ROOT", "/pulp/").rstrip("/") + "/"
# Direct REST API (pulpcore-api), not nginx :80 — avoids 502 when API is down.
BASE_URL = os.environ.get("DEVCONTAINER_POPULATE_BASE_URL", "http://localhost:24817").rstrip("/")
AUTH = (
    os.environ.get("DEVCONTAINER_POPULATE_USER", "admin"),
    os.environ.get("DEVCONTAINER_POPULATE_PASSWORD", "password"),
)

session = requests.Session()
session.auth = AUTH

# Service paths are relative to /api/pulp/{domain}/api/v3/distributions|repositories|...
# Plugin/core paths are relative to {API_ROOT}api/v3/ (include distributions/ / repositories/).
if MODE == "service":
    ALL_TYPES = {
        "file": {
            "dist_path": "file/file/",
            "repo_path": "file/file/",
            "upload_path": "content/file/files/upload/",
            "content_path": "content/file/files/",
            "assets_dir": "file",
        },
        "pypi": {
            "dist_path": "python/pypi/",
            "repo_path": "python/python/",
            "upload_path": "content/python/packages/upload/",
            "content_path": "content/python/packages/",
            "assets_dir": "pypi",
        },
        "maven": {
            "dist_path": "maven/maven/",
            "repo_path": "maven/maven/",
            "upload_path": "content/maven/artifact/upload/",
            "content_path": "content/maven/artifact/",
            "assets_dir": "maven",
        },
        "npm": {
            "dist_path": "npm/npm/",
            "repo_path": "npm/npm/",
            "upload_path": "content/npm/packages/upload/",
            "content_path": "content/npm/packages/",
            "assets_dir": "npm",
        },
        "rpm": {
            "dist_path": "rpm/rpm/",
            "repo_path": "rpm/rpm/",
            "upload_path": "content/rpm/packages/upload/",
            "content_path": "content/rpm/packages/",
            "assets_dir": "rpm",
        },
    }
else:
    ALL_TYPES = {
        "file": {
            "dist_path": "distributions/file/file/",
            "repo_path": "repositories/file/file/",
            "upload_path": "content/file/files/upload/",
            "content_path": "content/file/files/",
            "assets_dir": "file",
        },
        "pypi": {
            "dist_path": "distributions/python/pypi/",
            "repo_path": "repositories/python/python/",
            "upload_path": "content/python/packages/",
            "content_path": "content/python/packages/",
            "assets_dir": "pypi",
        },
        "maven": {
            "dist_path": "distributions/maven/maven/",
            "repo_path": "repositories/maven/maven/",
            "upload_path": "content/maven/artifact/",
            "content_path": "content/maven/artifact/",
            "assets_dir": "maven",
        },
        "npm": {
            "dist_path": "distributions/npm/npm/",
            "repo_path": "repositories/npm/npm/",
            "upload_path": "content/npm/packages/",
            "content_path": "content/npm/packages/",
            "assets_dir": "npm",
        },
        "rpm": {
            "dist_path": "distributions/rpm/rpm/",
            "repo_path": "repositories/rpm/rpm/",
            "upload_path": "content/rpm/packages/",
            "content_path": "content/rpm/packages/",
            "assets_dir": "rpm",
        },
    }

_wanted = [
    t.strip()
    for t in os.environ.get("DEVCONTAINER_POPULATE_TYPES", ",".join(ALL_TYPES)).split(",")
    if t.strip()
]
unknown = [t for t in _wanted if t not in ALL_TYPES]
if unknown:
    raise SystemExit(f"Unknown DEVCONTAINER_POPULATE_TYPES: {unknown}; known={sorted(ALL_TYPES)}")
CONTENT_TYPES = {k: ALL_TYPES[k] for k in _wanted}


def api(path: str) -> str:
    path = path.lstrip("/")
    if MODE == "service":
        return f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/{path}"
    return f"{BASE_URL}{API_ROOT}api/v3/{path}"


def print_response(resp: requests.Response) -> None:
    if resp.status_code == 400:
        try:
            body = resp.json()
        except Exception:
            body = {}
        if any("unique" in str(v).lower() for v in body.values()):
            name = ""
            try:
                name = json.loads(resp.request.body or b"{}").get("name", "")
            except Exception:
                name = ""
            print(f"  {name} already exists" if name else "  already exists")
            return
    print(f"  {resp.status_code} {resp.reason}")
    try:
        print(json.dumps(resp.json(), indent=2))
    except Exception:
        print(resp.text)
    print()


def instance_names(content_type: str) -> tuple[str, str, str]:
    return f"my-{content_type}-dist", f"my-{content_type}-path", f"my-{content_type}-repo"


def wait_for_task(task_href: str, timeout: int = 300, poll_interval: int = 5):
    elapsed = 0
    while elapsed < timeout:
        resp = session.get(f"{BASE_URL}{task_href}")
        task = resp.json()
        state = task["state"]
        if state == "completed":
            print(f"  Task completed ({task_href})")
            return task
        if state in ("failed", "canceled", "canceling"):
            print(f"  Task {state} ({task_href})")
            if "error" in task:
                print(f"  Error: {task['error']}")
            return task
        print(f"  Task {state}... ({elapsed}s)")
        time.sleep(poll_interval)
        elapsed += poll_interval
    print(f"  Task timed out after {timeout}s")
    return None


def get_by_name(collection_path: str, name: str) -> dict:
    resp = session.get(api(collection_path), params={"name": name})
    resp.raise_for_status()
    results = resp.json()["results"]
    if not results:
        raise RuntimeError(f"No object named {name!r} at {collection_path}")
    return results[0]


def content_hrefs_from_upload(resp: requests.Response) -> list[str]:
    """Return pulp content hrefs created by an upload call."""
    if resp.status_code == 202:
        task_href = resp.json()["task"]
        task = wait_for_task(task_href)
        if not task or task.get("state") != "completed":
            return []
        return list(task.get("created_resources") or [])
    if resp.status_code in (200, 201):
        body = resp.json()
        href = body.get("pulp_href")
        return [href] if href else []
    print_response(resp)
    return []


def maven_relative_path(path: Path) -> str:
    """Map junit-<version>.(jar|pom) to Maven repo layout."""
    m = re.match(r"junit-(?P<ver>\d+\.\d+\.\d+)\.(?P<ext>jar|pom)$", path.name)
    if m:
        ver = m.group("ver")
        return f"junit/junit/{ver}/{path.name}"
    return path.name


def npm_name_version(path: Path):
    """Parse name/version from <name>-<version>.tgz."""
    m = re.match(r"(?P<name>.+)-(?P<ver>\d+\.\d+\.\d+)\.tgz$", path.name)
    if not m:
        return None, None
    return m.group("name"), m.group("ver")


def upload_form_fields(key: str, path: Path, repo_href: str) -> dict:
    data: dict = {}
    if key == "file":
        data["relative_path"] = path.name
    elif key == "maven":
        data["relative_path"] = maven_relative_path(path)
        data["repository"] = repo_href
    elif key == "npm":
        name, version = npm_name_version(path)
        if name and version:
            data["name"] = name
            data["version"] = version
    return data


def add_content_to_repository(repo_href: str, content_hrefs: list[str]) -> None:
    if not content_hrefs:
        return
    resp = session.post(
        f"{BASE_URL}{repo_href}modify/",
        json={"add_content_units": content_hrefs},
    )
    if resp.status_code == 202:
        wait_for_task(resp.json()["task"])
    else:
        print_response(resp)


def asset_files(assets_dir: str) -> list[Path]:
    root = ASSETS_ROOT / assets_dir
    if not root.is_dir():
        print(f"  Missing assets dir: {root}")
        return []
    return sorted(
        p for p in root.iterdir() if p.is_file() and not p.name.endswith(".metadata")
    )


def repo_collection(value: dict) -> str:
    if MODE == "service":
        return f"repositories/{value['repo_path']}"
    return value["repo_path"]


def dist_collection(value: dict) -> str:
    if MODE == "service":
        return f"distributions/{value['dist_path']}"
    return value["dist_path"]


def dist_create_url(value: dict) -> str:
    if MODE == "service":
        return api(f"distributions/{value['dist_path']}")
    return api(value["dist_path"])


def repo_create_url(value: dict) -> str:
    if MODE == "service":
        return api(f"repositories/{value['repo_path']}")
    return api(value["repo_path"])


print(f"Populate mode={MODE} base={BASE_URL} types={list(CONTENT_TYPES)} assets={ASSETS_ROOT}")

# 1. Create domain (service / domains only)
if MODE == "service":
    print("=== Creating domain ===")
    resp = session.post(
        f"{BASE_URL}/api/pulp/default/api/v3/domains/",
        json={
            "name": DOMAIN,
            "storage_class": "pulpcore.app.models.storage.FileSystem",
            "storage_settings": {"location": "/var/lib/pulp/media/"},
        },
    )
    print_response(resp)

# 2. Create distributions
print("=== Creating distributions ===")
for key, value in CONTENT_TYPES.items():
    dist_name, base_path, _ = instance_names(key)
    resp = session.post(
        dist_create_url(value),
        json={"name": dist_name, "base_path": base_path},
    )
    print_response(resp)

# 3. List distributions
print("=== Listing distributions ===")
resp = session.get(api("distributions/"))
print_response(resp)

# 4. Create repositories
print("=== Creating repositories ===")
for key, value in CONTENT_TYPES.items():
    _, _, repo_name = instance_names(key)
    resp = session.post(repo_create_url(value), json={"name": repo_name})
    print_response(resp)

# 5. List repositories
print("=== Listing repositories ===")
resp = session.get(api("repositories/"))
print_response(resp)

# 6. Attach repositories to distributions
print("=== Attaching repositories to distributions ===")
for key, value in CONTENT_TYPES.items():
    dist_name, _, repo_name = instance_names(key)
    repo_href = get_by_name(repo_collection(value), repo_name)["pulp_href"]
    dist_href = get_by_name(dist_collection(value), dist_name)["pulp_href"]
    resp = session.patch(f"{BASE_URL}{dist_href}", json={"repository": repo_href})
    print_response(resp)

# 7. Upload local packages into each repository
print(f"=== Uploading local packages from {ASSETS_ROOT} ===")
for key, value in CONTENT_TYPES.items():
    _, _, repo_name = instance_names(key)
    print(f"--- {key} ---")
    repo_href = get_by_name(repo_collection(value), repo_name)["pulp_href"]
    files = asset_files(value["assets_dir"])
    if not files:
        print("  No files to upload")
        continue

    for path in files:
        print(f"  Uploading {path.name}...")
        data = upload_form_fields(key, path, repo_href)
        with path.open("rb") as fh:
            resp = session.post(
                api(value["upload_path"]),
                data=data,
                files={"file": (path.name, fh)},
            )
        content_hrefs = content_hrefs_from_upload(resp)
        if key != "maven":
            add_content_to_repository(repo_href, content_hrefs)
        elif not content_hrefs and resp.status_code not in (200, 201, 202):
            print_response(resp)


def list_packages_for_type(key: str, value: dict) -> None:
    _, base_path, repo_name = instance_names(key)
    print(f"--- {key} ---")
    repo = get_by_name(repo_collection(value), repo_name)
    version_href = repo.get("latest_version_href")
    resp = session.get(
        api(value["content_path"]),
        params={"repository_version": version_href, "limit": 100},
    )
    print_response(resp)

    if key == "pypi" and MODE == "service":
        print(f"--- {key} simple index ---")
        simple = session.get(
            f"{BASE_URL}/api/pypi/{DOMAIN}/{base_path}/simple/",
            headers={"Accept": "application/vnd.pypi.simple.v1+json"},
        )
        print_response(simple)
    elif key == "pypi":
        print(f"  Simple index example: {BASE_URL}/pypi/{base_path}/simple/")


# 8. List packages for all content types
print("=== Listing packages for all types ===")
for key, value in CONTENT_TYPES.items():
    list_packages_for_type(key, value)

print("Populate complete.")
