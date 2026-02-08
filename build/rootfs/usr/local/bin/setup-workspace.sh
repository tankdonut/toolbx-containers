#!/usr/bin/env bash

set -e

USERNAME=""
EMAIL=""
WORKSPACE="${WORKSPACE:-"${HOME}/Development"}"

function usage() {
	echo "usage: $0 -u USERNAME -e EMAIL [-w WORKSPACE]"
	exit 1
}

while getopts ":e:u:w:" o; do
	case "$o" in
	e)
		EMAIL="$OPTARG"
		;;
	u)
		USERNAME="$OPTARG"
		;;
	w)
		WORKSPACE="$OPTARG"
		;;
	*)
		usage
		;;
	esac
done

if [ -z "$USERNAME" ] || [ -z "$EMAIL" ]; then
	usage
fi

mkdir -pv "$WORKSPACE"

# ssh

mkdir -pv "${WORKSPACE}/.ssh"

chmod 0700 "${WORKSPACE}/.ssh"

if [ -f "${WORKSPACE}/.ssh/id_ecdsa" ]; then
	:
else
	ssh-keygen -C "$EMAIL" -t ecdsa -f "${WORKSPACE}/.ssh/id_ecdsa"
	echo "${EMAIL} $(cat "${WORKSPACE}/.ssh/id_ecdsa.pub")" >"${WORKSPACE}/.ssh/allowed_signers"
fi

# git config

function git_config() { git config --file "${WORKSPACE}/.gitconfig" "$@"; }

git_config user.name "$USERNAME"
git_config user.email "$EMAIL"
git_config user.signingkey "${WORKSPACE}/.ssh/id_ecdsa.pub"
git_config commit.gpgsign true
git_config tag.gpgsign true
git_config gpg.format ssh
git_config gpg.ssh.allowedsignersfile "${WORKSPACE}/.ssh/allowed_signers"
git_config core.excludesfile "${WORKSPACE}/.gitignore"
git_config core.sshcommand "/usr/bin/ssh -i ${WORKSPACE}/.ssh/id_ecdsa"
