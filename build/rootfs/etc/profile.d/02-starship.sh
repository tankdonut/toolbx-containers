if [ "$(basename "$SHELL")" = "bash" ]; then
	export STARSHIP_CONFIG="${STARSHIP_CONFIG:-"/etc/starship/config.toml"}"
	eval "$(starship init "$(basename "$SHELL")")"
fi
