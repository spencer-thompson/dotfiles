# Milestones and handoffs

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

After the update, re-read the touched page and its directly linked or indexed component pages to confirm that no
contradictory current-status claims remain.
