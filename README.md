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

Containerfiles are located under `build/`:

- `fedora` (default) -> `build/Containerfile`
- `ubuntu` -> `build/Containerfile.ubuntu`

## Quick Start

Build a container image:

```bash
podman build -f build/Containerfile.ubuntu -t ubuntu-toolbox
```

Create and enter a Toolbx container from the built image:

```bash
toolbox create --image ubuntu-toolbox
toolbox enter
```

## Documentation

- [Contributing](CONTRIBUTING.md) -- development setup, build/test tasks,
  guidelines
- [OpenCode Configuration](docs/opencode.md) -- system config, user overrides
- [AGENTS.md](AGENTS.md) -- automated agent guidelines
