# OpenCode Configuration

This image ships a system-level OpenCode config at
`/etc/opencode/opencode.jsonc`. The profile script at
`build/rootfs/etc/profile.d/01-variables.sh` exports the path:

```bash
OPENCODE_CONFIG="/etc/opencode/opencode.jsonc"
```

## System Configuration

The system config sets these defaults:

- **autoupdate**: disabled inside the container
- **compaction**: auto with pruning enabled, 10 000 tokens reserved
- **default agent**: `build`
- **instructions**: loads `AGENTS.md`
- **permissions**:
  - **bash**: defaults to `ask`; the following are allowlisted:
    - git read operations (`status`, `log`, `diff`, `show`, `branch`,
      `rev-parse`)
    - text processing (`awk`, `cat`, `grep`, `rg`, `sed`, `sort`, `uniq`)
    - output commands (`echo`, `printf`)
    - filesystem discovery (`find`, `tree`, `test`, `type`, `ls`, `stat`,
      `tail`, `wc`, `which`)
    - system information (`date`, `env`, `hostname`, `id`, `printenv`,
      `uname`)
    - build tools (`make`, `uv`)
  - **edit** / **write**: defaults to `ask`; `/tmp/**` is allowed
  - **external_directory**: `/tmp/**` is allowed
- **plugin**: loads `@tarquinen/opencode-dcp@latest`
- **share**: `manual` (sessions are not shared without explicit action)
- **watcher**: ignores `.git`, `node_modules`, `dist`, and `build`

The system config does **not** set a theme, network policy, or execution
policy. Those fall back to OpenCode's built-in defaults.

## User Overrides

Users can override the system configuration by creating:

```bash
$XDG_CONFIG_HOME/opencode/opencode.jsonc
```

User configuration takes precedence over the system config.

An example override template is provided at
`build/rootfs/etc/skel/.config/opencode/opencode.jsonc.example`.
That file demonstrates how to set a dark theme (`github-dark`), enable
network access without confirmation, and disable destructive commands:

```jsonc
{
    "theme": "github-dark",
    "network": {
        "enabled": true,
        "requireConfirmation": false
    },
    "execution": {
        "allowDestructiveCommands": false,
        "requireConfirmation": true
    }
}
```
