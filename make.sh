#!/usr/bin/env bash
#
# make.sh is the entry point for toolbx-containers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTROBOX_INI="${SCRIPT_DIR}/distrobox.ini"
CACHE_DIR="${SCRIPT_DIR}/cache"
MESLO_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Meslo.zip"

function usage() {
	cat <<EOF
Usage: make.sh <command>

Commands:
  clean           Remove the cache directory
  distrobox       Create the containers defined in distrobox.ini (recreating
                  any that already exist)
  download-fonts  Download Meslo Nerd Fonts into the cache directory
  pre-commit      Run all pre-commit hooks across the repository
  submodules      Initialize and update git submodules; pass --update to pull
                  the latest remote commits instead of the pinned ones
EOF
}

function require_distrobox() {
	if ! command -v distrobox >/dev/null 2>&1; then
		echo "error: distrobox not found in PATH. Install it from https://github.com/89luca89/distrobox" >&2
		exit 1
	fi
}

function cmd_distrobox() {
	require_distrobox
	distrobox assemble create --replace --file "${DISTROBOX_INI}"
}

function cmd_clean() {
	rm -rf "${CACHE_DIR}"
}

function cmd_download_fonts() {
	mkdir -p "${CACHE_DIR}"
	if [[ ! -f "${CACHE_DIR}/Meslo.zip" ]]; then
		wget -O "${CACHE_DIR}/Meslo.zip" "${MESLO_URL}"
	fi
}

function cmd_pre_commit() {
	uv run pre-commit run --all
}

function cmd_submodules() {
	if [[ "${1:-}" == "--update" ]]; then
		git submodule update --init --recursive --remote
	else
		git submodule update --init --recursive
	fi
}

command="${1:-}"
if [ $# -gt 0 ]; then
	shift
fi

case "${command}" in
	clean)
		cmd_clean
		;;
	distrobox)
		cmd_distrobox "$@"
		;;
	download-fonts)
		cmd_download_fonts
		;;
	pre-commit)
		cmd_pre_commit
		;;
	submodules)
		cmd_submodules "$@"
		;;
	help | -h | --help)
		usage
		;;
	"")
		usage >&2
		exit 1
		;;
	*)
		echo "error: unknown command: ${command}" >&2
		usage >&2
		exit 1
		;;
esac
