#!/usr/bin/env bats

load common.sh

@test "test node is in PATH" {
	check_path node
}

@test "test npm is in PATH" {
	check_path npm
}

@test "test pnpm is in PATH" {
	check_path pnpm
}

@test "test node reports version" {
	run node --version
	[ "$status" -eq 0 ]
}

@test "test node executes" {
	run node -e "console.log('ok')"
	[ "$status" -eq 0 ]
}
