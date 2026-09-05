# Implementation guide

## Design from questions

Start with decisions the project needs to make:

- What delays readiness, the first useful result, or the next interaction?
- Which repeated phase owns wall time or allocations?
- Which file, request, route, query, frame, job, asset, or batch is expensive?
- When does the product escalate, retry, fall back, miss cache, queue work, or cross a process boundary?
- Which costs belong to project code and which belong to an external tool?
- What correctness and maintainability checks must remain true after optimization?

Turn these questions into a measurement contract. Name each metric, unit, subject, dimensions, direction, collection
point, expected frequency, and decision it supports. Avoid collecting values with no plausible use.

## Development-only boundaries

Choose the cleanest native boundary available:

| Ecosystem shape | Useful boundary |
| --- | --- |
| Compiled application | Optional feature, build tag, compilation flag, source set, or separate development target |
| Python project | Optional dependency group, development entrypoint, environment-gated collector, or benchmark package |
| JavaScript or TypeScript | Development-only entrypoint, package script, conditional import, or separate benchmark bundle |
| JVM or .NET | Development profile, source set, conditional symbol, benchmark project, or test fixture |
| Mobile or game project | Development configuration, editor-only module, benchmark scene, or instrumentation build |
| Data or infrastructure project | Local runner around representative plans, queries, transformations, or simulations |

Prefer compile-time exclusion when it stays simple. Environment gating is acceptable when the normal disabled path is
measured and effectively free. Evaluation-only dependencies must not leak into the production artifact.

Collect in memory and flush in one transaction when crash survival is not important. Use bounded buffering or periodic
transactions for long sessions. Never put database I/O directly in a latency-sensitive phase without measuring the
observer cost.

## Instrument real ownership boundaries

Record raw durations for startup phases, repeated hot paths, per-subject work, external calls, serialization, rendering,
queue waits, cache operations, retries, fallbacks, persistence, and cleanup when they matter to the product.

Useful dimensions include workload version, iteration, path or stable subject, operation, outcome, algorithm mode,
depth or limit, batch size, cache state, thread or task, input size, output size, and error category. Avoid secrets,
credentials, customer data, raw prompts, or sensitive source content. Hash or classify subjects when local paths are
still too sensitive.

Timers should add almost no work while disabled. When enabled, avoid formatting dimensions until collection is active.
Use monotonic clocks for duration and wall clocks only for run identity.

## Workloads

The standard workload is the comparison contract. It should:

- be deterministic and versioned;
- use representative input types, sizes, states, and control flow;
- follow real cache reuse and algorithm escalation;
- run in the same optimized mode for every comparison;
- use at least three measured repetitions by default;
- record outcomes, not just durations;
- avoid network, production systems, paid services, and mutable shared state unless the user explicitly authorizes them.

Build a separate real-session mode when the application depends on human interaction or organic inputs. Keep exhaustive
algorithm sweeps, failure injection, cold-cache studies, and stress tests in named diagnostic modes.

Warm up runtimes when startup is not the question. Keep cold starts when startup is the question. Record which one the
scenario measures.

## Project commands

Use the repository's existing runner. Add names that another agent can guess, such as:

- `evals` for the standard comparable workload;
- `evals-depth`, `evals-stress`, or another specific name for diagnostics;
- `evals-query` only when a stable summary query materially helps;
- an interactive command or flag that writes to the same database on normal exit.

Commands must pin or lock dependencies when the project normally does. Document the exact database path, build mode,
default repetitions, scenario name, workload version, and any required external executable.

## Initial evaluation loop

1. Validate the evaluator and run the standard workload.
2. Check schema version, integrity, foreign keys, row counts, run metadata, units, and dimensions.
3. Query phase totals, means, maxima, per-subject costs, resource measurements, outcomes, and counters.
4. Confirm the standard workload followed the product's real control flow.
5. Repair instrumentation or workload errors before treating the run as a product baseline.
6. Select one large actionable cost owned by the project.
7. Make one coherent change with a correctness test when behavior or concurrency changes.
8. Run focused checks and the full project gate.
9. Repeat the exact same evaluation command.
10. Compare matching scenarios, workloads, repetitions, build modes, subjects, and dimensions.
11. Keep the change only when the evidence and readability justify it. Preserve rejected runs and revert rejected code
    with a safe method that does not discard unrelated work.

Do not claim project speedups from faster external tools, machine-frequency noise, or a changed workload. Repeat noisy
measurements. Report memory, binary size, allocations, and complexity when the optimization can affect them.

## Completion standard

The setup is complete when a future agent can enter with no prior context, invoke the project eval skill, reproduce the
standard run, query the database correctly, make and verify a change, reject a bad experiment, and explain the result
with exact run IDs.
