#!/usr/bin/env bats

@test "OpenCode system config directory exists" {
    [ -d "/etc/opencode" ]
}

@test "OpenCode system config file exists" {
    [ -f "/etc/opencode/opencode.jsonc" ]
}

@test "OpenCode default permissions require confirmation" {
    # Strip // comments because jq does not support JSONC
    config="$(sed 's://.*$::' /etc/opencode/opencode.jsonc)"

    edit_perm=$(echo "$config" | jq -r '.permission.edit')
    write_perm=$(echo "$config" | jq -r '.permission.write')
    bash_perm=$(echo "$config" | jq -r '.permission.bash')

    [ "$edit_perm" = "ask" ]
    [ "$write_perm" = "ask" ]
    [ "$bash_perm" = "ask" ]
}
