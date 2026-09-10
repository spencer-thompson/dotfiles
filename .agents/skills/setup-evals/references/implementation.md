# Collection and comparison guide

## Measurement contract

Start with one decision: what user-visible delay, repeated cost, or resource constraint needs to be understood? Name the
primary metric, unit, direction, collection point, and expected outcome. Add subjects and dimensions only when they help
explain that result, including whether a cost belongs to project code or an external tool.

## Collection boundary

Choose the simplest native development boundary: an optional build feature, separate target, development entrypoint,
benchmark package, or gated collector. Evaluation-only dependencies must stay out of the production artifact. Verify
normal and instrumented execution using the ecosystem's relevant checks. If runtime gating leaves work in production,
measure the disabled path and keep its cost effectively free.

Use monotonic clocks for durations and wall clocks for timestamps. Avoid formatting dimensions while collection is
disabled. Collect in memory and flush a completed run in one transaction; use bounded buffers and periodic transactions
for long sessions. Measure observer overhead when collection could materially affect the result, especially if it does
I/O in a timed path.

Define phase durations as inclusive or exclusive. Nested and concurrent samples can overlap: their sum is not
necessarily end-to-end wall time. Measure the primary latency separately and label phase totals as accumulated work. Add
parent or worker identifiers when needed to interpret overlap.

Keep secrets and sensitive user content out of measurements and metadata, including commands and subjects. Use safe
labels or classifications where necessary.

## Standard workload

Use deterministic, versioned inputs and representative control flow, including normal cache reuse and fallback behavior.
Record expected outcomes as well as durations so skipping work cannot look like a speedup. Keep the build mode optimized
or production-like, and document runtime versions, inputs, and cache conditions needed to reproduce it.

Warm up when startup is not the question; keep cold starts when it is. Record warm-up and measured iterations
separately. A cold-start scenario can be standard when startup is the target. Add separately named diagnostic modes only
for useful experiments that change the comparison conditions, such as forced cache bypasses, exhaustive sweeps, or
stress work. Use real-session capture when synthetic inputs cannot represent important behavior.

Keep the standard workload local and reproducible. Network, production systems, paid services, or mutable shared state
require the user's authorization.

## Evidence quality

Choose repetitions appropriate to runtime and noise; three measured repetitions can be a starting point, not proof of a
speedup. Distinguish independent process runs from iterations sharing a process, cache, or runtime. For each reported
metric, include the sample count and a useful measure of variation, such as a range or interquartile range.

Compare explicitly selected run IDs with matching workload versions, build modes, machines, runtime conditions, and
relevant subjects or dimensions. Identify the code measured using the schema's source fingerprint; different code is the
intended comparison, while unrelated environmental changes must be accounted for. If the evaluator or workload changes,
establish a new baseline or rerun both implementations under the revised contract.

When a difference is close to normal variability, gather more independent runs and alternate before/after order when
practical. Stop when further measurement is disproportionate and report the result as inconclusive. Do not attribute
machine noise or faster external tools to a project optimization.

## Project commands

Use the repository's command runner and normal dependency locking. Provide a standard command such as `evals`, plus tested
queries or a query command when useful. Document the database path, build mode, scenario, workload version, warm-up and
repetition settings, and required tools. Each invocation should report its run ID. Name additional collection modes
separately and explain their comparison limits.
