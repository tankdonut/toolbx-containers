export SSH_AGENT_ENV="${HOME}/.ssh/agent-environment"

function start_ssh_agent() {
	mkdir -pv "$(dirname "$SSH_AGENT_ENV")"
	ssh-agent | sed 's/^echo/#echo/' >"${SSH_AGENT_ENV}"
	chmod 0600 "$SSH_AGENT_ENV"
	# shellcheck disable=SC1090
	. "$SSH_AGENT_ENV" >/dev/null

	for d in "${HOME}/.ssh" "${WORKSPACE}/.ssh"; do
		grep -slR "PRIVATE" "$d" | xargs ssh-add
	done
}

if [ -f "$SSH_AGENT_ENV" ]; then
	# shellcheck disable=SC1090
	. "$SSH_AGENT_ENV" >/dev/null
	ps -p "$SSH_AGENT_PID" >/dev/null || {
		start_ssh_agent
	}
else
	start_ssh_agent
fi
