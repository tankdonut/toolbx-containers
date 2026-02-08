#!/usr/bin/env python

import argparse
import logging
from pathlib import Path
from site import USER_SITE
import sys

logger = logging.getLogger(__name__)

logging.basicConfig(level=logging.INFO)

VENDOR_PYTHON = "/vendor/python/lib/python3.13/site-packages"

parser = argparse.ArgumentParser(description="install /vendor/python")
parser.add_argument(
    "-d", "--dry-run", action="store_true", default=False, help="Do not take any actions"
)
args = parser.parse_args()

vendor_in_path = all(item == VENDOR_PYTHON for item in sys.path)


def write_pth_file(dest_dir: str | Path, dry_run: bool = False) -> None:
    vendor_path = Path(dest_dir) / "vendor.pth"
    logger.info(f"creating .pth file {vendor_path}")
    if not dry_run:
        Path.mkdir(vendor_path.parent, parents=True, exist_ok=True)
        with Path.open(vendor_path, "w") as f:
            f.write(VENDOR_PYTHON)


if not vendor_in_path:
    logger.info(f"{VENDOR_PYTHON} not in sys.path")

    write_pth_file(USER_SITE, args.dry_run)

    for item in sys.path:
        if ".asdf" in item and not item.endswith(".zip") and not item.endswith("lib-dynload"):
            write_pth_file(item, args.dry_run)
