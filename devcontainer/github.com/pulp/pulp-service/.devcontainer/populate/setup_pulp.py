#!/usr/bin/env python3
"""Bootstrap a domain with distributions/repos and upload local packages from assets/."""
from __future__ import annotations

import json
import os
import time
from pathlib import Path

import requests

POPULATE_ROOT = Path(os.environ.get("PULP_POPULATE_ROOT", "/opt/pulp-dev/populate"))
ASSETS_ROOT = Path(os.environ.get("PULP_POPULATE_ASSETS", str(POPULATE_ROOT / "assets")))
BASE_URL = os.environ.get("PULP_POPULATE_BASE_URL", "http://localhost:24817")
DOMAIN = os.environ.get("PULP_POPULATE_DOMAIN", "my-public-domain")
AUTH = (
    os.environ.get("PULP_POPULATE_USER", "admin"),
    os.environ.get("PULP_POPULATE_PASSWORD", "password"),
)

session = requests.Session()
session.auth = AUTH

CONTENT_TYPES = {
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


def print_response(resp: requests.Response) -> None:
    if resp.status_code == 400:
        body = resp.json()
        if any("unique" in str(v).lower() for v in body.values()):
            name = ""
            try:
                name = json.loads(resp.request.body or b"{}").get("name", "")
            except Exception:
                name = ""
            print(f"  {name} already exists")
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
    resp = session.get(
        f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/{collection_path}",
        params={"name": name},
    )
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
    import re

    name = path.name
    m = re.match(r"junit-(?P<ver>\d+\.\d+\.\d+)\.(?P<ext>jar|pom)$", name)
    if m:
        ver = m.group("ver")
        return f"junit/junit/{ver}/{name}"
    return name


def npm_name_version(path: Path):
    """Parse name/version from <name>-<version>.tgz."""
    import re

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


# 1. Create domain
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
        f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/distributions/{value['dist_path']}",
        json={"name": dist_name, "base_path": base_path},
    )
    print_response(resp)

# 3. List distributions
print("=== Listing distributions ===")
resp = session.get(f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/distributions/")
print_response(resp)

# 4. Create repositories
print("=== Creating repositories ===")
for key, value in CONTENT_TYPES.items():
    _, _, repo_name = instance_names(key)
    resp = session.post(
        f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/repositories/{value['repo_path']}",
        json={"name": repo_name},
    )
    print_response(resp)

# 5. List repositories
print("=== Listing repositories ===")
resp = session.get(f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/repositories/")
print_response(resp)

# 6. Attach repositories to distributions
print("=== Attaching repositories to distributions ===")
for key, value in CONTENT_TYPES.items():
    dist_name, _, repo_name = instance_names(key)
    repo_href = get_by_name(f"repositories/{value['repo_path']}", repo_name)["pulp_href"]
    dist_href = get_by_name(f"distributions/{value['dist_path']}", dist_name)["pulp_href"]
    resp = session.patch(f"{BASE_URL}{dist_href}", json={"repository": repo_href})
    print_response(resp)

# 7. Upload local packages into each repository
print(f"=== Uploading local packages from {ASSETS_ROOT} ===")
for key, value in CONTENT_TYPES.items():
    _, _, repo_name = instance_names(key)
    print(f"--- {key} ---")
    repo_href = get_by_name(f"repositories/{value['repo_path']}", repo_name)["pulp_href"]
    files = asset_files(value["assets_dir"])
    if not files:
        print("  No files to upload")
        continue

    for path in files:
        print(f"  Uploading {path.name}...")
        data = upload_form_fields(key, path, repo_href)
        with path.open("rb") as fh:
            resp = session.post(
                f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/{value['upload_path']}",
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
    repo = get_by_name(f"repositories/{value['repo_path']}", repo_name)
    version_href = repo.get("latest_version_href")
    resp = session.get(
        f"{BASE_URL}/api/pulp/{DOMAIN}/api/v3/{value['content_path']}",
        params={"repository_version": version_href, "limit": 100},
    )
    print_response(resp)

    # Extra client-style index for PyPI
    if key == "pypi":
        print(f"--- {key} simple index ---")
        simple = session.get(
            f"{BASE_URL}/api/pypi/{DOMAIN}/{base_path}/simple/",
            headers={"Accept": "application/vnd.pypi.simple.v1+json"},
        )
        print_response(simple)


# 8. List packages for all content types
print("=== Listing packages for all types ===")
for key, value in CONTENT_TYPES.items():
    list_packages_for_type(key, value)
