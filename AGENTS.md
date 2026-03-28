# AGENTS.md

Guidelines for automated coding agents and contributors working in this
repository.

## Purpose

This project hosts container configurations and related tooling.

Agents should prioritize safety, reproducibility, and minimal disruption to
existing developer workflows. This file defines how agents are expected to
behave, what they may change, and how they should communicate those changes.

The structure and recommendations are informed by GitHub's guidance on
writing effective `AGENTS.md` files:
<https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/>.

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

---

This file defines expectations for automated agents and contributors operating in this repository.
