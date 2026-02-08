#!/usr/bin/env bash

set -e

FORCE=false
PROFILE="main"
WORKSPACE="${WORKSPACE:-"${HOME}/Development"}"

function usage() {
	echo "usage: $0 -r REPO [-f] [-t TEMPLATE_REPO] [-w WORKSPACE] [-p PROFILE]"
}

while getopts "fp:r:t:w:" opt; do
	case "$opt" in
	f)
		FORCE=true
		;;
	p)
		PROFILE="$OPTARG"
		;;
	r)
		REPO="$OPTARG"
		;;
	t)
		TEMPLATE_REPO="$OPTARG"
		;;
	w)
		WORKSPACE="$OPTARG"
		;;
	*)
		usage
		;;
	esac
done

if [ -z "$REPO" ]; then
	usage
	exit 1
fi

codium --install-extension zokugun.sync-settings

[ "$FORCE" ] && rm -rvf "${WORKSPACE}/settings"

if [ ! -d "${WORKSPACE}/settings/.git" ]; then
	if [ -x "$TEMPLATE_REPO" ]; then
		git clone "$TEMPLATE_REPO" "${WORKSPACE}/settings"
		rm -rf "${WORKSPACE}/settings/.git"
		(
			cd "${WORKSPACE}/settings"
			git init
			git add -A
			git commit -m "initial commit"
			git remote add origin "$REPO"
			git push -u origin main
		)
	fi
fi

cat >"${HOME}/.config/VSCodium/User/globalStorage/zokugun.sync-settings/settings.yml" <<EOT
profile: ${PROFILE}
repository:
  type: git
  url: $REPO
  branch: main
EOT
