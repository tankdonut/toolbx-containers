#!/usr/bin/env bash

set -e

if [ "$DEBUG" = "true" ]; then
	set -x
fi

#
# global variables
#

# CLEANUP_DIRS contains all directories to try to clean, relative to $HOME
declare -a CLEANUP_DIRS=(
	".ansible"
	".bundle"
	".cache/go-build"
	".cache/hardhat-nodejs"
	".cache/helm"
	".cache/mesa_shader_cache"
	".cache/nvidia"
	".cache/pip"
	".cache/pre-commit"
	".cache/pyopencl"
	".cache/typescript"
	".cache/yarn"
	".cache/Yubico"
	".config/doctl"
	".config/gatsby"
	".config/packer"
	".cookiecutters"
	".cookiecutter_replay"
	".gushio"
	".java"
	".nv"
	".packer.d"
	".rest-client"
	".subversion"
	".terraform.d"
)

# CLEANUP_FILES contains all files to try to clean, relative to $HOME
declare -a CLEANUP_FILES=(
	".docker/config.json"
	".geodesic/history"
	".lesshst"
	".python_history"
	".sqlite_history"
	".viminfo"
	".wget-hsts"
)

#
# functions
#

function _is_in_path() {
	type "$1" &>/dev/null
}

function _delete_dir() {
	if [ -d "$1" ]; then
		if _is_in_path bleachbit; then
			bleachbit --shred "$1"
		else
			find "$1" -type f -print -exec shred -u {} \;
			rm -rvf "$1"
		fi
	else
		echo "${1} is not a directory or does not exist. skipping..."
	fi
}

function _delete_file() {
	if [ -f "$1" ]; then
		shred -uvf "$1"
	else
		echo "${1} is not a file or does not exist. skipping..."
	fi
}

function _delete_glob() {
	if compgen -G "$1" >/dev/null; then
		rm -rf "$1"
	else
		echo "${1} does not match any files or directories. skipping..."
	fi
}

#
# shell history and cache
#

# bash
_delete_file "${HOME}/.bash_history"

# zsh
_delete_glob "${HOME}/.zsh_history*"
_delete_glob "${HOME}/.zcompdump*"
_delete_glob "${HOME}/.cache/*.zsh.zwc"
_delete_glob "${HOME}/.cache/*.zsh"

#
# image thumbnails
#

if [ -d "${HOME}/.cache" ]; then
	find "${HOME}/.cache" \( -name "*.png" -o -name "*.jpg" \) -exec shred -vu {} \;
fi

#
# file system database
#

if _is_in_path tracker3; then
	tracker3 reset --filesystem --rss
fi

#
# containers
#

if _is_in_path podman; then
	podman container prune -f
	podman image prune -af
else
	echo "podman is not installed. skipping..."
fi

if _is_in_path docker; then
	if [ -S "/var/run/docker.sock" ]; then
		docker container prune -f
		docker image prune -af
	fi
else
	echo "docker is not installed. skipping..."
fi

if _is_in_path flatpak; then
	# uninstall unused flatpak runtimes
	flatpak uninstall --unused --assumeyes --verbose >/dev/null

	# reset permissions
	for fp in $(flatpak list --user --columns=application | sed 1d); do
		flatpak permission-reset --verbose "$fp"
	done
else
	echo "flatpak is not installed. skipping..."
fi

#
# package managers
#

if _is_in_path npm; then
	npm cache clean --force
fi

if _is_in_path brew; then
	brew cleanup
fi

for f in "${CLEANUP_FILES[@]}"; do
	_delete_file "${HOME}/${f}"
done

for d in "${CLEANUP_DIRS[@]}"; do
	_delete_dir "${HOME}/${d}"
done

if _is_in_path bleachbit; then
	bleachbit --clean --all-but-warning
fi

exit 0
