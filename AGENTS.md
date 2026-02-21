# AGENTS.md

Guidelines for automated coding agents and contributors working in this repository.

## Purpose

This project hosts container configurations and related tooling. Agents should prioritize safety, reproducibility, and minimal disruption to existing developer workflows.

## Core Principles

- Be safe: avoid destructive operations unless explicitly requested.
- Be minimal: make the smallest change that solves the problem.
- Be explicit: document assumptions in commit messages and PR descriptions.
- Preserve intent: do not revert or reformat unrelated changes.

## Editing Rules

- Prefer updating existing files over creating new ones.
- Keep changes scoped and focused; avoid drive-by refactors.
- Maintain existing formatting and style conventions.
- Use ASCII by default unless the file already requires Unicode.
- Do not add comments unless they clarify non-obvious behavior.

## Git Workflow

- Never use destructive commands like `git reset --hard` unless explicitly requested.
- Do not amend commits unless explicitly instructed.
- Do not force-push to main/master.
- Stage only relevant files.
- Write concise commit messages that explain why the change is needed.

## Containers and Tooling

- Do not change base images or image tags without justification.
- Keep container builds deterministic.
- Avoid introducing unnecessary dependencies.
- Ensure builds remain reproducible and documented.

## Testing and Validation

- Run relevant build or lint steps before committing when applicable.
- If validation cannot be run locally, clearly state what should be verified.
- Do not ignore failing checks without explanation.

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

---

This file defines expectations for automated agents and contributors operating in this repository.
