# ruff: noqa: PT028
import os
from pathlib import Path
import shlex
import subprocess

from dotenv import load_dotenv
from invoke import Context, task

from config import BUILD_DIR, DIST_DIR, TEST_DIR


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


load_dotenv()

FEDORA_VERSION = os.getenv("FEDORA_VERSION", "43")
UBUNTU_VERSION = os.getenv("UBUNTU_VERSION", "24.04")
DESTINATION_REGISTRY = os.getenv("DESTINATION_REGISTRY", "localhost")
TOOLS_REGISTRY = os.getenv("TOOLS_REGISTRY", "localhost")


USE_COLOR = True


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


@task
def build(
    c: Context,
    registry: str,
    image: str,
    containerfile: str,
    tag: str | None = None,
    no_cache: bool = False,
    build_args: dict[str, str] | None = None,
) -> None:
    if tag is None:
        tag = get_commit_sha()
    build_args_list = [f"--build-arg TOOLS_REGISTRY={TOOLS_REGISTRY}"]

    if build_args:
        build_args_list.extend(f"--build-arg {key}={value}" for key, value in build_args.items())

    no_cache_flag = "--no-cache" if no_cache else ""

    image_ref = f"{registry}/{image}:{tag}"

    cmd_parts = [
        "podman",
        "build",
        "--pull",
        "--file",
        shlex.quote(containerfile),
        *build_args_list,
    ]

    if no_cache_flag:
        cmd_parts.append(no_cache_flag)

    cmd_parts.extend(["--tag", shlex.quote(image_ref), "."])

    command = " ".join(cmd_parts)

    with c.cd(BUILD_DIR):
        c.run(command)


@task
def build_fedora(c: Context, no_cache: bool = False) -> None:
    build(
        c,
        registry="localhost",
        image="fedora-toolbox",
        containerfile="Containerfile",
        build_args={"FEDORA_VERSION": FEDORA_VERSION},
        no_cache=no_cache,
    )


@task
def build_ubuntu(c: Context, no_cache: bool = False) -> None:
    build(
        c,
        registry="localhost",
        image="ubuntu-toolbox",
        containerfile="Containerfile.ubuntu",
        build_args={"UBUNTU_VERSION": UBUNTU_VERSION},
        no_cache=no_cache,
    )


