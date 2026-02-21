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

Tests are written using
[Bats](https://github.com/bats-core/bats-core).

They verify:

- Required CLI tools are present in `PATH`
- Language runtimes execute successfully
- Required fonts and utilities are installed

To run tests:

```bash
bats test/
```

These are smoke tests intended to validate container correctness rather than
full integration behavior.

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
