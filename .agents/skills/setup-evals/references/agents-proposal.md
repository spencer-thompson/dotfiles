# Repository instruction proposal

Inspect all applicable `AGENTS.md` files before drafting anything. Preserve project-specific rules and higher-priority
instructions. Propose only the smallest useful addition. Do not apply the proposal without separate approval.

## Existing `AGENTS.md`

Adapt this patch to the document's current headings and voice:

```markdown
## Agent ownership

- Act autonomously within this repository when the requested direction is clear.
- Make project-local decisions that support the stated goal, existing architecture, and verified evidence.
- Treat code and commit history as the primary explanation of the work. Favor designs a human can read, verify, and
  extend without an agent translating them.
- Apply creativity and care where they improve simplicity, performance, correctness, or the development experience.

## Git policy

- Agents may stage and commit coherent completed repository work when a useful checkpoint is ready.
- Use clear, concise commit messages that describe the actual change.
- Commit permission does not include pushing, force operations, history rewrites, releases, or deployments unless the
  user separately authorizes them.

## Evaluation policy

- For performance, latency, regression, profiling, simplification, or performance-sensitive refactoring work, read and
  follow the project-owned eval skill.
- Run the standard workload before editing, compare an equivalent run afterward, preserve negative evidence, and report
  exact run IDs with both wins and regressions.
```

Name the actual eval skill path in the final proposal.

## No `AGENTS.md`

Propose a compact file based on this structure:

```markdown
# Agent instructions

## Engineering judgment

- Favor simple, readable solutions and verification proportional to risk.
- Preserve unrelated work and follow the repository's established build, test, formatting, and architecture
  conventions.

## Agent ownership

- Act autonomously within this repository when the requested direction is clear.
- Make project-local decisions that support the stated goal, existing architecture, and verified evidence.
- Treat code and commit history as the primary explanation of the work. Favor designs a human can read, verify, and
  extend without an agent translating them.
- Apply creativity and care where they improve simplicity, performance, correctness, or the development experience.

## Git policy

- Agents may stage and commit coherent completed repository work when a useful checkpoint is ready.
- Use clear, concise commit messages that describe the actual change.
- Commit permission does not include pushing, force operations, history rewrites, releases, or deployments unless the
  user separately authorizes them.

## Evaluation policy

- For performance, latency, regression, profiling, simplification, or performance-sensitive refactoring work, read and
  follow `<actual-project-eval-skill-path>`.
- Run the standard workload before editing, compare an equivalent run afterward, preserve negative evidence, and report
  exact run IDs with both wins and regressions.
```

Add discovered project commands or safety boundaries only when they are stable and genuinely useful in every future
task. Do not turn the proposal into a transcript of the setup work.

## Presentation

Show the exact proposed Markdown or patch, followed by a short rationale. State clearly that:

- autonomy covers safe project-local implementation decisions;
- committing covers coherent completed checkpoints;
- external mutations and destructive Git operations still require their own authority;
- the user can approve, revise, or decline the proposal without affecting the eval system.
