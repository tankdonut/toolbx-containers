# Contributing to toolbx-containers

Thanks for your interest in contributing. This guide covers what you need to
set up, build, test, and submit changes.

## Development Environment

You'll need a few tools installed before you start:

- [uv](https://docs.astral.sh/uv/) for Python dependency management
- [podman](https://podman.io/) or Docker as the container runtime
- [pre-commit](https://pre-commit.com/) for git hooks
- [asdf](https://asdf-vm.com/) for language runtime management
- [git](https://git-scm.com/) for version control

### Initial Setup

Clone the repository and install the git hooks:

```bash
git clone https://github.com/tankdonut/toolbx-containers.git
cd toolbx-containers
pre-commit install
```

The `pre-commit install` step wires up the hooks defined in
[`.pre-commit-config.yaml`](.pre-commit-config.yaml) so they run automatically
on every commit.

Python dependencies are managed through `uv`. There is no manual `pip install`
step. All invoke tasks use the `uv run inv` prefix, which resolves and executes
in the project's virtual environment automatically.

## Build Tasks

This project uses [Invoke](https://www.pyinvoke.org/) tasks for build
workflows. All commands require the `uv run inv` prefix.

### Build a Single Image

```bash
uv run inv build.build-fedora    # Build the Fedora toolbox image
uv run inv build.build-ubuntu    # Build the Ubuntu toolbox image
```

Both tasks detect whether `podman` or `docker` is available. They tag images
using the current git commit SHA and branch name by default.

### Push an Image

```bash
uv run inv build.push --image fedora-toolbox
```

Pushes all generated tags for the image to the configured registry.

### Release (Build, Test, Push)

The release tasks run the full pipeline: build, then test, then push.

```bash
uv run inv build.release-fedora  # Build, test, and push Fedora
uv run inv build.release-ubuntu  # Build, test, and push Ubuntu
```

Pass `--skip-tests` to skip the test step, or `--no-cache` to force a clean
build.

## Test Tasks

Tests use [Bats](https://github.com/bats-core/bats-core) and run inside the
built container, not on the host. They verify that CLI tools are on `PATH`,
language runtimes work, and expected fonts and utilities are present.

Tests require a pre-built image. If the image is not found, the task raises an
error. Build the image first using the appropriate build task.

### Running Tests

Test a specific variant:

```bash
uv run inv build.test-fedora    # Test the Fedora toolbox image
uv run inv build.test-ubuntu    # Test the Ubuntu toolbox image
```

Or test any image directly:

```bash
uv run inv build.test --image localhost/fedora-toolbox:abc1234
```

Add `--verbose` to show full output from each test case:

```bash
uv run inv build.test --image localhost/fedora-toolbox:abc1234 --verbose
```

## Dev Tasks

Utility tasks for day-to-day development:

```bash
uv run inv dev.clean            # Remove the cache directory
uv run inv dev.download-fonts   # Download Meslo Nerd Fonts into cache
uv run inv dev.pre-commit       # Run all pre-commit hooks
```

- `dev.clean` deletes the `cache/` directory used for downloaded artifacts.
- `dev.download-fonts` fetches the Meslo Nerd Fonts zip into `cache/`. The
  build process references these fonts.
- `dev.pre-commit` runs `pre-commit run --all` across the repository. Useful
  when you want to check everything without committing.

## Linting and Hooks

Pre-commit runs automatically on every commit when installed. You can also
trigger it manually:

```bash
pre-commit run --all-files
```

Or use the Invoke shortcut:

```bash
uv run inv dev.pre-commit
```

### Configured Hooks

- **General hygiene** (via
  [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)):
  checks for large files, merge conflict markers, trailing whitespace,
  mixed line endings, and missing newlines at end of file.
- **hadolint** (via [hadolint](https://github.com/hadolint/hadolint)):
  lints Containerfiles under `build/`.
- **ruff** (via [ruff-pre-commit](https://github.com/astral-sh/ruff-pre-commit)):
  checks and auto-fixes Python style issues.
- **markdownlint** (via
  [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)):
  enforces Markdown formatting rules from `.markdownlint.json`.

If a hook fails, fix the reported issues and stage the changes before
committing again.

## Git Conventions

Follow these rules when working with git in this repository:

- **No destructive operations.** Never run `git reset --hard`,
  `git checkout --`, or similar commands unless explicitly asked.
- **No amend unless asked.** Don't use `git commit --amend` on shared
  branches unless someone specifically requests it.
- **No force-push to main.** Never force-push to the `main` or `master`
  branch.
- **Stage only relevant files.** Don't `git add .` blindly. Stage the files
  that belong to your change and nothing else.
- **Write concise commit messages.** Explain *why* the change is needed, not
  just *what* changed. Wrap the body at 72 characters.
- **Reference issues.** If your change relates to an open issue, mention it
  in the commit message (for example, `Fix font path lookup (#12)`).

## Key Expectations

Keep these principles in mind when contributing:

- **Minimal changes.** Make the smallest change that solves the problem.
  Don't bundle unrelated refactors or formatting tweaks into your work.
- **Scoped work.** Only modify files that are directly relevant to your
  change. If you spot something unrelated, file an issue instead.
- **Reproducible builds.** Container builds should produce the same output
  given the same inputs. Avoid non-deterministic steps in Containerfiles.
- **Deterministic dependencies.** Don't add packages or tools that pull in
  unstable or pinned-to-latest dependencies. Prefer versioned, stable
  packages. When determining package availability for Fedora, check
  <https://packages.fedoraproject.org/> to verify the package exists for
  the target Fedora version.
- **No secrets.** Never commit tokens, credentials, or environment files
  with real values.

## Documentation Rules

All Markdown files in this repository must pass `markdownlint` using the
project's `.markdownlint.json` configuration. The key rules:

- **Wrap prose at 100 characters.** Code blocks and tables are exempt from
  the line length limit.
- **Blank lines around headings and lists.** Put a blank line before and
  after every heading and before/after list blocks.
- **Fenced code blocks with language IDs.** Always specify the language in
  fenced code blocks (for example, ` ```bash ` instead of bare ` ``` `).
- **No bare URLs.** Wrap URLs in angle brackets (`<https://example.com>`)
  or use Markdown link syntax (`[text](url)`).
- **No trailing whitespace.** Lines should not end with spaces or tabs.
- **Blank line at end of file.** Every file must end with a trailing
  newline.

Run the linter to check:

```bash
pre-commit run --all-files
```

---

Questions or issues? Open an issue on the repository and we'll take a look.
