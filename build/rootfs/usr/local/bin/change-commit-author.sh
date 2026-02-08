#!/usr/bin/env bash

set -e

function usage() {
	echo "usage: $0 [-f] -e WRONG_EMAIL [-n NEW_NAME] [-m NEW_EMAIL]"
	exit 1
}

declare -a ARGS=()

while getopts "e:fm:n:" opt; do
	case "$opt" in
	e)
		WRONG_EMAIL="$OPTARG"
		;;
	f)
		ARGS+=("--force")
		;;
	n)
		NEW_NAME="$OPTARG"
		;;
	m)
		NEW_EMAIL="$OPTARG"
		;;
	*)
		usage
		;;
	esac
done

if [ -z "$NEW_NAME" ]; then
	NEW_NAME="$(git config user.name)"
fi

if [ -z "$NEW_EMAIL" ]; then
	NEW_EMAIL="$(git config user.email)"
fi

if [ -z "$WRONG_EMAIL" ] || [ -z "$NEW_NAME" ] || [ -z "$NEW_EMAIL" ]; then
	usage
fi

echo "NEW_NAME: ${NEW_NAME}"
echo "NEW_EMAIL: ${NEW_EMAIL}"
echo "WRONG_EMAIL: ${WRONG_EMAIL}"

read -r -p "Do you want to proceed? (y/n) " yn

case $yn in
	[Yy]*) echo "Proceeding...";;
	[Nn]*) echo "Exiting..."; exit;;
	*) echo "Invalid response"; exit 1;;
esac

FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch "${ARGS[@]}" --env-filter "
if [ \"\$GIT_COMMITTER_EMAIL\" = \"$WRONG_EMAIL\" ]
then
    export GIT_COMMITTER_NAME=\"$NEW_NAME\"
    export GIT_COMMITTER_EMAIL=\"$NEW_EMAIL\"
fi
if [ \"\$GIT_AUTHOR_EMAIL\" = \"$WRONG_EMAIL\" ]
then
    export GIT_AUTHOR_NAME=\"$NEW_NAME\"
    export GIT_AUTHOR_EMAIL=\"$NEW_EMAIL\"
fi
" --tag-name-filter cat -- --branches --tags
