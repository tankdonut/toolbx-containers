#!/usr/bin/env bats

@test "OpenCode system config directory exists" {
    [ -d "/etc/opencode" ]
}

@test "OpenCode system config file exists" {
    [ -f "/etc/opencode/opencode.jsonc" ]
}

@test "OpenCode config is valid JSONC" {
    run node -e '
        const fs = require("fs");
        const content = fs.readFileSync("/etc/opencode/opencode.jsonc", "utf8");
        // Evaluate as JS object literal to allow JSONC comments
        Function("return " + content)();
    '

    [ "$status" -eq 0 ]
}

@test "OpenCode default permissions require confirmation" {
    # Parse JSONC safely by evaluating it as a JS object literal in Node
    config="$(node -e '
        const fs = require("fs");
        const content = fs.readFileSync("/etc/opencode/opencode.jsonc", "utf8");
        const parsed = Function("return " + content)();
        console.log(JSON.stringify(parsed));
    ')"

    edit_perm=$(echo "$config" | jq -r '.permission.edit')
    write_perm=$(echo "$config" | jq -r '.permission.write')
    bash_default=$(echo "$config" | jq -r '.permission.bash["*"]')
    git_status=$(echo "$config" | jq -r '.permission.bash["git status"]')
    git_log=$(echo "$config" | jq -r '.permission.bash["git log"]')
    git_diff=$(echo "$config" | jq -r '.permission.bash["git diff"]')
    git_show=$(echo "$config" | jq -r '.permission.bash["git show"]')
    git_branch=$(echo "$config" | jq -r '.permission.bash["git branch"]')
    git_rev_parse=$(echo "$config" | jq -r '.permission.bash["git rev-parse"]')

    [ "$edit_perm" = "ask" ]
    [ "$write_perm" = "ask" ]
    [ "$bash_default" = "ask" ]
    [ "$git_status" = "allow" ]
    [ "$git_log" = "allow" ]
    [ "$git_diff" = "allow" ]
    [ "$git_show" = "allow" ]
    [ "$git_branch" = "allow" ]
    [ "$git_rev_parse" = "allow" ]
}
