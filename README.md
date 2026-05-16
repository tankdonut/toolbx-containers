# toolbx-containers

Container images intended for use with
[Toolbx](https://github.com/containers/toolbox).

## Variants

| Variant | Image | Containerfile |
|---------|-------|---------------|
| Fedora 44 | `ghcr.io/tankdonut/fedora-toolbox:44` | `build/Containerfile` |
| Ubuntu 24.04 | `build/Containerfile.ubuntu` | `build/Containerfile.ubuntu` |

## Quick Start

Pull a prebuilt image and create a Toolbx container:

```bash
podman pull ghcr.io/tankdonut/fedora-toolbox:44
toolbox create --image ghcr.io/tankdonut/fedora-toolbox:44
toolbox enter
```

## Documentation

- [Contributing](CONTRIBUTING.md) -- development setup, build/test tasks,
  guidelines
- [OpenCode Configuration](docs/opencode.md) -- system config, user overrides
- [AGENTS.md](AGENTS.md) -- automated agent guidelines
