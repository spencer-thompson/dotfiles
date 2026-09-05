# Session Recall CLI Reference

Use SQLite for discovery and aggregate metadata. Read rollout JSONL only for selected threads when message, event, or
detailed workload evidence is required.

## Catalog

`catalog_sessions.py` queries the current `state_5.sqlite` schema read-only.

### List And Rank Threads

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
  --since START_ISO --until REVIEW_CUTOFF_ISO \
  --top-level-only --exclude-thread-source guardian_review \
  --sort recency --limit 40 --compact
```

Filtering and ranking run before output projection. `--sort` accepts `recency`, `updated`, `created`, or
`tokens`. `--top-by-tokens N` aliases `--sort tokens --limit N`; `--min-tokens N` filters first.

Discovery filters include `--since`, `--until`, `--query`, `--cwd`, `--source`, `--model`, `--reasoning-effort`,
`--git-project`, `--git-branch`, `--named-only`, `--archived`, `--top-level-only`, repeatable `--exclude-thread`, and
repeatable case-insensitive exact `--exclude-thread-source`. Exclusions apply before sorting and limiting.
Use the same exact start and cutoff for catalog discovery and rollout inspection so out-of-range rollouts are never
selected merely to produce empty summaries.

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

`open_child_count` counts direct children whose stored `thread_spawn_edges.status` is `open`. It is catalog metadata,
not a live process check, and it may remain open after a child has returned a final response. Use rollout events or the
agent-management tools when actual execution status matters.

### Thread Families And Statistics

Use `--root-thread-id ROOT` for a known root, `--family THREAD` for any family member, and `--children THREAD` for
direct children. Family navigation disables the implicit three-day window unless an explicit range is supplied.

`stats` accepts catalog filters and groups by `archive`, `family`, `git-branch`, `git-project`, `model`,
`month`, or `reasoning-effort`. It reports `cumulative_tokens` plus average, median, p90, and maximum cumulative
token fields. Formats are JSON, JSONL, and TSV.

Aggregate exact-range workload for one family without reconstructing it from rollout files manually:

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
  --family THREAD_ID --format paths \
| python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py summary \
  --paths-from-stdin --since START_ISO --until REVIEW_CUTOFF_ISO --aggregate --compact
```

### Show Selected Threads

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py show THREAD_ID ... \
  --metadata compact --until REVIEW_CUTOFF_ISO --format jsonl
```

`show` accepts multiple IDs, removes duplicate IDs while preserving requested order, validates every ID and rollout
before output, and applies `--tail` independently per thread. Event filters include `--kind`, `--since`, `--until`,
`--match`, `--input-match`, `--ignore-case`, `--max-chars`, `--raw`, and `--metadata-only`.

Peek at the latest assistant message from each selected thread (this can be a progress update or unrelated side task,
not necessarily a substantive final answer):

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py show THREAD_ID ... \
  --events-only --kind assistant --tail 1 --until REVIEW_CUTOFF_ISO --format jsonl
```

When that peek is insufficient, search a specific topic across the selected IDs without loading whole transcripts:

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py show THREAD_ID ... \
  --events-only --kind user --kind assistant --match 'TOPIC|ARTIFACT|ISSUE_ID' --ignore-case \
  --since START_ISO --until REVIEW_CUTOFF_ISO --tail 8 --max-chars 3000 --format jsonl
```

`list --query` searches name, title, first user message, cwd, Git origin, and branch; it does not search later messages.
Use `show --match` for conversation content after selecting candidates. An empty catalog search is not evidence that
the topic was never discussed. For completion verification, omit the message-kind restriction and target the relevant
tool result or artifact. Read later topic matches before treating an earlier decision as final.

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
`--no-dedupe` is supplied.

By default, messages and payload details are bounded by `--max-chars` and known secret patterns are replaced with
`[REDACTED]`. Tool calls, outputs, commands, file changes, and MCP events expose string previews rather than their raw
structured values. Use `--metadata-only` to omit payload previews. Use `--raw` for complete unredacted messages and
payloads; this bypasses `--max-chars` and may expose secrets, personal data, or large outputs. The two modes are
mutually exclusive.

Use repeatable `--input-match REGEX` to search complete custom or function tool inputs before preview rendering.
Repeated input patterns use OR semantics. When combined with `--match`, an event must satisfy both filter classes.
`catalog_sessions.py show` supports the same filters and payload modes.

### Summary Mode

```bash
python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py summary ROLLOUT.jsonl ... \
  --since START_ISO --until REVIEW_CUTOFF_ISO --aggregate --compact
