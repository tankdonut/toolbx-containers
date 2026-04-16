#!/usr/bin/env bats

load common.sh

@test "test host-spawn is in PATH" {
	command -v host-spawn >/dev/null 2>&1 || skip "host-spawn not installed"
	check_path host-spawn
}

@test "test host-spawn symlinks delegate to host" {
	command -v host-spawn >/dev/null 2>&1 || skip "host-spawn not installed"
	local tools="buildah docker docker-compose flatpak podman podman-compose rpm-ostree"
	for tool in $tools; do
		[ -L "/usr/local/bin/$tool" ]
		run readlink "/usr/local/bin/$tool"
		[ "$output" = "/usr/bin/host-spawn" ]
	done
}
