# ruff: noqa: PT028
from datetime import UTC, datetime
import os
from pathlib import Path
import shlex
import subprocess

from dotenv import load_dotenv
from invoke.context import Context
from invoke.tasks import task

from config import BUILD_DIR, DIST_DIR, ROOT_DIR, TEST_DIR

load_dotenv()

DESTINATION_REGISTRY = os.getenv("DESTINATION_REGISTRY", "localhost")
IMAGE_NAMESPACE = os.getenv("IMAGE_NAMESPACE")
OCI_SOURCE_URL = os.getenv("OCI_SOURCE_URL")

USE_COLOR = True


def read_version(name: str) -> str:
    """Read a version from the repo-root `.<name>-version` file."""
    version_file = ROOT_DIR / f".{name}-version"
    try:
        value = version_file.read_text(encoding="utf-8").strip()
    except FileNotFoundError as err:
        raise RuntimeError(f"Version file not found: {version_file}") from err
    if not value:
        raise RuntimeError(f"Version file is empty: {version_file}")
    return value


FEDORA_VERSION = read_version("fedora")
UBUNTU_VERSION = read_version("ubuntu")


def detect_runtime(requested: str | None = None) -> str:
    if requested:
        if (
            subprocess.run(
                ["which", requested],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            != 0
        ):
            raise RuntimeError(f"Requested runtime '{requested}' not found.")
        return requested

    for candidate in ["podman", "docker"]:
        if (
            subprocess.run(
                ["which", candidate],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        ):
            return candidate

    raise RuntimeError("Neither podman nor docker found on system.")


def info(msg: str) -> None:
    if USE_COLOR:
        print(f"\033[1;34m==>\033[0m {msg}")
    else:
        print(f"==> {msg}")


def warn_msg(msg: str) -> None:
    if USE_COLOR:
        print(f"\033[1;33m==>\033[0m {msg}")
    else:
        print(f"==> {msg}")


def get_commit_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()


def get_git_context() -> dict[str, str | None]:
    short_sha = get_commit_sha()

    try:
        branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
        ).strip()
        if branch == "HEAD":
            branch = None
    except subprocess.CalledProcessError:
        branch = None

    try:
        git_tag = subprocess.check_output(
            ["git", "describe", "--tags", "--exact-match"], text=True
        ).strip()
    except subprocess.CalledProcessError:
        git_tag = None

    try:
        remote_url = subprocess.check_output(
            ["git", "remote", "get-url", "origin"], text=True
        ).strip()
    except subprocess.CalledProcessError:
        remote_url = None

    return {
        "short_sha": short_sha,
        "branch": branch,
        "git_tag": git_tag,
        "remote_url": remote_url,
    }


def resolve_namespace(remote_url: str | None) -> str:
    if IMAGE_NAMESPACE:
        return IMAGE_NAMESPACE

    if not remote_url:
        raise RuntimeError(
            "IMAGE_NAMESPACE not set and could not determine namespace from git remote."
        )

    if remote_url.startswith("git@"):
        path = remote_url.split(":", 1)[1]
    elif remote_url.startswith("http"):
        path = remote_url.split("/", 3)[-1]
    else:
        raise RuntimeError(f"Unsupported remote URL format: {remote_url}")

    owner = path.split("/", 1)[0]
    return owner


def sanitize_tag(value: str) -> str:
    return value.replace("/", "-")


def generate_metadata(
    registry: str,
    image: str,
    version_tag: str | None = None,
) -> tuple[list[str], dict[str, str]]:
    ctx = get_git_context()
    namespace = resolve_namespace(ctx["remote_url"])

    base = f"{registry}/{namespace}/{image}"

    tags: list[str] = []

    short_sha = ctx["short_sha"]
    tags.append(f"{base}:{short_sha}")

    branch = ctx["branch"]
    git_tag = ctx["git_tag"]

    if branch:
        tags.append(f"{base}:{sanitize_tag(branch)}")

    if git_tag:
        tags.append(f"{base}:{git_tag}")

    if branch == "main" and version_tag:
        tags.append(f"{base}:{version_tag}")

    created = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    source = OCI_SOURCE_URL or ctx["remote_url"] or ""

    version = git_tag or version_tag or short_sha
    ref_name = git_tag or branch or short_sha

    labels = {
        "org.opencontainers.image.revision": short_sha,
        "org.opencontainers.image.source": source,
        "org.opencontainers.image.created": created,
        "org.opencontainers.image.version": version,
        "org.opencontainers.image.ref.name": ref_name,
    }

    return tags, labels


def image_exists(runtime: str, image_ref: str) -> bool:
    return (
        subprocess.run(
            [runtime, "image", "inspect", image_ref],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )


def _save_image(c: Context, runtime: str, image_ref: str, image: str) -> None:
    out_file = Path(DIST_DIR) / "registry" / f"{image}-{get_commit_sha()}.tar"
    out_file.parent.mkdir(parents=True, exist_ok=True)
    c.run(f"{runtime} image save {shlex.quote(image_ref)} -o {shlex.quote(str(out_file))}")


@task(
    help={
        "registry": "Registry hostname for image tags",
        "image": "Image name without registry/namespace",
        "containerfile": "Path to the Containerfile",
        "build_args": "Build args to pass to the runtime",
        "skip_if_exists": "Skip the build and only retag if the image exists",
        "version_tag": "Extra version tag applied on main-branch builds",
        "save": "Also export the image to dist/registry as a tar",
    }
)
def build(
    c: Context,
    registry: str = DESTINATION_REGISTRY,
    image: str = "",
    containerfile: str = "Containerfile",
    no_cache: bool = False,
    build_args: dict[str, str] | None = None,
    skip_if_exists: bool = True,
    version_tag: str | None = None,
    save: bool = False,
) -> None:
    """Build a container image with generated tags and labels."""
    runtime = detect_runtime()

    build_args_list = []
    if build_args:
        build_args_list.extend(f"--build-arg {key}={value}" for key, value in build_args.items())

    no_cache_flag = "--no-cache" if no_cache else ""

    tags, labels = generate_metadata(registry, image, version_tag)
    sha_ref = tags[0]

    if skip_if_exists and image_exists(runtime, sha_ref):
        info(f"Image {sha_ref} exists. Retagging additional tags.")
        for ref in tags[1:]:
            c.run(f"{runtime} tag {shlex.quote(sha_ref)} {shlex.quote(ref)}")
        if save:
            _save_image(c, runtime, sha_ref, image)
        return

    cmd_parts = [
        runtime,
        "build",
        "--pull",
        "--file",
        shlex.quote(containerfile),
        *build_args_list,
    ]

    for key, value in labels.items():
        cmd_parts.extend(["--label", f"{key}={value}"])

    for ref in tags:
        cmd_parts.extend(["--tag", shlex.quote(ref)])

    if no_cache_flag:
        cmd_parts.append(no_cache_flag)

    cmd_parts.append(".")

    command = " ".join(cmd_parts)

    with c.cd(BUILD_DIR):
        c.run(command)

    if save:
        _save_image(c, runtime, sha_ref, image)


@task
def build_fedora(c: Context, no_cache: bool = False) -> None:
    """Build the Fedora toolbox image."""
    build(
        c,
        registry=DESTINATION_REGISTRY,
        image="fedora-toolbox",
        containerfile="Containerfile",
        build_args={"FEDORA_VERSION": FEDORA_VERSION},
        no_cache=no_cache,
        skip_if_exists=True,
        version_tag=FEDORA_VERSION,
    )


@task
def build_ubuntu(c: Context, no_cache: bool = False) -> None:
    """Build the Ubuntu toolbox image."""
    build(
        c,
        registry=DESTINATION_REGISTRY,
        image="ubuntu-toolbox",
        containerfile="Containerfile.ubuntu",
        build_args={"UBUNTU_VERSION": UBUNTU_VERSION},
        no_cache=no_cache,
        skip_if_exists=True,
        version_tag=UBUNTU_VERSION,
    )


@task(
    help={
        "image": "Image reference to test (must already exist locally)",
        "verbose": "Show full output of each test case",
        "runtime": "Force podman or docker instead of autodetection",
    }
)
def test(
    c: Context,
    image: str,
    verbose: bool = False,
    runtime: str | None = None,
    no_build: bool = False,
    no_color: bool = False,
) -> None:
    """Run the Bats test suite inside a pre-built image."""
    global USE_COLOR
    USE_COLOR = not no_color

    if "CI" in os.environ:
        USE_COLOR = False

    runtime = detect_runtime(runtime)

    info(f"Using container runtime: {runtime}")

    test_dir = shlex.quote(str(TEST_DIR))
    image_ref = shlex.quote(image)
    verbose_flag = "--verbose-run" if verbose else ""

    image_exists_flag = image_exists(runtime, image)

    if not image_exists_flag:
        raise RuntimeError(f"Image {image} not found. Run the build task before testing.")

    mount_flag = f"{test_dir}:/test:Z" if runtime == "podman" else f"{test_dir}:/test"

    info(f"Running tests in image: {image}")

    cmd_parts = [
        runtime,
        "run",
        "--rm",
        "-v",
        mount_flag,
        image_ref,
        "bats",
    ]

    if verbose_flag:
        cmd_parts.append(verbose_flag)

    cmd_parts.append("/test")

    c.run(" ".join(cmd_parts))


@task
def test_fedora(c: Context, verbose: bool = False) -> None:
    """Test the Fedora image built from the current commit."""
    namespace = IMAGE_NAMESPACE or resolve_namespace(get_git_context()["remote_url"])
    image_ref = f"{DESTINATION_REGISTRY}/{namespace}/fedora-toolbox:{get_commit_sha()}"
    test(
        c,
        image=image_ref,
        verbose=verbose,
    )


@task
def test_ubuntu(c: Context, verbose: bool = False) -> None:
    """Test the Ubuntu image built from the current commit."""
    namespace = IMAGE_NAMESPACE or resolve_namespace(get_git_context()["remote_url"])
    image_ref = f"{DESTINATION_REGISTRY}/{namespace}/ubuntu-toolbox:{get_commit_sha()}"
    test(
        c,
        image=image_ref,
        verbose=verbose,
    )


@task(
    help={
        "image": "Image name without registry/namespace",
        "registry": "Registry hostname to push to",
        "version_tag": "Extra version tag applied on main-branch builds",
    }
)
def push(
    c: Context,
    image: str,
    registry: str = DESTINATION_REGISTRY,
    runtime: str | None = None,
    version_tag: str | None = None,
) -> None:
    """Push all generated tags for an image to the registry."""
    runtime = detect_runtime(runtime)

    tags, _ = generate_metadata(registry, image, version_tag)

    for ref in tags:
        info(f"Pushing {ref}")
        c.run(f"{runtime} push {shlex.quote(ref)}")


@task
def release_fedora(
    c: Context,
    no_cache: bool = False,
    skip_tests: bool = False,
) -> None:
    """Build, test, and push the Fedora image."""
    build_fedora(c, no_cache=no_cache)
    if not skip_tests:
        test_fedora(c)
    push(
        c,
        image="fedora-toolbox",
        registry=DESTINATION_REGISTRY,
        version_tag=FEDORA_VERSION,
    )


@task
def release_ubuntu(
    c: Context,
    no_cache: bool = False,
    skip_tests: bool = False,
) -> None:
    """Build, test, and push the Ubuntu image."""
    build_ubuntu(c, no_cache=no_cache)
    if not skip_tests:
        test_ubuntu(c)
    push(
        c,
        image="ubuntu-toolbox",
        registry=DESTINATION_REGISTRY,
        version_tag=UBUNTU_VERSION,
    )
