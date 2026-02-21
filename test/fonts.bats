#!/usr/bin/env bats

load common.sh

@test "test font packages are in PATH" {
	check_path fc-list fc-cache
}

@test "test Meslo fonts are installed" {
	run fc-list
	[ "$status" -eq 0 ]
	echo "$output" | grep -qi "Meslo"
}
