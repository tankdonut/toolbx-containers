#!/usr/bin/env bats

@test "OPENCODE_CONFIG is set correctly" {
    [ "$OPENCODE_CONFIG" = "/etc/opencode" ]
}

@test "OpenCode system config directory exists" {
    [ -d "/etc/opencode" ]
}

@test "OpenCode system config file exists" {
    [ -f "/etc/opencode/opencode.jsonc" ]
}

@test "OpenCode default permissions require confirmation" {
    run opencode config dump
    [ "$status" -eq 0 ]

    edit_perm=$(echo "$output" | jq -r '.permission.edit')
    write_perm=$(echo "$output" | jq -r '.permission.write')
    bash_perm=$(echo "$output" | jq -r '.permission.bash')

    [ "$edit_perm" = "ask" ]
    [ "$write_perm" = "ask" ]
    [ "$bash_perm" = "ask" ]
}
