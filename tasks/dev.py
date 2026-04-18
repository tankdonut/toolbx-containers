from invoke import Context, task

from config import CACHE_DIR


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
def pre_commit(c: Context) -> None:
    c.run("pre-commit run --all")


@task
def submodules(c: Context, update: bool = False) -> None:
    c.run(f"git submodule update --init --recursive {'--remote' if update else ''}")
