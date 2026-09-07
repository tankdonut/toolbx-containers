import shutil

from invoke import Context, task

from config import ROOT_DIR

DISTROBOX_INI = ROOT_DIR / "distrobox.ini"


def require_distrobox() -> None:
    if not shutil.which("distrobox"):
        raise RuntimeError(
            "distrobox not found on system. Install it from "
            "https://github.com/89luca89/distrobox and retry."
        )


@task(help={"replace": "Recreate containers that already exist"})
def create(c: Context, replace: bool = False) -> None:
    """Create the containers defined in distrobox.ini."""
    require_distrobox()
    cmd = f"distrobox assemble create --file {DISTROBOX_INI}"
    if replace:
        cmd += " --replace"
    c.run(cmd)


@task
def upgrade(c: Context) -> None:
    """Upgrade packages inside the distrobox.ini containers (dnf/apt)."""
    require_distrobox()
    c.run("distrobox upgrade --all")


@task
def rm(c: Context) -> None:
    """Remove the containers defined in distrobox.ini."""
    require_distrobox()
    c.run(f"distrobox assemble rm --file {DISTROBOX_INI}")
