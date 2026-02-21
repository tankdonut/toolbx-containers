from invoke import Context, task

from config import BUILD_DIR, CACHE_DIR


@task
def clean(c: Context) -> None:
    if CACHE_DIR.exists():
        c.run(f"rm -rf {CACHE_DIR}")


@task
def download_fonts(c: Context) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    zip_path = CACHE_DIR / "Meslo.zip"
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Meslo.zip"

    if not zip_path.exists():
        c.run(f"wget -O {zip_path} {url}")


@task
def get_pypi_version(c: Context, package: str) -> None:
    c.run(f"pip index versions {package}")


@task
def node_modules(c: Context, latest: bool = False) -> None:
    args = ["yarn", "install"]

    if latest:
        args.append("--latest")

    with c.cd(BUILD_DIR):
        c.run(" ".join(args))


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
