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

@test "test node executes" {
	node -e "console.log('ok')"
}
