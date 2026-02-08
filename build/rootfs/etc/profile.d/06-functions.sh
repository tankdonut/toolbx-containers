# git-authors displays all all commit authors in the repository
function git-authors() { git log --pretty='%an %ae%n%cn %ce' | sort | uniq; }

# git_merge_hook deletes local tracking branches that are no longer on remote that have been merged with a merge commit
function git-merge-hook() {
	git branch --merged | grep -E -v "(^\*|master|dev|main)" | xargs git branch -d 2>/dev/null
	git fetch -p
}

# git_purge completely removes a file or directory from the repository's history
function git-purge() {
	if [ -d "$1" ]; then
		RECURSIVE="-r"
	fi

	FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --index-filter "git rm ${RECURSIVE} --cached --ignore-unmatch ${1}" --prune-empty --tag-name-filter cat -- --all
}

# git_sync_local_config sets local repository config using global values
function git-sync-local-config() {
	git config user.name "$(git config --get user.name)"
	git config user.email "$(git config --get user.email)"
}
