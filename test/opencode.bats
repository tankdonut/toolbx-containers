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
