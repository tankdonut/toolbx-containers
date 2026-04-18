#!/usr/bin/env bats

load common.sh

@test "test chromium-browser is in PATH" {
	check_path chromium-browser
}

@test "test chromium-browser reports version" {
	run chromium-browser --version
	[ "$status" -eq 0 ]
}

@test "test /usr/bin/chromium symlink exists for Playwright" {
	[ -L /usr/bin/chromium ]
	run readlink /usr/bin/chromium
	[ "$output" = "/usr/bin/chromium-browser" ]
}

@test "test /opt/google/chrome/chrome symlink exists for Playwright" {
	[ -L /opt/google/chrome/chrome ]
	run readlink /opt/google/chrome/chrome
	[ "$output" = "/usr/bin/chromium-browser" ]
}

@test "test playwright is in PATH" {
	check_path playwright
}

@test "test playwright reports version" {
	run playwright --version
	[ "$status" -eq 0 ]
}
