# npm

# Create user npmrc on first login with secure defaults
if [ -n "${NPM_CONFIG_USERCONFIG:-}" ] && [ ! -f "$NPM_CONFIG_USERCONFIG" ]; then
	mkdir -p "$(dirname "$NPM_CONFIG_USERCONFIG")"
	cat > "$NPM_CONFIG_USERCONFIG" <<-EOF
		min-release-age=7
		ignore-scripts=true
		prefix=${XDG_DATA_HOME}/npm
	EOF
fi
