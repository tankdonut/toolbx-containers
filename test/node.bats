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

@test "test bun is in PATH" {
	check_path bun
}

@test "test bun reports version" {
	run bun --version
	[ "$status" -eq 0 ]
}

@test "test bunx is in PATH" {
	check_path bunx
}