@task
def test(
    c: Context,
    image: str,
    verbose: bool = False,
    runtime: str | None = None,
    no_build: bool = False,
    no_color: bool = False,
) -> None:
    """
    Build image (if SHA-tagged image missing) and run Bats inside container.
    Supports podman (default) with docker fallback.
    """

    global USE_COLOR
    USE_COLOR = not no_color

    if "CI" in os.environ:
        USE_COLOR = False

    # Determine runtime
    if runtime is None:
        for candidate in ["podman", "docker"]:
            if (
                subprocess.run(
                    ["which", candidate],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                ).returncode
                == 0
            ):
                runtime = candidate
                break
    else:
        if (
            subprocess.run(
                ["which", runtime],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            != 0
        ):
            raise RuntimeError(f"Requested runtime '{runtime}' not found.")

    if runtime is None:
        raise RuntimeError("Neither podman nor docker found on system.")

    info(f"Using container runtime: {runtime}")

    test_dir = shlex.quote(str(TEST_DIR))
    image_ref = shlex.quote(image)
    verbose_flag = "--verbose-run" if verbose else ""

    # Check if exact tagged image exists
    image_exists = (
        subprocess.run(
            [runtime, "image", "inspect", image],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )

    if not image_exists:
        if no_build:
            raise RuntimeError(f"Image {image} not found and --no-build specified.")

        warn_msg(f"Image {image} not found. Building with {runtime}...")

        containerfile = "Containerfile"
        if "ubuntu" in image:
            containerfile = "Containerfile.ubuntu"

        build_cmd = f"{runtime} build --pull --file {containerfile} --tag {image} ."

        with c.cd(BUILD_DIR):
            c.run(build_cmd)

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
    test(c, image=f"localhost/fedora-toolbox:{get_commit_sha()}", verbose=verbose)


@task
def test_ubuntu(c: Context, verbose: bool = False) -> None:
    test(c, image=f"localhost/ubuntu-toolbox:{get_commit_sha()}", verbose=verbose)


@task
def save(
    c: Context,
    image: str,
    tag: str,
    localhost: bool = False,
    force: bool = True,
    runtime: str | None = None,
) -> None:
    runtime = detect_runtime(runtime)

    registry = "localhost" if localhost else DESTINATION_REGISTRY
    out_file = Path(DIST_DIR) / "registry" / f"{image}-{tag}.tar"

    if force and out_file.exists():
        out_file.unlink()

    out_file.parent.mkdir(parents=True, exist_ok=True)

    image_ref = f"{registry}/{image}:{tag}"
    c.run(f"{runtime} image save {shlex.quote(image_ref)} -o {shlex.quote(str(out_file))}")


@task
def save_fedora(c: Context, localhost: bool = False) -> None:
    save(c, image="fedora-toolbox", tag=FEDORA_VERSION, localhost=localhost)


@task
def save_ubuntu(c: Context, localhost: bool = False) -> None:
    save(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION, localhost=localhost)


@task
def tag(
    c: Context,
    image: str,
    tag: str,
    localhost: bool = False,
    runtime: str | None = None,
) -> None:
    runtime = detect_runtime(runtime)

    registry = "localhost" if localhost else DESTINATION_REGISTRY
    source = f"localhost/{image}:{get_commit_sha()}"
    destination = f"{registry}/{image}:{tag}"

    c.run(f"{runtime} tag {shlex.quote(source)} {shlex.quote(destination)}")


@task
def tag_fedora(c: Context, localhost: bool = False) -> None:
    tag(c, image="fedora-toolbox", tag=FEDORA_VERSION, localhost=localhost)


@task
def tag_ubuntu(c: Context, localhost: bool = False) -> None:
    tag(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION, localhost=localhost)


@task
def push(
    c: Context,
    image: str,
    tag: str,
    registry: str = DESTINATION_REGISTRY,
    runtime: str | None = None,
) -> None:
    runtime = detect_runtime(runtime)
    c.run(f"{runtime} push {registry}/{image}:{tag}")


@task
def push_fedora(c: Context) -> None:
    push(c, image="fedora-toolbox", tag=FEDORA_VERSION)


@task
def push_ubuntu(c: Context) -> None:
    push(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION)


@task
def create_toolbox(c: Context, image: str, registry: str, tag: str | None = None) -> None:
    if tag is None:
        tag = get_commit_sha()

    toolbox_container_name = f"{image}-{tag}"
    c.run(f"toolbox rm -f {shlex.quote(toolbox_container_name)}", warn=True)
    image_ref = f"{registry}/{image}:{tag}"
    c.run(f"toolbox create -i {shlex.quote(image_ref)}")


@task
def create_fedora_toolbox(c: Context, registry: str = DESTINATION_REGISTRY) -> None:
    create_toolbox(c, image="fedora-toolbox", registry=registry, tag=FEDORA_VERSION)


@task
def create_ubuntu_toolbox(c: Context, registry: str = DESTINATION_REGISTRY) -> None:
    create_toolbox(c, image="ubuntu-toolbox", registry=registry, tag=UBUNTU_VERSION)


@task(
    pre=[
        build_fedora,
        test_fedora,
        tag_fedora,
        save_fedora,
    ]
)
def fedora(c: Context, push: bool = False) -> None:
    if push:
        push_fedora(c)


@task(
    pre=[
        build_ubuntu,
        test_ubuntu,
        tag_ubuntu,
        save_ubuntu,
    ]
)
def ubuntu(c: Context, push: bool = False) -> None:
    if push:
        push_ubuntu(c)
