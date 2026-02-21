function check_path() {
	for p in "$@"; do
		command -v "$p" >/dev/null 2>&1
	done
}
