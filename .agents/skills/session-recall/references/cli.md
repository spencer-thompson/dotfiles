# Session Recall CLI Reference

Use SQLite for discovery and aggregate metadata. Read rollout JSONL only for selected threads when message, event, or
detailed workload evidence is required.

## Catalog

`catalog_sessions.py` queries the current `state_5.sqlite` schema read-only.

### List And Rank Threads

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
  --days 3 --top-level-only --sort recency --limit 40 --compact
```

Filtering and ranking run before output projection. `--sort` accepts `recency`, `updated`, `created`, or
`tokens`. `--top-by-tokens N` aliases `--sort tokens --limit N`; `--min-tokens N` filters first.

Discovery filters include `--query`, `--cwd`, `--source`, `--model`, `--reasoning-effort`, `--git-project`,
`--git-branch`, `--named-only`, `--archived`, `--top-level-only`, and repeatable `--exclude-thread`.

Use `--fields FIELD,...` to select and order TSV or JSONL fields. Unknown, empty, or duplicate fields fail. Use
`--compact` for this preset:

```text
thread_id,recency_at,cumulative_tokens,display_name,model,reasoning_effort,
git_project,git_branch,family_size,open_child_count
```

`--fields` and `--compact` are mutually exclusive and cannot accompany `--format paths`. Full selectable fields are:

```text
thread_id,created_at,updated_at,recency_at,archived_at,created_at_ms,updated_at_ms,
recency_at_ms,archived,source,thread_source,model,reasoning_effort,cwd,name,
display_name,title,first_user,rollout_path,agent_role,agent_nickname,agent_path,
cumulative_tokens,git_project,git_branch,git_sha,parent_thread_id,root_thread_id,
family_size,direct_child_count,open_child_count,family_cumulative_tokens,catalog_source
```

Catalog token values are cumulative workloads. The SQLite column remains `tokens_used`; public output uses
`cumulative_tokens` and `family_cumulative_tokens`.

### Thread Families And Statistics

Use `--root-thread-id ROOT` for a known root, `--family THREAD` for any family member, and `--children THREAD` for
direct children. Family navigation disables the implicit three-day window unless an explicit range is supplied.

`stats` accepts catalog filters and groups by `archive`, `family`, `git-branch`, `git-project`, `model`,
`month`, or `reasoning-effort`. It reports `cumulative_tokens` plus average, median, p90, and maximum cumulative
token fields. Formats are JSON, JSONL, and TSV.

### Show Selected Threads

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py show THREAD_ID ... \
  --metadata compact --until REVIEW_CUTOFF_ISO --format jsonl
```

`show` accepts multiple IDs, removes duplicate IDs while preserving requested order, validates every ID and rollout
before output, and applies `--tail` independently per thread. Event filters include `--kind`, `--since`, `--until`,
`--match`, `--ignore-case`, and `--max-chars`.

Metadata modes are:

- `full`: current complete catalog record.
- `compact`: catalog compact fields plus `root_thread_id` and `rollout_path`; bound `display_name` to
  120 characters.
- `none`: retain only `thread_id` as structural batch identity.
- `--events-only`: exact alias for `--metadata none`.

Markdown renders one section per thread. JSON emits one object for one thread and an array for multiple threads. JSONL
always emits one thread envelope per line.

### SQLite Statistics Fields

Stats token fields are `cumulative_tokens`, `average_cumulative_tokens`, `median_cumulative_tokens`,
`p90_cumulative_tokens`, and `max_cumulative_tokens`.

## Rollout Inspector

`inspect_sessions.py` accepts explicit rollout files only. It never discovers directories, ranks threads, reconstructs
families, or replaces catalog metadata. Pass paths positionally or with `--paths-from-stdin`.

### Events Mode

```bash
python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py events ROLLOUT.jsonl \
  --since START_ISO --until REVIEW_CUTOFF_ISO \
  --kind user --kind assistant --match 'decision|remember|blocked' --ignore-case --tail 30
```

Events are timestamped, line-numbered JSONL. Stable IDs are deduplicated across selected rollouts unless
`--no-dedupe` is supplied. Redaction is on by default. `--unredacted` and `--no-redact` expose raw details and may
reveal credentials, private data, or large payloads.

### Summary Mode

```bash
python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py summary ROLLOUT.jsonl ... \
  --since START_ISO --until REVIEW_CUTOFF_ISO --aggregate --compact
```

Summary mode computes range-scoped message, activity, turn, duration, token-delta, tool, command, file-change, MCP,
compaction, replay, media, model, effort, malformed-line, and rollout-size metrics.

Use `--fields FIELD,...` to select and order output fields. Use `--compact` for a bounded overview that retains
identity, event bounds, completeness indicators, workload totals, failure counts, models, efforts, and top counters.
Projection never changes calculations.

Counters `tools`, `command_families`, and `mcp_tools` are JSON objects. Without `--counter-limit`, all entries are
included. `--counter-limit N` retains the N largest entries in each counter; `0` emits empty objects. Compact mode
defaults to five entries unless overridden.

Every record includes explicit counter completeness fields. These report whether each counter was truncated, its total
distinct keys, and the workload omitted from the rendered counter:

```text
tools_truncated,tools_distinct,tool_calls_omitted
command_families_truncated,command_families_distinct,command_executions_omitted
mcp_tools_truncated,mcp_tools_distinct,mcp_calls_omitted
```

Each rollout has `sessions: 1`; aggregate output reports its actual session count. Full TSV uses the same public field
schema as JSONL, including `sessions`, `first_event_at`, `token_delta_complete`, cache-write tokens, and completeness
metrics. Structured values use compact JSON inside one TSV cell. Custom fields preserve requested order in both formats.

Inspector tokens are deltas between cumulative snapshots around the requested range. Check `token_delta_complete`;
false means no pre-range baseline existed and the value may include earlier use. Active duration excludes idle gaps.
