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

@test "OpenCode baseline permissions are configured" {
    # Parse JSONC safely by evaluating it as a JS object literal in Node
    config="$(node -e '
        const fs = require("fs");
        const content = fs.readFileSync("/etc/opencode/opencode.jsonc", "utf8");
        const parsed = Function("return " + content)();
        console.log(JSON.stringify(parsed));
    ')"

    # --- bash defaults to ask ---
    bash_default=$(echo "$config" | jq -r '.permission.bash["*"]')
    [ "$bash_default" = "ask" ]

    # --- read-only bash allowlist (representative samples) ---
    git_status=$(echo "$config" | jq -r '.permission.bash["git status *"]')
    git_log=$(echo "$config" | jq -r '.permission.bash["git log *"]')
    git_diff=$(echo "$config" | jq -r '.permission.bash["git diff *"]')
    git_show=$(echo "$config" | jq -r '.permission.bash["git show *"]')
    git_rev_parse=$(echo "$config" | jq -r '.permission.bash["git rev-parse *"]')
    bash_cat=$(echo "$config" | jq -r '.permission.bash["cat *"]')
    bash_find=$(echo "$config" | jq -r '.permission.bash["find *"]')
    bash_uv=$(echo "$config" | jq -r '.permission.bash["uv *"]')
    bash_make=$(echo "$config" | jq -r '.permission.bash["make *"]')
    bash_sed=$(echo "$config" | jq -r '.permission.bash["sed *"]')
    bash_echo=$(echo "$config" | jq -r '.permission.bash["echo *"]')
    [ "$git_status" = "allow" ]
    [ "$git_log" = "allow" ]
    [ "$git_diff" = "allow" ]
    [ "$git_show" = "allow" ]
    [ "$git_rev_parse" = "allow" ]
    [ "$bash_cat" = "allow" ]
    [ "$bash_find" = "allow" ]
    [ "$bash_uv" = "allow" ]
    [ "$bash_make" = "allow" ]
    [ "$bash_sed" = "allow" ]
    [ "$bash_echo" = "allow" ]

    # --- strict git: list/show only, mutating subcommands fall through to ask ---
    git_branch_list=$(echo "$config" | jq -r '.permission.bash["git branch"]')
    git_branch_broad=$(echo "$config" | jq -r '.permission.bash["git branch *"]')
    git_tag_list=$(echo "$config" | jq -r '.permission.bash["git tag"]')
    git_tag_broad=$(echo "$config" | jq -r '.permission.bash["git tag *"]')
    git_config_get=$(echo "$config" | jq -r '.permission.bash["git config --get*"]')
    sed_inplace=$(echo "$config" | jq -r '.permission.bash["sed -i*"]')
    [ "$git_branch_list" = "allow" ]
    [ "$git_branch_broad" = "null" ]
    [ "$git_tag_list" = "allow" ]
    [ "$git_tag_broad" = "null" ]
    [ "$git_config_get" = "allow" ]
    [ "$sed_inplace" = "ask" ]

    # --- catastrophic bash denies (defense in depth) ---
    [ "$(echo "$config" | jq -r '.permission.bash["rm -rf /*"]')" = "deny" ]
    [ "$(echo "$config" | jq -r '.permission.bash["dd * of=/dev/*"]')" = "deny" ]
    [ "$(echo "$config" | jq -r '.permission.bash["mkfs* *"]')" = "deny" ]

    # --- edit defaults + secret deny-list ---
    edit_default=$(echo "$config" | jq -r '.permission.edit["*"]')
    edit_tmp=$(echo "$config" | jq -r '.permission.edit["/tmp/**"]')
    edit_vartmp=$(echo "$config" | jq -r '.permission.edit["/var/tmp/**"]')
    edit_env=$(echo "$config" | jq -r '.permission.edit["**/.env"]')
    edit_env_example=$(echo "$config" | jq -r '.permission.edit["**/.env.example"]')
    edit_ssh_key=$(echo "$config" | jq -r '.permission.edit["**/id_rsa"]')
    edit_aws_creds=$(echo "$config" | jq -r '.permission.edit["**/.aws/credentials"]')
    edit_docker=$(echo "$config" | jq -r '.permission.edit["**/.docker/config.json"]')
    edit_kube=$(echo "$config" | jq -r '.permission.edit["**/.kube/config"]')
    edit_tfstate=$(echo "$config" | jq -r '.permission.edit["**/*.tfstate"]')
    [ "$edit_default" = "ask" ]
    [ "$edit_tmp" = "allow" ]
    [ "$edit_vartmp" = "allow" ]
    [ "$edit_env" = "deny" ]
    [ "$edit_env_example" = "allow" ]
    [ "$edit_ssh_key" = "deny" ]
    [ "$edit_aws_creds" = "deny" ]
    [ "$edit_docker" = "deny" ]
    [ "$edit_kube" = "deny" ]
    [ "$edit_tfstate" = "deny" ]

    # --- inert 'write' key removed (covered by 'edit') ---
    write_key=$(echo "$config" | jq -r '.permission.write // "absent"')
    [ "$write_key" = "absent" ]

    # --- read defaults + mirrored secret denies + opencode self-config ---
    read_default=$(echo "$config" | jq -r '.permission.read["*"]')
    read_env=$(echo "$config" | jq -r '.permission.read["**/.env"]')
    read_opencode_self=$(echo "$config" | jq -r '.permission.read["~/.config/opencode/**"]')
    [ "$read_default" = "allow" ]
    [ "$read_env" = "deny" ]
    [ "$read_opencode_self" = "allow" ]

    # --- discovery + agent UX keys ---
    [ "$(echo "$config" | jq -r '.permission.glob["*"]')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.grep["*"]')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.list["*"]')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.task["*"]')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.lsp["*"]')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.skill["*"]')" = "allow" ]

    # --- flat-action-only keys ---
    [ "$(echo "$config" | jq -r '.permission.todowrite')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.question')" = "allow" ]
    [ "$(echo "$config" | jq -r '.permission.webfetch')" = "ask" ]
    [ "$(echo "$config" | jq -r '.permission.websearch')" = "ask" ]
    [ "$(echo "$config" | jq -r '.permission.doom_loop')" = "ask" ]

    # --- external_directory: tmp + opencode self-config allowed, else ask ---
    ext_default=$(echo "$config" | jq -r '.permission.external_directory["*"]')
    ext_tmp=$(echo "$config" | jq -r '.permission.external_directory["/tmp/**"]')
    ext_vartmp=$(echo "$config" | jq -r '.permission.external_directory["/var/tmp/**"]')
    ext_opencode=$(echo "$config" | jq -r '.permission.external_directory["~/.config/opencode/**"]')
    [ "$ext_default" = "ask" ]
    [ "$ext_tmp" = "allow" ]
    [ "$ext_vartmp" = "allow" ]
    [ "$ext_opencode" = "allow" ]
}
