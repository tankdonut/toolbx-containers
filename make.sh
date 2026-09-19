#!/usr/bin/env bash
#
# make.sh is the entry point for toolbx-containers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTROBOX_INI="${SCRIPT_DIR}/distrobox.ini"

function usage() {
	cat <<EOF
Usage: make.sh <command>

Commands:
  distrobox    Create the containers defined in distrobox.ini (recreating
               any that already exist)
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

command="${1:-}"
if [ $# -gt 0 ]; then
	shift
fi

case "${command}" in
	distrobox)
		cmd_distrobox "$@"
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
