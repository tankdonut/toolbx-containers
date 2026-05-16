# toolbx-containers

Container images intended for use with
[Toolbx](https://github.com/containers/toolbox).

These images provide reproducible development environments with common CLI
tools, language runtimes, and supporting utilities preinstalled.

## Purpose

This repository defines container builds used as development environments via
Toolbx. The goal is to provide:

- A consistent CLI toolchain
- Preinstalled language ecosystems (Node, Python, etc.)
- Infrastructure and DevOps tooling
- Reproducible and deterministic builds

## Supported Variants

Containerfiles are located under `build/` and follow this naming pattern:

```text
build/Containerfile.<variant>
```

Currently supported variants:

- `fedora` (default) -> `build/Containerfile`
- `ubuntu` -> `build/Containerfile.ubuntu`

To see available variants:

```bash
ls build/Containerfile*
```

## Building the Container

Build a specific variant using:

```bash
podman build -f build/Containerfile.$VARIANT -t $VARIANT-toolbox
```

Example:

```bash
podman build -f build/Containerfile.ubuntu -t ubuntu-toolbox
```

## Using with Toolbx

Create a new Toolbx container from a built image:

```bash
toolbox create --image $VARIANT-toolbox
toolbox enter
```

## Test Suite

Tests verify container correctness using
[Bats](https://github.com/bats-core/bats-core).

They check:

- Required CLI tools are present in `PATH`
- Language runtimes execute successfully
- Required fonts and utilities are installed

Tests run inside the built container, not on the host.

### Running Tests

Use inv tasks to test specific variants:

```bash
uv run inv build.test-fedora    # Test Fedora toolbox
uv run inv build.test-ubuntu    # Test Ubuntu toolbox
```

These tasks:

1. Verify the image exists (raises an error if not found)
2. Mount the test directory into the container
3. Execute bats inside the container

You must build the image before running tests. The test tasks do not
auto-build.

For advanced options:

```bash
uv run inv build.test --image ubuntu-toolbox --verbose
```

These are smoke tests intended to validate container correctness rather than
full integration behavior.

## OpenCode Configuration

This image ships a system-level OpenCode config at
`/etc/opencode/opencode.jsonc`. The profile script
(`build/rootfs/etc/profile.d/01-variables.sh`) sets:

```bash
OPENCODE_CONFIG="/etc/opencode/opencode.jsonc"
```

### What the system config provides

The system config sets these defaults:

- **autoupdate**: disabled inside the container
- **compaction**: auto with pruning enabled, 10 000 tokens reserved
- **default agent**: `build`
- **instructions**: loads `AGENTS.md`
- **permissions**: bash commands require confirmation unless explicitly
  allowlisted (read-only tools, git queries, build tools); file edits and
  writes require confirmation except under `/tmp`
- **plugin**: loads `@tarquinen/opencode-dcp@latest`
- **share**: `manual` (sessions are not shared without explicit action)
- **watcher**: ignores `.git`, `node_modules`, `dist`, and `build`

The system config does **not** set a theme, network policy, or execution
policy. Those fall back to OpenCode's built-in defaults.

### User overrides

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

## Contributing

For development setup, task reference, and contribution guidelines, see
[CONTRIBUTING.md](CONTRIBUTING.md).
