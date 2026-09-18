# Dotfiles

This repository is the source for configuration installed into `~` with GNU Stow. `install.sh` restows this directory;
it also preserves `~/.agents` as a real directory rather than a symlink to the whole repository directory.

## Configuration ownership

- Before editing an installed configuration, resolve its symlink and edit the source in this repository when managed
  here. Preserve existing files and links owned by other tools.
- Let Stow create and manage links. Avoid hand-written absolute symlinks, replacing symlinks with regular files, or
  using `stow --adopt` to absorb existing configuration without inspecting the differences and establishing intent.
- Keep this root `AGENTS.md` excluded through the exact root rule in `.stow-local-ignore`. The nested
  `.codex/AGENTS.md` supplies global Codex preferences and must remain stowed to `~/.codex/AGENTS.md`.
- `.config/nvim` is a Git submodule. Inspect its own status and instructions before changes; preserve local work and
  update its parent-repository pointer only when that update belongs to the task.
- Keep credentials, machine-local state, generated caches, and temporary backups out of commits. Preserve unrelated
  machine-specific settings when changing shared configuration.

## Environment diagnosis

Before asking Spencer to log in again, distinguish invalid credentials from sandbox, keyring, network, or missing-tool
access. Use the permitted recovery path when available; never assume sandbox escalation is supported or authorized.
Report the actual access limitation when no permitted recovery is available.

## Validation and applying changes

Use checks suited to the changed files: `shellcheck` and `shfmt` for shell, `rumdl` for Markdown, and the application's
own validation command when available. Avoid restarting the whole desktop or unrelated services to apply one change.

When adding configuration files or changing links or ignore rules, run this from `~/dotfiles`:

```bash
stow --simulate --restow --target="$HOME" .
```

Resolve conflicts affecting the task before applying Stow. Preserve unrelated conflicts and report them. A dry run
does not apply configuration; after an authorized restow or targeted reload, verify the affected link or service.