```

Summary mode computes range-scoped message, activity, turn, duration, token-delta, tool, command, file-change, MCP,
compaction, replay, media, model, effort, malformed-line, rollout-size, and execution-overlap metrics.

Repeatable `--require-tool TOOL` retains only rollouts that used every named tool inside the requested range. Filtering
happens before sorting, limiting, aggregation, counter projection, and output formatting. It uses the complete internal
tool counter, so `--counter-limit` cannot hide or alter a match.

Find top-level sessions that used `spawn_agent` without rendering unrelated summaries:

```bash
python3 ~/.agents/skills/session-recall/scripts/catalog_sessions.py list \
  --since START_ISO --until REVIEW_CUTOFF_ISO --top-level-only --format paths \
| python3 ~/.agents/skills/session-recall/scripts/inspect_sessions.py summary \
  --paths-from-stdin --since START_ISO --until REVIEW_CUTOFF_ISO \
  --require-tool spawn_agent --fields session_id,first_event_at,last_event_at,tools
```

Use `--fields FIELD,...` to select and order output fields. Use `--compact` for a bounded overview that retains
identity, event bounds, completeness indicators, workload totals, failure counts, models, efforts, and top counters.
Projection never changes calculations. Use `--list-fields` without rollout paths to print every selectable field.
Unknown fields report nearby names.

Full selectable summary fields are:

```text
kind,path,session_id,sessions,first_event_at,last_event_at,rollout_bytes,
records_in_range,malformed_lines,activity_events,user_messages,assistant_messages,
visible_messages,tool_calls,custom_tool_calls,function_tool_calls,tools,
tools_truncated,tools_distinct,tool_calls_omitted,completed_turns,aborted_turns,
active_duration_ms,average_time_to_first_token_ms,execution_items,parallel_groups,
parallel_execution_items,max_concurrency,execution_work_ms,execution_wall_ms,
execution_overlap_ms,failed_parallel_groups,successful_siblings_in_failed_groups,
command_executions,command_successes,command_failures,command_duration_ms,
command_families,command_families_truncated,command_families_distinct,
command_executions_omitted,file_change_events,files_changed,mcp_calls,mcp_failures,
mcp_duration_ms,mcp_tools,mcp_tools_truncated,mcp_tools_distinct,mcp_calls_omitted,
compactions,image_inputs,audio_inputs,replayed_events,model_context_window,
token_snapshots_in_range,token_delta_complete,input_tokens,cached_input_tokens,
cache_write_input_tokens,output_tokens,reasoning_output_tokens,total_tokens,models,
reasoning_efforts
```

`tool_calls` counts model-visible tool calls. `custom_tool_calls` and `function_tool_calls` partition that total by
response-item type.

Execution metrics use completed command, MCP, image-view, and extension intervals that contain recorded start and end
times:

- `execution_items` counts those intervals.
- `parallel_groups` counts connected groups containing overlapping intervals; `parallel_execution_items` counts their
  members.
- `max_concurrency` is the largest number of intervals active at once.
- `execution_work_ms` sums interval durations. `execution_wall_ms` sums their union. `execution_overlap_ms` is the
  difference between those values.
- `failed_parallel_groups` counts overlapping groups containing a failed execution.
  `successful_siblings_in_failed_groups` counts the other non-failed executions in those groups.

These are observed execution intervals. `execution_overlap_ms` is not a claim about end-to-end latency saved.
Aggregate summaries sum interval metrics across rollouts and take the maximum `max_concurrency`.

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

Catalog cumulative tokens rank whole-thread workload; inspector deltas describe the requested event range.
Message counts, tokens, tools, bytes, and duration measure different things. Output projections (`--compact`,
`--fields`, metadata modes, and counter limits) do not change filtering, ranking, calculations, or evidence collection.
Preserve truncation, distinct-count, and omitted-count fields when handing off or storing limited counters.
