if [ "$(basename "$SHELL")" = "bash" ]; then
	eval "$(direnv hook bash)"
fi
