#!/usr/bin/env bash

set -e

PLUGINS_FILE="${PLUGINS_FILE:-"/etc/asdf-plugins.txt"}"

if [ -f "$PLUGINS_FILE" ]; then
	mapfile -t ASDF_PLUGINS < <(grep -h -v '^#' "${PLUGINS_FILE}")
else
	ASDF_PLUGINS=()
fi

if type asdf &>/dev/null; then
	for plugin in "${ASDF_PLUGINS[@]}"; do
		asdf plugin add "$plugin"
	done
else
	echo "asdf is not installed"
	exit 1
fi
