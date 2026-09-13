---
name: shared-memory
description: >-
  Resume work from saved context or maintain durable memory across sessions.
  Use to preserve useful decisions and next steps, or when asked to remember,
  forget, or reconcile stale memory.
---

# Shared Memory

Preserve only information that will make future work faster or more accurate. Keep memory lean, current, and distinct
from transcripts or project documentation.

## Workflow

1. Decide whether the task needs a read, write, cleanup, or no memory action.
2. Select the smallest target below and state the exact path before editing.
3. Inspect the target first with `rg`, targeted reads, or a narrow listing. Do not scan the whole wiki without a reason.
4. Update the existing source of truth when possible. Avoid duplicate facts across memory targets.
5. Report the files read or changed and the durable point preserved. If no write helps future work, do not create one.

## Memory Targets

### Active Project Continuity

Store Codex-owned project continuity under `~/wiki/project-context/` using a deterministic path:

1. Resolve the Git root; outside Git, use the workspace root.
2. For a root under the home directory, append `.md` to its home-relative path.
3. For a root outside the home directory, mirror its absolute path without the leading slash under `_external/`.
4. Do not create project memory for the home directory itself.

Examples:

- `~/projects/receipts` -> `~/wiki/project-context/projects/receipts.md`
- `~/dotfiles` -> `~/wiki/project-context/dotfiles.md`
- `/srv/example` -> `~/wiki/project-context/_external/srv/example.md`

Read an existing project page before project-scoped work when continuity is relevant. During migration, if the wiki page
does not exist, inspect a repository-root `CONTEXT.md` only as a legacy candidate; confirm it is personal continuity
rather than repository documentation. Never create a new repository-root `CONTEXT.md` for Codex memory.

Keep project pages focused on the current goal, binding decisions and constraints, blockers, next actions, and useful
references. Target 100 lines or fewer. Replace stale state instead of appending history.

Move completed work and detailed history to the dated journal or its authoritative source system, such as Git, Linear,
deployment records, or project documentation. Keep only the completed outcome when it still constrains active work, and
link to the richer record instead of retaining an implementation diary in project context.

Maintain `~/wiki/project-context/INDEX.md` when project pages are added, removed, renamed, or moved. Update the root
wiki index only when the project-context section itself is materially repurposed.

### Milestones And Handoffs

When recording a major deployment, release, completion, architectural change, or fresh-thread handoff, use
[the milestone and handoff reference](references/milestones-and-handoffs.md) to reconcile current-status claims against
authoritative evidence and keep entry points current.

### Durable Wiki

Use `~/wiki/` for stable preferences, recurring collaboration patterns, reusable workflows, technical notes, and durable
decisions or context that should outlive one task. Read `~/wiki/INDEX.md` when orienting, prefer updating an existing
page, and keep the index brief and current.

### Journal

Use `~/wiki/journal/MM-DD-YYYY.md` for meaningful work completed that day, pickup points, decisions, and open loops.
Keep entries short and link to active context or source systems for detail; do not journal every trivial action.
Maintain `~/wiki/journal/INDEX.md` when entries are added, removed, or renamed.

### Optimizations

Use `~/wiki/OPTIMIZATIONS.md` for improvements to AGENTS.md, skills, hooks, tools, approval rules, context efficiency,
verification, and recurring collaboration failure modes. Update or prune implemented, contradicted, or stale ideas.

## Editing Rules

- Keep every memory file below both 250 lines and 32 KB; keep frequently read project pages much smaller.
- Distinguish facts from guesses, impressions, and preferences.
- Never store secrets, credentials, private keys, tokens, or sensitive personal information unless the user explicitly
  asks and the location is appropriate.
- Preserve ambiguous or user-authored material unless it is clearly obsolete. Do not rewrite unrelated memory for style.
- Prefer one canonical entry. Link to richer material instead of copying it across targets.
- Use relative links inside the wiki. Store durable local assets under `~/wiki/assets/` and link them relatively.
- Use `apply_patch` for manual edits and respect the active sandbox and approval boundaries.

## Verification

After editing an active project page, run `wc -l <page>`; if it exceeds 100 lines, prune completed history or explain
why the extra active context is still necessary. After editing memory Markdown, run `rumdl fmt <touched-files>`.
If wiki links or images changed, run `lychee --offline --no-progress <touched-wiki-files>`. Use networked link checking
only when external URLs changed, the user requests it, or remote reachability matters. For milestone and handoff
updates, follow the status reconciliation check in the linked reference. Report checks that could not run.
