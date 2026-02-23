#!/usr/bin/env bats

@test "OpenCode system config directory exists" {
    [ -d "/etc/opencode" ]
}

@test "OpenCode system config file exists" {
    [ -f "/etc/opencode/opencode.jsonc" ]
}

@test "OpenCode default permissions require confirmation" {
    # Parse JSONC safely using Node to strip line comments before jq
    config="$(node -e '
        const fs = require("fs");
        const content = fs.readFileSync("/etc/opencode/opencode.jsonc", "utf8");
        const stripped = content.replace(/\/\/.*$/gm, "");
        console.log(stripped);
    ')"

    edit_perm=$(echo "$config" | jq -r '.permission.edit')
    write_perm=$(echo "$config" | jq -r '.permission.write')
    bash_perm=$(echo "$config" | jq -r '.permission.bash')

    [ "$edit_perm" = "ask" ]
    [ "$write_perm" = "ask" ]
    [ "$bash_perm" = "ask" ]
}
