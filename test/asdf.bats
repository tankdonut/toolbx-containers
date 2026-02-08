#!/usr/bin/env bats

load common.sh

@test "test asdf is in PATH" {
	check_path asdf
}
