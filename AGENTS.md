# TOOLBX-CONTAINERS CONTEXT

## OVERVIEW

Container images for [Toolbx](https://github.com/containers/toolbox): a Fedora
variant and an Ubuntu variant. Each is a layered OCI image built from a
Containerfile plus a vendored rootfs overlay (`build/rootfs/`), copied over the
base image with `COPY rootfs/ /`. The `ghcr.io/tankdonut/tools` image layers
extra binaries (for example, `direnv`) into `/vendor/bin/`. Build, test, and
release are driven by Invoke tasks under `uv`.

For human contributor setup (asdf, podman, pre-commit install) and contribution
workflow, see [CONTRIBUTING](CONTRIBUTING.md). This file is the source of truth
for repository layout, conventions, and agent guardrails.

## STRUCTURE

| Path | Role |
|------|------|
| `tasks/` | Invoke task definitions (`build.py`, `dev.py`, `config.py`) |
| `test/` | Bats tests (`*.bats` + `common.sh` helper) |
| `build/Containerfile` | Fedora toolbox image |
| `build/Containerfile.ubuntu` | Ubuntu toolbox image |
| `build/fedora-packages.txt` | Fedora dnf package list |
| `build/ubuntu-packages.txt` | Ubuntu apt package list |
| `build/rootfs/` | Vendored filesystem overlay, applied via `COPY rootfs/ /` |
| `build/rootfs/etc/profile.d/` | Login/profile scripts, sourced alphabetically |
| `build/rootfs/etc/zshrc` | zsh interactive init, layered on the stock Fedora `/etc/zshrc` |
| `build/rootfs/etc/starship/` | Starship configuration |
| `.github/workflows/` | CI pipeline definitions |
| `.tool-versions` | asdf-pinned tools (hadolint, python, uv) |
| `.env.example` | Build environment variable template |
| `pyproject.toml` | Python deps (uv), ruff + pyright config |
| `.pre-commit-config.yaml` | Pre-commit hooks |
| `.markdownlint.json` | Markdown lint rules |

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a runtime package | `build/fedora-packages.txt` or `build/ubuntu-packages.txt` | Verify Fedora packages on <https://packages.fedoraproject.org/>; prefer minimal runtime over `-devel`. |
| Add a login/profile script | `build/rootfs/etc/profile.d/NN-name.sh` | `00`-`xx` prefix; must be ksh-safe (see Conventions). |
| Add a zsh-interactive hook | `build/rootfs/etc/zshrc` | Native zsh context; mirror the `_init_*` / `_src_*` pattern. |
| Add an Invoke task | `tasks/*.py` | List with `uv run inv --list`. |
| Add a test | `test/*.bats` | `load common.sh`. |
| Change build args | `.env` (from `.env.example`) | `FEDORA_VERSION`, `UBUNTU_VERSION`, etc. |
| Change base image or tag | `build/Containerfile*` | Requires explicit justification. |

## CONVENTIONS

### Profile scripts (`profile.d`)

- Sourced alphabetically; use a `00`-`xx` numeric prefix.
- Sourced under zsh's `emulate -L ksh` (via `/etc/zprofile` and `/etc/zshrc`),
  so they MUST be ksh-compatible POSIX sh: avoid zsh-native constructs such as
  array subscript flags (`(I)`), arithmetic over array expansions, `autoload`,
  ZLE widgets, or prompt substitution.
- Put zsh-interactive hooks (`direnv hook zsh`, `starship init zsh`,
  completion, plugins) in `build/rootfs/etc/zshrc`, not in `profile.d`.
- Guard any bash-only `profile.d` logic with
  `if [ "$(basename "$SHELL")" = "bash" ]`.

### zshrc

- `build/rootfs/etc/zshrc` is the stock Fedora zsh RPM `/etc/zshrc`
  (`pathmunge`, `_src_etc_profile_d`) with project blocks appended
  (`_src_plugins`, `_init_starship`, `_init_direnv`, `compinit`).
- Add new interactive setup as an `_init_<name>()` function, call it on the
  next line, and add it to the final `unset -f` cleanup line.
- Do not move zsh-interactive hooks into `profile.d` (they break under
  `emulate -L ksh`).

### Container builds

- Two variants only: Fedora (`Containerfile`) and Ubuntu
  (`Containerfile.ubuntu`).
- Keep builds deterministic and reproducible; avoid unnecessary dependencies.
- Prefer the minimal runtime package over `-devel` variants unless headers or
  static libraries are required.
- Do not change base images or image tags without explicit justification in the
  commit message.

### Dependencies

- Python packages are installed and run via `uv` (`pyproject.toml`), not system
  pip. Prefer `uv run python ...` over invoking `python` directly.
- Tool versions are pinned in `.tool-versions`, managed via asdf.
- Do not assume system-level Python has project packages installed.

### Editing

- Prefer updating existing files over creating new ones.
- Keep changes scoped; avoid drive-by refactors.
- Maintain existing formatting and style; use ASCII by default.
- Add comments only to clarify non-obvious behavior.
- Do not reorganize sections or reorder lists unless required for correctness.

### Documentation

- All Markdown must pass `markdownlint` (`.markdownlint.json`); code blocks and
  tables are exempt from the 100-character line limit.
- Surround headings and lists with blank lines; use fenced code blocks with
  language identifiers; wrap links (no bare URLs).
- Full rules are in [CONTRIBUTING](CONTRIBUTING.md).

## ANTI-PATTERNS

- **NEVER** put zsh-native hooks (`direnv hook zsh`, `starship init zsh`) in
  `profile.d` -- they break under `emulate -L ksh`.
- **NEVER** change base images, image tags, or core build logic without
  explicit justification.
- **NEVER** assume system Python has project packages -- use `uv run`.
- **NEVER** commit secrets, tokens, credentials, or `.env`.
- **NEVER** modify CI settings unless explicitly requested.
- **NEVER** introduce new external services, network calls, or credentials.
- **NEVER** use destructive git commands (`git reset --hard`), amend commits,
  or force-push to `main` unless explicitly instructed.

## KEY DEPENDENCIES

| Layer | Stack |
|-------|-------|
| Task runner | `uv` + Invoke (`pyproject.toml`, `tasks/`) |
| Tests | Bats (`test/`) |
| Lint | pre-commit: hadolint (Containerfiles), ruff (Python), markdownlint-cli2 (Markdown), plus hygiene hooks |
| Tool pinning | asdf (`.tool-versions`): hadolint 2.14.0, python 3.14.6, uv 0.11.32 |
| Base images | `quay.io/fedora/fedora-toolbox`, Ubuntu |
| Layered tools | `ghcr.io/tankdonut/tools` -> `/vendor/bin/` |

## COMMANDS

```bash
uv run inv build.build-fedora        # build Fedora image
uv run inv build.build-ubuntu        # build Ubuntu image
uv run inv build.test-fedora         # test Fedora image (needs pre-built image)
uv run inv build.test-ubuntu         # test Ubuntu image (needs pre-built image)
uv run inv build.test --image <ref>  # test an arbitrary image reference
uv run inv build.release-fedora      # build + test + push (Fedora)
uv run inv build.release-ubuntu      # build + test + push (Ubuntu)
uv run inv dev.pre-commit            # run all linters
uv run inv dev.clean                 # remove the cache directory
uv run inv dev.download-fonts        # download Meslo Nerd Fonts into cache
uv run inv --list                    # list all tasks
```

Release tasks accept `--skip-tests` and `--no-cache`.

## ENVIRONMENT

Build tasks read `.env` (git-ignored). Copy `.env.example` to `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `DESTINATION_REGISTRY` | `localhost` | Registry hostname for image tags |
| `FEDORA_VERSION` | `44` | Fedora build arg |
| `UBUNTU_VERSION` | `24.04` | Ubuntu build arg |
| `IMAGE_NAMESPACE` | git remote owner | Override the image namespace |
| `OCI_SOURCE_URL` | -- | Override the OCI source URL label |

## NOTES

- Pre-commit hooks are active; run `uv run inv dev.pre-commit` before
  committing.
- `profile.d` is the login path (`/etc/zprofile` -> `/etc/profile`); `zshrc` is
  the interactive path. The stock Fedora zsh RPM owns `pathmunge` and
  `_src_etc_profile_d` in `/etc/zshrc` -- leave them intact.
- The `ghcr.io/tankdonut/tools` layer provides binaries like `direnv` in
  `/vendor/bin/`; shell hooks for them live in `zshrc` / `profile.d`, not the
  package lists.
- If validation cannot be run locally, state what should be verified; do not
  ignore failing checks without explanation.
- When in doubt, ask for clarification, prefer reversible changes, and document
  assumptions in the commit message.
