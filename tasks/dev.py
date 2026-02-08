from pathlib import Path

from invoke import Context, task

from config import BUILD_DIR, CACHE_DIR


@task
def clean(c: Context) -> None:
    c.run(f"find . -name {CACHE_DIR} | xargs rm -rf")


@task
def download_fonts(c: Context) -> None:
    with c.cd(BUILD_DIR):
        if not Path(f"{CACHE_DIR}/Meslo.zip").exists():
            c.run(
                f"wget -P {CACHE_DIR} https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Meslo.zip"
            )


@task
def get_pypi_version(c: Context, package: str) -> None:
    c.run(f"pip index versions {package}")


@task
def node_modules(c: Context, latest: bool = False) -> None:
    with c.cd(BUILD_DIR):
        c.run(f"yarn install {'--latest' if latest else ''}")


@task
def python_packages(c: Context, latest: bool = False) -> None:
    with c.cd(BUILD_DIR):
        c.run("poetry install")
        if latest:
            c.run("poetry update")


@task
def pre_commit(c: Context) -> None:
    c.run("pre-commit run --all")


@task
def submodules(c: Context, update: bool = False) -> None:
    c.run(f"git submodule update --init --recursive {'--remote' if update else ''}")
