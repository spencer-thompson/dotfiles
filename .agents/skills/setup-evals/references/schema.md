# SQLite schema guide

Use SQLite's `user_version` or the project's migration mechanism. Apply schema changes atomically. Enable foreign keys
on every connection. WAL with normal synchronization is a good local default when supported, but measure and adapt if
the project has unusual durability or filesystem constraints.

## Core tables

### `runs`

Keep one immutable row per evaluation process or session:

- integer primary key;
- start and finish timestamps plus total elapsed nanoseconds;
- scenario, workload name and version, repetitions, and status;
- code revision, branch, and dirty state;
- build mode and target;
- language runtime, compiler, framework, external-tool, and application versions;
- operating system, architecture, logical CPUs, and any stable machine identifier needed for fair local comparisons;
- exact command, subject repository, optional notes, and valid metadata JSON.

Do not silently compare different workload versions, build modes, machines, or dirty states.

### `phase_samples`

Store each raw timed observation:

- run ID foreign key;
- sequence number unique within the run;
- phase name;
- monotonic start offset and duration in nanoseconds;
- optional subject;
- thread, task, worker, or process label;
- valid dimensions JSON.

Index phase, subject, and run ID. Keep raw samples so later investigations can inspect outliers and new groupings.

### `counter_values`

Store the final nonnegative value for each named counter and run. Counters may cover cache hits and misses, retries,
fallbacks, queue events, coalescing, allocations, processed items, dropped work, or other discrete behavior.

### `measurements`

Store scalar observations that are not timed phases:

- run ID and sequence;
- monotonic recorded offset;
- metric name and explicit unit;
- numeric value;
- whether lower is better;
- optional subject;
- valid dimensions JSON.

Examples include memory, binary or bundle size, allocations, rows, requests, files, output size, throughput, test count,
source size, frame rate, and quality scores.

## Views

Create views for common run-level phase and measurement statistics. Include sample count, minimum, mean, maximum, and
total. Keep subjects and dimensions in the grouping key when those distinctions affect decisions.

Percentiles are useful for large sample sets. Implement them with the SQLite version's supported functions or compute
them in a project-native query tool. Do not fake a percentile from an aggregate-only row.

## Integrity rules

- Use strict tables and JSON validation when the installed SQLite supports them.
- Reject negative durations and counters.
- Store large integer values with checked conversions.
- Use one transaction for a completed run.
- Cascade run deletion only if the project deliberately supports pruning. Normal eval work should append, not delete.
- Keep the database inside an ignored repository-local development directory.
- Never store secrets or sensitive user data.

## Required queries

The project eval skill should include tested queries for:

- recent comparable runs and their revision or dirty state;
- hot phases in the latest run;
- per-subject and per-mode costs;
- outcomes, fallbacks, cache counters, and resource measurements;
- comparison of two explicitly selected run IDs;
- database integrity, foreign keys, and schema version.

Use exact run IDs in reports. Do not rely only on "latest two" after an experiment introduces a different scenario.
