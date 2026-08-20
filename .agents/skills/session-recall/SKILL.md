---
name: session-recall
description: >-
  Use when the user asks to inspect, recall, search, rank, or analyze recent or past Codex sessions.
---

# Session Recall

Use local Codex session data as private, read-only evidence. Identify relevant threads quickly, inspect only necessary
rollout evidence, and report what happened, what remains open, and what may deserve durable memory.

## Safety And Evidence

- Never modify, archive, delete, rename, pin, or compact session data unless the user explicitly asks.
- Use redacted output by default. Use `--unredacted` only when raw messages, tool inputs, outputs, commands, or file
  details are necessary; warn that it may expose secrets or personal data.
- Treat encrypted reasoning as unavailable. Base conclusions on visible messages, safe metadata, work events, token
  records, compactions, and summaries.
- Paraphrase findings and distinguish observations from inference.

## Review Workflow

1. Define the smallest useful scope. Honor an explicit range. Otherwise begin with the current day and relevant project,
   cwd, user-assigned name, or task; expand only as needed.

2. Capture one timezone-aware `review_cutoff` before discovery. Resolve the range start and relative dates in the
   user's timezone, then keep the start and cutoff immutable while reviewing live threads.

3. Discover and rank threads through SQLite. Prefer compact output for ordinary discovery:

   ```bash
   python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
     --since START_ISO --until REVIEW_CUTOFF_ISO \
     --archived all --top-level-only --sort recency --limit 40 --compact
   ```

   Prefer these signals:

   - `--named-only --sort recency` for threads the user marked as important.
   - `--git-project`, `--git-branch`, `--cwd`, or `--query` for project and topic discovery.
   - `--family`, `--root-thread-id`, or `--children` for complete thread families.
   - `--top-by-tokens` or `--min-tokens --sort tokens` for high-workload candidates.
   - `stats` for fast token, thread, family, archive, name, model, reasoning, project, branch, or month analytics.
   - `--fields` only when the compact preset lacks a field needed for selection.

4. Use catalog output as the source of thread metadata and rollout paths. Do not rescan the sessions directory to
   reconstruct recency, families, project identity, or cumulative thread tokens.

5. Use `show` for targeted evidence from one or more known thread IDs. Prefer `--metadata compact`; use
   `--events-only` for batch event review when catalog metadata is already available. For the final assistant response
   from each selected thread, use `--kind assistant --tail 1` instead of loading every progress update.

6. Inspect selected rollout paths only when SQLite cannot answer the question:

   ```bash
   python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
     --since START_ISO --until REVIEW_CUTOFF_ISO \
     --git-project OWNER/REPO --sort recency --limit 20 --format paths \
   | python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py summary \
     --paths-from-stdin --since START_ISO --until REVIEW_CUTOFF_ISO --aggregate --compact
   ```

   Use `summary` for exact-range message, turn, tool, token, duration, command, file-change, MCP, compaction, and replay
   metrics. Use repeatable `--require-tool TOOL` to retain only rollouts that used every named tool inside the range.
   Use `events` for redacted, timestamped, line-numbered evidence and targeted text matching. Use `--counter-limit` or
   `--fields` when a custom bounded summary is more useful than the compact preset. Preserve the generated truncation,
   distinct-count, and omitted-count fields whenever limited counters are handed off or stored.

7. Interpret metrics carefully:

   - Catalog `cumulative_tokens` is cumulative thread workload and is ideal for fast ranking.
   - Catalog `open_child_count` reflects stored spawn-edge status. It is not proof that a child agent is still running.
   - Inspector token fields are cumulative-counter deltas inside the requested event range.
   - `active_duration_ms` sums recorded task durations; it excludes idle wall-clock gaps.
   - Message count, activity events, tokens, tools, bytes, and duration describe different kinds of thread length.

8. Read narrowly. Treat output projections as presentation controls only: `--compact`, `--fields`, metadata modes,
   and counter limits do not change filtering, ranking, calculations, or evidence collection. Exclude the active recall
   thread or family when analyzing historical behavior.

9. Synthesize high-signal findings: completed work, decisions, validation, preferences, open loops, and contradictions.
   Own final judgment; metrics identify candidates but do not determine importance.

Before a persistent write, drift-check families active during inspection. If they advanced past the cutoff, keep the
write scoped to the original snapshot or establish and state a new cutoff.

Read [the CLI reference](references/cli.md) for exact presets, fields, output contracts, and redaction behavior.

## Reporting

Use only sections that help answer the request: Reviewed, Work Done, Observations, Improvements, Open Loops, and Memory
Candidates. State the exact range or cutoff, selected thread or family count, active-family exclusion, and projects when
those details affect confidence.

## Shared-Memory Handoff

Do not load or update `shared-memory` automatically. When the user asks to pair the skills, run session recall first and
present each candidate with the claim, target, evidence, confidence, durability, and replacement or expiration
condition. Then let `shared-memory` accept, merge, reject, or write candidates independently. Never pass secrets.
