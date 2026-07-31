#!/usr/bin/env python3
"""Bootstrap maven repo/dist and upload local artifacts from assets/ (no domains)."""
from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

import requests

POPULATE_ROOT = Path(os.environ.get("PULP_POPULATE_ROOT", "/opt/pulp-dev/populate"))
ASSETS_ROOT = Path(os.environ.get("PULP_POPULATE_ASSETS", str(POPULATE_ROOT / "assets")))
BASE_URL = os.environ.get("PULP_POPULATE_BASE_URL", "http://localhost:24817").rstrip("/")
API_ROOT = os.environ.get("PULP_POPULATE_API_ROOT", "/pulp/").rstrip("/") + "/"
AUTH = (
    os.environ.get("PULP_POPULATE_USER", "admin"),
    os.environ.get("PULP_POPULATE_PASSWORD", "password"),
)

session = requests.Session()
session.auth = AUTH

MAVEN = {
    "dist_path": "distributions/maven/maven/",
    "repo_path": "repositories/maven/maven/",
    "upload_path": "content/maven/artifact/",
    "content_path": "content/maven/artifact/",
    "assets_dir": "maven",
    "dist_name": "my-maven-dist",
    "base_path": "my-maven-path",
    "repo_name": "my-maven-repo",
}


def api(path: str) -> str:
    return f"{BASE_URL}{API_ROOT}api/v3/{path.lstrip('/')}"


def print_response(resp: requests.Response) -> None:
    if resp.status_code == 400:
        try:
            body = resp.json()
        except Exception:
            body = {}
        if any("unique" in str(v).lower() for v in body.values()):
            print("  already exists")
            return
    print(f"  {resp.status_code} {resp.reason}")
    try:
        print(json.dumps(resp.json(), indent=2))
    except Exception:
        print(resp.text)
    print()


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
    m = re.match(r"junit-(?P<ver>\d+\.\d+\.\d+)\.(?P<ext>jar|pom)$", path.name)
    if m:
        ver = m.group("ver")
        return f"junit/junit/{ver}/{path.name}"
    return path.name


def asset_files(assets_dir: str) -> list[Path]:
    root = ASSETS_ROOT / assets_dir
    if not root.is_dir():
        print(f"  Missing assets dir: {root}")
        return []
    return sorted(p for p in root.iterdir() if p.is_file())


print("=== Creating maven repository ===")
resp = session.post(api(MAVEN["repo_path"]), json={"name": MAVEN["repo_name"]})
print_response(resp)

print("=== Creating maven distribution ===")
resp = session.post(
    api(MAVEN["dist_path"]),
    json={"name": MAVEN["dist_name"], "base_path": MAVEN["base_path"]},
)
print_response(resp)

print("=== Attaching repository to distribution ===")
repo_href = get_by_name(MAVEN["repo_path"], MAVEN["repo_name"])["pulp_href"]
dist_href = get_by_name(MAVEN["dist_path"], MAVEN["dist_name"])["pulp_href"]
resp = session.patch(f"{BASE_URL}{dist_href}", json={"repository": repo_href})
print_response(resp)

print(f"=== Uploading local packages from {ASSETS_ROOT} ===")
files = asset_files(MAVEN["assets_dir"])
if not files:
    print("  No files to upload")
else:
    for path in files:
        print(f"  Uploading {path.name}...")
        with path.open("rb") as fh:
            resp = session.post(
                api(MAVEN["upload_path"]),
                data={
                    "relative_path": maven_relative_path(path),
                    "repository": repo_href,
                },
                files={"file": (path.name, fh)},
            )
        content_hrefs = content_hrefs_from_upload(resp)
        if not content_hrefs and resp.status_code not in (200, 201, 202):
            print_response(resp)

print("=== Listing maven content ===")
repo = get_by_name(MAVEN["repo_path"], MAVEN["repo_name"])
resp = session.get(
    api(MAVEN["content_path"]),
    params={"repository_version": repo.get("latest_version_href"), "limit": 100},
)
print_response(resp)
print(
    "Done. Content URL example: "
    f"{BASE_URL}/api/pulp-content/{MAVEN['base_path']}/"
)
