# NOTE: see https://wiki.archlinux.org/title/XDG_Base_Directory for how to
#       configure applications to use XDG Base Directory

# default PATH

export PATH="${HOME}/bin:/usr/local/bin:${PATH}"

# default EDITOR

if command -v vim &>/dev/null; then
	EDITOR="vim"
else
	EDITOR="vi"
fi

export EDITOR

# shell

# Determine the shell executing this profile safely
if [ -n "$BASH_VERSION" ]; then
	SHELL="$(command -v bash)"
elif [ -n "$ZSH_VERSION" ]; then
	SHELL="$(command -v zsh)"
else
	# Fallback to the actual process executable
	if [ -r "/proc/$$/exe" ]; then
		SHELL="$(readlink -f /proc/$$/exe 2>/dev/null || true)"
	fi
	: "${SHELL:=/bin/sh}"
fi

export SHELL

# asdf

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-"${XDG_DATA_HOME}/asdf"}"
export ASDF_CONFIG_FILE="${ASDF_CONFIG_FILE:-"${XDG_CONFIG_HOME}/asdf/asdfrc"}"

PATH="${ASDF_DATA_DIR}/shims:${PATH}"

export PATH

# aws

AWS_DATA_PATH="${AWS_DATA_PATH:-"${XDG_CONFIG_HOME}"}/aws"
AWS_CONFIG_FILE="${AWS_DATA_PATH}/config"
AWS_SHARED_CREDENTIALS_FILE="${AWS_DATA_PATH}/credentials"
AWS_DEFAULT_REGION="us-east-2"
AWS_DEFAULT_OUTPUT="json"

export AWS_DATA_PATH AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE AWS_DEFAULT_REGION AWS_DEFAULT_OUTPUT

# golang

GOPATH="${GOPATH:-"${XDG_DATA_HOME}/go"}"
GOMODCACHE="${GOMODCACHE:-"${XDG_CACHE_HOME}/go/mod"}"

if [ -d "${GOPATH}/bin" ]; then
	PATH="${GOPATH}/bin:${PATH}"
fi

export GOPATH GOMODCACHE PATH

# kubernetes

KUBECONFIG="${XDG_CONFIG_HOME}/kube"
KUBECACHEDIR="${XDG_CACHE_HOME}/kube"

export KUBECONFIG KUBECACHEDIR

# nodejs

NODE_REPL_HISTORY="$XDG_DATA_HOME"/node_repl_history

export NODE_REPL_HISTORY

# npm

NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"

export NPM_CONFIG_USERCONFIG

# opencode

OPENCODE_CONFIG="/etc/opencode/opencode.jsonc"

export OPENCODE_CONFIG

# python

PYTHON_HISTORY="/dev/null"

export PYTHON_HISTORY

# rust

CARGO_HOME="${XDG_DATA_HOME}/cargo"

if [ -d "$CARGO_HOME" ]; then
	PATH="${CARGO_HOME}/bin:${PATH}"
fi

export CARGO_HOME PATH

# workspace

if [ -d "$WORKSPACE" ]; then
	:
elif [ -d "${HOME}/Development" ]; then
	WORKSPACE="${HOME}/Development"
elif [ -d "${HOME}/workspaces" ]; then
	WORKSPACE="${HOME}/workspaces"
fi

export WORKSPACE

# zsh

# change location of dotfiles
ZDOTDIR="$HOME/.config/zsh"

export ZDOTDIR
