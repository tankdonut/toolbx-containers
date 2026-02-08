# ruff: noqa: PT028
import os
from pathlib import Path
import subprocess

from dotenv import load_dotenv
from invoke import Context, task

from config import BUILD_DIR, DIST_DIR, TEST_DIR

load_dotenv()

FEDORA_VERSION = os.getenv("FEDORA_VERSION", "41")
UBUNTU_VERSION = os.getenv("UBUNTU_VERSION", "24.04")
DESTINATION_REGISTRY = os.getenv("DESTINATION_REGISTRY", "localhost")
TOOLS_REGISTRY = os.getenv("TOOLS_REGISTRY", "localhost")

COMMIT_SHA = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()


@task
def build(
    c: Context,
    registry: str,
    image: str,
    containerfile: str,
    tag: str = COMMIT_SHA,
    no_cache: bool = False,
    build_args: dict[str, str] | None = None,
) -> None:
    args_string = f"--build-arg TOOLS_REGISTRY={TOOLS_REGISTRY} "

    if build_args:
        args_string += " ".join(f"--build-arg {key}={value}" for key, value in build_args.items())

    no_cache_str = "--no-cache" if no_cache else ""

    with c.cd(BUILD_DIR):
        c.run(f"""
            podman build --pull --file {containerfile} {args_string} {no_cache_str} \
                --tag {registry}/{image}:{tag}
            """)


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
def test(c: Context, image: str, verbose: bool = False) -> None:
    c.run(f"""
    podman run --rm -v {TEST_DIR}:/test:z {image} \
        bats {"--verbose-run" if verbose else ""} /test
    """)


@task
def test_fedora(c: Context, verbose: bool = False) -> None:
    test(c, image=f"localhost/fedora-toolbox:{COMMIT_SHA}", verbose=verbose)


@task
def test_ubuntu(c: Context, verbose: bool = False) -> None:
    test(c, image=f"localhost/ubuntu-toolbox:{COMMIT_SHA}", verbose=verbose)


@task
def save(c: Context, image: str, tag: str, localhost: bool = False, force: bool = True) -> None:
    registry = "localhost" if localhost else DESTINATION_REGISTRY
    out_file = Path(f"{DIST_DIR}/registry/{image}-{tag}.tar")

    if force:
        c.run(f"rm -rfv {out_file}")

    c.run(f"mkdir -p {Path(out_file).parent}")
    c.run(f"podman image save {registry}/{image}:{tag} -o {out_file}")


@task
def save_fedora(c: Context, localhost: bool = False) -> None:
    save(c, image="fedora-toolbox", tag=FEDORA_VERSION, localhost=localhost)


@task
def save_ubuntu(c: Context, localhost: bool = False) -> None:
    save(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION, localhost=localhost)


@task
def tag(c: Context, image: str, tag: str, localhost: bool = False) -> None:
    registry = "localhost" if localhost else DESTINATION_REGISTRY
    c.run(f"podman tag localhost/{image}:{COMMIT_SHA} {registry}/{image}:{tag}")


@task
def tag_fedora(c: Context, localhost: bool = False) -> None:
    tag(c, image="fedora-toolbox", tag=FEDORA_VERSION, localhost=localhost)


@task
def tag_ubuntu(c: Context, localhost: bool = False) -> None:
    tag(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION, localhost=localhost)


@task
def push(c: Context, image: str, tag: str, registry: str = DESTINATION_REGISTRY) -> None:
    c.run(f"podman push {registry}/{image}:{tag}")


@task
def push_fedora(c: Context) -> None:
    push(c, image="fedora-toolbox", tag=FEDORA_VERSION)


@task
def push_ubuntu(c: Context) -> None:
    push(c, image="ubuntu-toolbox", tag=UBUNTU_VERSION)


@task
def create_toolbox(c: Context, image: str, registry: str, tag: str = COMMIT_SHA) -> None:
    toolbox_container_name = f"{image}-{tag}"
    c.run(f"podman stop {toolbox_container_name} || true")
    c.run(f"toolbox rm {toolbox_container_name} || true")
    c.run(f"toolbox create -i {registry}/{image}:{tag}")


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
        save_fedora,
        tag_fedora,
    ]
)
def fedora(c: Context, push: bool = False) -> None:
    if push:
        push_fedora(c)


@task(
    pre=[
        build_ubuntu,
        test_ubuntu,
        save_ubuntu,
        tag_ubuntu,
    ]
)
def ubuntu(c: Context, push: bool = False) -> None:
    if push:
        push_ubuntu(c)
