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
- **permissions**: baseline tuned for a general-purpose dev container.
  OpenCode evaluates rules last-match-wins in insertion order, so within
  each tool the broad rule (`"*"`) leads and narrower rules follow.
  - **bash**: defaults to `ask`. Read-only inspection is allowlisted --
    file discovery (`ls`, `find`, `tree`, `stat`, `du`, `df`, `wc`,
    `which`, ...), content viewing (`cat`, `head`, `tail`, `less`, `bat`,
    `nl`, ...), text processing (`grep`, `rg`, `awk`, `sed`, `sort`,
    `uniq`, `tr`, ...), hashing/encoding (`sha256sum`, `xxd`, `base64`,
    `strings`, ...), structured-data viewers (`jq`, `yq`, `xq`, `dasel`),
    system info (`uname`, `lscpu`, `ps`, `ss`, `ip addr`, `mount`, ...),
    and read-only git operations (`status`, `diff`, `log`, `show`,
    `rev-parse`, `describe`, `remote get-url`, `ls-files`, `blame`,
    `cat-file`, list-only `branch`/`tag`/`config --get`). `sed -i`,
    mutating `git branch`/`git tag` flags, and `git config --set*` fall
    through to `ask`. Catastrophic operations (`rm -rf /`, `dd ... of=/dev/`,
    `mkfs*`, `shutdown*`, `reboot*`, `halt`, `init 0/6`) are explicitly
    denied. Build tools `make` and `uv` are allowed.
  - **edit**: defaults to `ask`; `/tmp/**` and `/var/tmp/**` are allowed.
    The `edit` permission also gates the `write` and `apply_patch` tools.
    Secrets are denied regardless of path: `.env*` (except `.env.example`
    and similar template suffixes), SSH keys, `.aws/credentials`,
    `.gnupg/**`, `.docker/config.json`, `.kube/config`, `*.tfstate*`,
    `*.pem`, `*.key`, `*.p12`, `*.keystore`, `*.kdbx`, `*.ovpn`,
    `.netrc`, `.npmrc`, `.pypirc`, `.git-credentials`, and
    `credentials.json`.
  - **read**: defaults to `allow`, with the same secret deny-list mirrored
    (so `.env` and friends cannot be exfiltrated via reads or MCP resource
    fetches). `~/.config/opencode/**` is explicitly allowed for
    self-inspection.
  - **glob**, **grep**, **list**, **task**, **lsp**, **skill**: `allow`
    (discovery, subagent dispatch, code intelligence, and skill loading
    are required for normal agent UX).
  - **external_directory**: defaults to `ask`; `/tmp/**`, `/var/tmp/**`,
    and `~/.config/opencode/**` are allowed.
  - **todowrite**, **question**: `allow` (benign UX tools).
  - **webfetch**, **websearch**: `ask` (network egress can leak codebase
    context; the user opts in per call).
  - **doom_loop**: `ask` (OpenCode's safety net for repeated identical
    tool calls).
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
