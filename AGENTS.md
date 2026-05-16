# AGENTS.md

Guidelines for automated coding agents operating in this repository.

## Purpose

This project hosts container configurations and related tooling.

For human contributor guidelines, see [CONTRIBUTING](CONTRIBUTING.md).

Agents should prioritize safety, reproducibility, and minimal disruption to
existing developer workflows. This file defines how agents are expected to
behave, what they may change, and how they should communicate those changes.

## Where to Look

- `tasks/` - Invoke task definitions (`build.py`, `dev.py`, `config.py`)
- `test/` - Bats test files (`*.bats` + `common.sh` helper)
- `build/` - Containerfiles, package lists, rootfs overlay
- `build/rootfs/` - Vendored container filesystem (profile scripts, configs)
- `.github/workflows/` - CI pipeline definitions
- `.tool-versions` - Pinned versions for ASDF-managed tools (hadolint, python,
  uv)
- `.env.example` - Environment variable template for build configuration
- `pyproject.toml` - Python dependencies, ruff and pyright configuration
- `.pre-commit-config.yaml` - Pre-commit hook definitions
- `.markdownlint.json` - Markdown linting rules

## Commands

All commands use the `uv run inv` prefix. Use variant-specific tasks instead of
the generic `build.build` or `build.test`, which require extra arguments.

### Build

- `uv run inv build.build-fedora` - Build the Fedora toolbox image
- `uv run inv build.build-ubuntu` - Build the Ubuntu toolbox image

### Test

Requires a pre-built image.

- `uv run inv build.test-fedora` - Test the Fedora toolbox image
- `uv run inv build.test-ubuntu` - Test the Ubuntu toolbox image
- `uv run inv build.test --image <ref>` - Test an arbitrary image reference

### Release

Build, test, and push in sequence.

- `uv run inv build.release-fedora` - Full pipeline for Fedora
- `uv run inv build.release-ubuntu` - Full pipeline for Ubuntu

Pass `--skip-tests` to skip the test step, or `--no-cache` to force a clean
build.

### Dev

- `uv run inv dev.pre-commit` - Run all linters
- `uv run inv dev.clean` - Remove the cache directory
- `uv run inv dev.download-fonts` - Download Meslo Nerd Fonts into cache
- `uv run inv --list` - List all available tasks

## Conventions

- Tests use bats framework in `test/` directory.
- Two container variants: Fedora (`Containerfile`) and Ubuntu
  (`Containerfile.ubuntu`).
- Package lists: `build/fedora-packages.txt` and `build/ubuntu-packages.txt`.
- Profile scripts in `build/rootfs/etc/profile.d/` are sourced alphabetically
  (use `00`-`xx` prefix convention).
- Python deps managed via `uv` (`pyproject.toml`), not system pip.
- Tool versions pinned in `.tool-versions` (managed via asdf).
- Pre-commit hooks: general hygiene (trailing whitespace, merge conflicts,
  large files), hadolint (Containerfiles), ruff (Python),
  markdownlint-cli2 (Markdown).

## Environment Configuration

Build tasks read environment variables from `.env` (git-ignored). Copy
`.env.example` to `.env` and adjust as needed:

- `DESTINATION_REGISTRY` - Registry hostname for image tags (default:
  `localhost`)
- `FEDORA_VERSION` - Fedora version for build args (default: `44`)
- `UBUNTU_VERSION` - Ubuntu version for build args (default: `24.04`)
- `IMAGE_NAMESPACE` - Override the image namespace (defaults to the git remote
  owner)
- `OCI_SOURCE_URL` - Override the OCI source URL label

## Core Principles

- Be safe: avoid destructive operations unless explicitly requested.
- Be minimal: make the smallest change that solves the problem.
- Be explicit: document assumptions in commit messages and PR descriptions.
- Preserve intent: do not revert or reformat unrelated changes.
- Be scoped: only modify files that are directly relevant to the task.

## Scope of Authority

- Agents may update container configs, package lists, and supporting scripts.
- Agents may update documentation to reflect actual behavior.
- Agents must not change base images, image tags, or core build logic without
  explicit justification in the commit message.
- Agents must not introduce new external services, network calls, or
  credentials.
- Agents must not commit secrets or modify CI settings unless explicitly
  requested.

## Editing Rules

- Prefer updating existing files over creating new ones.
- Keep changes scoped and focused; avoid drive-by refactors.
- Maintain existing formatting and style conventions.
- Use ASCII by default unless the file already requires Unicode.
- Do not add comments unless they clarify non-obvious behavior.
- Do not reorganize sections or reorder lists unless required for correctness.

## Git Workflow

- Never use destructive commands like `git reset --hard` unless explicitly requested.
- Do not amend commits unless explicitly instructed.
- Do not force-push to main/master.
- Stage only relevant files.
- Write concise commit messages that explain why the change is needed.
- Reference related issues or context when available.
- Clearly state any trade-offs or follow-up work in the PR description.

## Containers and Tooling

- Do not change base images or image tags without justification.
- Keep container builds deterministic.
- Avoid introducing unnecessary dependencies.
- Ensure builds remain reproducible and documented.
- When adding packages, prefer the minimal runtime package over `-devel`
  variants unless headers or static libraries are required.
- When determining package availability for Fedora, use
  <https://packages.fedoraproject.org/> to verify packages exist for the target
  Fedora version.

## Dependency Management

- Python packages are installed and executed via `uv`.
- When running Python commands in tests or scripts,
  prefer `uv run python ...` instead of invoking `python` directly.
- Do not assume system-level Python has project packages installed.
- Keep dependency resolution deterministic and consistent with the container build configuration.

## Testing and Validation

- Run relevant build or lint steps before committing when applicable.
- If validation cannot be run locally, clearly state what should be verified.
- Do not ignore failing checks without explanation.
- For package changes, ensure the container build still succeeds.

## Security

- Never commit secrets, tokens, or credentials.
- Treat environment files (e.g., `.env`) as sensitive.
- Avoid adding network calls or external downloads without clear need.

## Documentation

- All Markdown files must pass `markdownlint` using the repository configuration.
- Wrap prose at 100 characters; avoid trailing whitespace.
- Surround headings and lists with blank lines.
- Use fenced code blocks with language identifiers when possible.
- Do not use bare URLs; wrap links in angle brackets or Markdown link syntax.

## When in Doubt

- Ask for clarification instead of guessing.
- Prefer reversible changes.
- Propose a minimal safe default and document the assumption.
