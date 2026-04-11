import json
import os
from pathlib import Path
import re
import subprocess
import urllib.error
import urllib.request

from invoke.context import Context
from invoke.tasks import task

from config import ROOT_DIR

TOOLS_IMAGE = "ghcr.io/tankdonut/tools"
TOOLS_TAG = "latest"
IMAGE_SHA_PATTERN = re.compile(r"ghcr\.io/tankdonut/tools@\b(sha256:[a-f0-9]{64})\b")
SHA_PATTERN = re.compile(r"sha256:[a-f0-9]{64}")
BRANCH_NAME = "update/tools-sha"
SKIP_DIRS = {
    ".git",
    ".venv",
    "node_modules",
    ".sisyphus",
    "dist",
    ".ruff_cache",
    "__pycache__",
}


def info(msg: str) -> None:
    print(f"\033[1;34m==>\033[0m {msg}")


def warn_msg(msg: str) -> None:
    print(f"\033[1;33m==>\033[0m {msg}")


def fetch_latest_digest(image: str, tag: str, token: str | None = None) -> str:
    registry_host = image.split("/")[0]
    owner_name = "/".join(image.split("/")[1:])
    owner, name = owner_name.split("/", 1)

    token_url = f"https://{registry_host}/token?scope=repository:{owner}/{name}:pull"
    token_req = urllib.request.Request(token_url)

    try:
        with urllib.request.urlopen(token_req) as resp:
            token_data = json.loads(resp.read())
        auth_token: str = token_data["token"]
    except (urllib.error.URLError, KeyError) as exc:
        raise RuntimeError(f"Failed to get auth token from GHCR: {exc}") from exc

    manifest_url = f"https://{registry_host}/v2/{owner}/{name}/manifests/{tag}"
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "Accept": (
            "application/vnd.oci.image.manifest.v1+json"
            ", application/vnd.docker.distribution.manifest.v2+json"
        ),
    }

    if token:
        headers["Authorization"] = f"Bearer {token}"

    manifest_req = urllib.request.Request(manifest_url, headers=headers)

    try:
        with urllib.request.urlopen(manifest_req) as resp:
            digest = resp.headers.get("docker-content-digest")
            if digest:
                return digest

            body = json.loads(resp.read())
            return body["config"]["digest"]
    except (urllib.error.URLError, KeyError) as exc:
        raise RuntimeError(f"Failed to fetch manifest digest from GHCR: {exc}") from exc


def find_tools_sha_references(root_dir: Path, image: str) -> list[tuple[Path, str]]:
    image_pattern = re.compile(
        r"ghcr\.io/" + re.escape("/".join(image.split("/")[1:])) + r"@(sha256:[a-f0-9]{64})"
    )
    refs: list[tuple[Path, str]] = []

    for path in root_dir.rglob("*"):
        if not path.is_file():
            continue

        if any(skip in path.parts for skip in SKIP_DIRS):
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, PermissionError, OSError):
            continue

        for match in image_pattern.finditer(content):
            refs.append((path, match.group(1)))

    return refs


def find_sha_references(root_dir: Path, sha: str) -> list[Path]:
    files: list[Path] = []

    for path in root_dir.rglob("*"):
        if not path.is_file():
            continue

        if any(skip in path.parts for skip in SKIP_DIRS):
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, PermissionError, OSError):
            continue

        if sha in content:
            files.append(path)

    return files


def replace_sha_in_files(files: list[Path], old_sha: str, new_sha: str) -> int:
    count = 0

    for path in files:
        content = path.read_text(encoding="utf-8")
        updated = re.sub(re.escape(old_sha), new_sha, content)
        if updated != content:
            path.write_text(updated, encoding="utf-8")
            count += 1

    return count


@task
def tools_sha(
    c: Context,
    dry_run: bool = False,
    image: str = TOOLS_IMAGE,
    tag: str = TOOLS_TAG,
) -> None:
    is_ci = "CI" in os.environ
    github_token = os.environ.get("GITHUB_TOKEN")

    info(f"Fetching latest digest for {image}:{tag}")
    new_sha = fetch_latest_digest(image, tag, github_token)
    info(f"Latest digest: {new_sha}")

    image_refs = find_tools_sha_references(ROOT_DIR, image)

    if not image_refs:
        warn_msg(f"No {image} SHA references found in repository")
        return

    old_sha = image_refs[0][1]

    if old_sha == new_sha:
        info("Already up to date")
        return

    info(f"Current SHA: {old_sha}")
    info(f"Latest SHA:  {new_sha}")

    affected = find_sha_references(ROOT_DIR, old_sha)
    for f in sorted(affected):
        info(f"  {f.relative_to(ROOT_DIR)}")

    if dry_run:
        info("Dry run — no changes made")
        return

    count = replace_sha_in_files(affected, old_sha, new_sha)

    if is_ci:
        subprocess.run(["git", "checkout", "-B", BRANCH_NAME], check=True)
        subprocess.run(["git", "add", "-A"], check=True)
        msg = f"chore(deps): update tools image digest to {new_sha[:19]}..."
        subprocess.run(["git", "commit", "-m", msg], check=True)
        subprocess.run(["git", "push", "origin", BRANCH_NAME, "--force"], check=True)
        subprocess.run(
            [
                "gh",
                "pr",
                "create",
                "--title",
                "chore(deps): update tools image digest",
                "--body",
                f"Update {image}:{tag} digest from `{old_sha[:19]}...` to `{new_sha[:19]}...`",
                "--base",
                "main",
                "--head",
                BRANCH_NAME,
            ],
            check=True,
        )
    else:
        info(f"Updated {count} files")
        info("Review the changes and commit when ready")
