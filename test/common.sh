function check_path() {
	for p in "$@"; do
		command -V "$p" >/dev/null
	done
}
