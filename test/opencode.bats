#!/usr/bin/env bats

load common.sh

@test "oc alias is in PATH" {
	command -v oc >/dev/null 2>&1 || skip "oc not installed"
	check_path oc
}

@test "oc alias delegates to opencode" {
	command -v oc >/dev/null 2>&1 || skip "oc not installed"
	[ -x "/usr/local/bin/oc" ]
	grep -q "exec opencode" /usr/local/bin/oc
}

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

    # Edit and write default to ask, but allow /tmp
    edit_default=$(echo "$config" | jq -r '.permission.edit["*"]')
    edit_tmp=$(echo "$config" | jq -r '.permission.edit["/tmp/**"]')
    write_default=$(echo "$config" | jq -r '.permission.write["*"]')
    write_tmp=$(echo "$config" | jq -r '.permission.write["/tmp/**"]')

    # Bash defaults to ask with specific allowlists
    bash_default=$(echo "$config" | jq -r '.permission.bash["*"]')
    git_status=$(echo "$config" | jq -r '.permission.bash["git status *"]')
    git_log=$(echo "$config" | jq -r '.permission.bash["git log *"]')
    git_diff=$(echo "$config" | jq -r '.permission.bash["git diff *"]')
    git_show=$(echo "$config" | jq -r '.permission.bash["git show *"]')
    git_branch=$(echo "$config" | jq -r '.permission.bash["git branch *"]')
    git_rev_parse=$(echo "$config" | jq -r '.permission.bash["git rev-parse *"]')

    # Additional bash allowlists
    bash_cat=$(echo "$config" | jq -r '.permission.bash["cat *"]')
    bash_find=$(echo "$config" | jq -r '.permission.bash["find *"]')
    bash_uv=$(echo "$config" | jq -r '.permission.bash["uv *"]')
    bash_make=$(echo "$config" | jq -r '.permission.bash["make *"]')
    bash_sed=$(echo "$config" | jq -r '.permission.bash["sed *"]')
    bash_echo=$(echo "$config" | jq -r '.permission.bash["echo *"]')

    # External directory access for /tmp
    external_tmp=$(echo "$config" | jq -r '.permission.external_directory["/tmp/**"]')

    [ "$edit_default" = "ask" ]
    [ "$edit_tmp" = "allow" ]
    [ "$write_default" = "ask" ]
    [ "$write_tmp" = "allow" ]
    [ "$bash_default" = "ask" ]
    [ "$git_status" = "allow" ]
    [ "$git_log" = "allow" ]
    [ "$git_diff" = "allow" ]
    [ "$git_show" = "allow" ]
    [ "$git_branch" = "allow" ]
    [ "$git_rev_parse" = "allow" ]
    [ "$bash_cat" = "allow" ]
    [ "$bash_find" = "allow" ]
    [ "$bash_uv" = "allow" ]
    [ "$bash_make" = "allow" ]
    [ "$bash_sed" = "allow" ]
    [ "$bash_echo" = "allow" ]
    [ "$external_tmp" = "allow" ]
}
