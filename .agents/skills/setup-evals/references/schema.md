# SQLite schema guide

Adapt these shapes to the measurement contract. Start with `runs` and the observation storage needed for the primary
outcome; add other tables and indexes when there is a query that needs them.

Use SQLite's `user_version` or project migrations, with atomic schema changes and foreign keys enabled on every
connection. Store the database in an ignored repository-local development directory.

## Runs and code identity

Keep one run per evaluation process or session, including:

- run ID, timestamps, elapsed time, status, and workload outcome;
- scenario, workload version, warm-up count, and measured repetition count;
- code revision, dirty state, and a source or patch fingerprint;
- build mode and relevant runtime, tool, and machine context;
- exact command, with sensitive arguments redacted, and any comparison-relevant metadata.

A revision plus `dirty: true` cannot distinguish successive uncommitted changes. Fingerprint the relevant source state,
including staged, unstaged, and relevant untracked inputs. Record the fingerprint method and scope; exclude generated
measurements and unrelated files. Store the digest rather than sensitive source or patch contents. Tie this identity to
the artifact actually executed, rebuilding as needed.

Completed runs are immutable. For streaming sessions, allow an active run to accumulate observations and finalize its
status; interrupted or failed runs must not appear as successful baselines. Preserve rejected experiments as evidence.

## Observations

Retain raw samples with run ID, sequence or iteration, metric name, explicit unit, value, and any relevant subject or
dimensions. Record the metric's meaning and desired direction in the measurement contract.

Use dedicated shapes when helpful:

- `phase_samples`: phase, monotonic start offset, duration, and parent or worker identity where overlap matters;
- `counter_values`: named counts, with subject or iteration dimensions if needed;
- `measurements`: scalar values such as memory, throughput, or output size, with recorded offsets when useful.

Keep timing semantics in the metric definition. Distinguish process runs from iterations within a run in storage so
queries preserve the sampling unit.

## Integrity and queries

Use constraints for valid foreign keys, unique sample sequences within their scope, nonnegative durations and counters,
and valid metadata JSON. Prefer strict tables when supported and use checked conversions for large integers. Persist
completed short runs atomically; commit long-session batches atomically and finalize the run explicitly.

Provide tested queries for:

- recent runs with status, code identity, and comparison conditions;
- the primary outcome and the measurements explaining it;
- a comparison of two explicitly selected run IDs;
- database integrity, foreign keys, and schema version.

Summaries should show sample count, central tendency, and variation while retaining meaningful subjects and dimensions.
Aggregate according to the metric: totals of memory snapshots or overlapping phases are not peak memory or wall time.
Compute percentiles from raw samples only when the sample size and query tooling justify them. Add further queries or
views as the instrumentation grows.
