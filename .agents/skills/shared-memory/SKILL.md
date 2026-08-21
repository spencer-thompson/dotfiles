---
name: shared-memory
description: >-
  Read, update, create, or clean shared memory for continuity across sessions.
  Use when starting or resuming work with saved context; when decisions,
  constraints, blockers, next steps, preferences, workflows, or reusable
  knowledge should survive the session; when the user asks to remember or
  forget something; or when existing memory may be stale.
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

When recording a major deployment, release, completion, architectural change, or fresh-thread handoff, verify that the
memory entry point will not send a future agent into stale state:

1. Start from the deterministic active project page and inspect only its directly linked or indexed component pages. Do
   not scan the whole wiki without evidence of a broader problem.
2. Compare current-status claims against the authoritative source used for the milestone, such as Git, Linear,
   deployment records, or project documentation. Replace or clearly mark contradictory pre-implementation, in-progress,
   blocked, or not-deployed claims.
3. Give durable component pages descriptive subject names. Do not create generic component pages such as `wiki.md` or
   `notes.md`. Preserve ambiguous existing pages until their purpose and ownership are clear.
4. When a Codex-owned component page is superseded, update inbound index or project-page links and either mark the old
   page historical with the canonical replacement or remove it when deletion is clearly safe and authorized.
5. For an explicit handoff, state the canonical current page and the authoritative systems for richer history. Keep old
   plans available as historical evidence, but do not leave them presented as current instructions.

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

- Keep every memory file under 250 lines or 32 KB; keep frequently read project pages much smaller.
- Distinguish facts from guesses, impressions, and preferences.
- Never store secrets, credentials, private keys, tokens, or sensitive personal information unless the user explicitly
  asks and the location is appropriate.
- Preserve ambiguous or user-authored material unless it is clearly obsolete. Do not rewrite unrelated memory for style.
- Prefer one canonical entry. Link to richer material instead of copying it across targets.
- Use relative links inside the wiki. Store durable local assets under `~/wiki/assets/` and link them relatively.
- Use `apply_patch` for manual edits and respect the active sandbox and approval boundaries.

## Verification

After editing an active project page, run `wc -l <page>`; if it exceeds 80 lines, prune completed history or explain why
the extra active context is still necessary. After editing memory Markdown, run `rumdl fmt <touched-files>`. If wiki
links or images changed, run `lychee --offline --no-progress <touched-wiki-files>`. Use networked link checking only
when external URLs changed, the user requests it, or remote reachability matters. After a milestone or handoff update,
re-read the touched page and its directly linked or indexed component pages to confirm that no contradictory
current-status claims remain. Report checks that could not run.
