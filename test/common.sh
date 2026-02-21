function check_path() {
	for p in "$@"; do
		command -v "$p" >/dev/null 2>&1 || {
			echo "Command not found in PATH: $p"
			return 1
		}
	done
}
