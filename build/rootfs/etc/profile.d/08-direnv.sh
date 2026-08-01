case "$(basename "$SHELL")" in
	bash)
		eval "$(direnv hook bash)"
		;;
	zsh)
		eval "$(direnv hook zsh)"
		;;
esac
