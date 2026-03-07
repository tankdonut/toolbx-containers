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

- `fedora` (default) → `build/Containerfile`
- `ubuntu` → `build/Containerfile.ubuntu`

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

1. Verify the image exists (build first if needed)
2. Mount the test directory into the container
3. Execute bats inside the container

For advanced options:

```bash
uv run inv build.test --image ubuntu-toolbox --verbose
```

These are smoke tests intended to validate container correctness rather than
full integration behavior.

## Development Tasks

This project uses [invoke](https://www.pyinvoke.org/) tasks for development workflows.

All tasks require `uv run inv` prefix:

### Build Tasks

```bash
uv run inv build.build-fedora    # Build Fedora toolbox image
uv run inv build.build-ubuntu    # Build Ubuntu toolbox image
uv run inv build.push            # Push image to registry
uv run inv build.release-fedora  # Build, test, and push Fedora
uv run inv build.release-ubuntu  # Build, test, and push Ubuntu
```

### Test Tasks

```bash
uv run inv build.test-fedora     # Test Fedora toolbox image
uv run inv build.test-ubuntu     # Test Ubuntu toolbox image
uv run inv build.test --image ubuntu-toolbox --verbose
```

### Dev Tasks

```bash
uv run inv dev.clean             # Remove cache directory
uv run inv dev.download-fonts    # Download Meslo fonts
uv run inv dev.get-pypi-version   # Check PyPI package versions
uv run inv dev.node-modules      # Install node dependencies
uv run inv dev.pre-commit        # Run pre-commit hooks
uv run inv dev.python-packages   # Install Python packages
uv run inv dev.submodules        # Update git submodules
```

For all available tasks:

```bash
uv run inv --list
```

## Linting and Hooks

This repository uses `pre-commit`.

Configured hooks include:

- General file hygiene checks
- `hadolint` for Containerfiles
- `ruff` for Python
- `markdownlint` for Markdown formatting

Install hooks locally:

```bash
pre-commit install
```

Run all hooks manually:

```bash
pre-commit run --all-files
# or
uv run inv dev.pre-commit
```

## Contributing

Please follow the guidelines in `AGENTS.md`.

Key expectations:

- Avoid destructive git operations
- Keep changes minimal and focused
- Do not modify vendored rootfs content
- Ensure Markdown passes `markdownlint`
- Ensure tests pass

---

This repository is intended to support a stable and reproducible Toolbx-based
development workflow.

## OpenCode Defaults

This image provides a system-level OpenCode configuration at:

`/etc/opencode/opencode.jsonc`

The profile script `build/rootfs/etc/profile.d/01-variables.sh` exports:

`OPENCODE_CONFIG=/etc/opencode`

### Default Behavior

- Theme: `github`
- Destructive commands disabled
- Confirmation required for execution actions
- Network enabled but confirmation-gated
- Plain output wrapped at 100 characters
- Editor integration via `$EDITOR`

These defaults balance developer convenience with secure-by-default behavior.

## User Overrides

Users may override the system configuration by creating:

`$XDG_CONFIG_HOME/opencode/opencode.jsonc`

User configuration takes precedence over `/etc/opencode`.

An example override template is provided at:

`build/rootfs/etc/skel/.config/opencode/opencode.jsonc.example`
