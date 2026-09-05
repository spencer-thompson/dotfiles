---
name: setup-evals
description: Set up a project-owned, development-only SQLite evaluation system and its ongoing eval-loop skill when the user explicitly invokes setup-evals. Not for running existing evals or ordinary optimization work.
---

# Set up evidence-driven evals

Build a trustworthy feedback system that future agents can use without prior conversation context. Adapt it to the
project's language, runtime, architecture, and existing conventions.

## Start with the project

Before editing:

- Resolve the repository root and inspect its status. Preserve unrelated work.
- Read every applicable instruction file, build manifest, test command, architecture note, and existing skill related
  to performance or development workflows.
- Map startup, user-visible latency, repeated work, concurrency, caches, external processes, memory ownership,
  fallbacks, retries, and quality gates. Use structural outlines before broad reads in an unfamiliar codebase.
- Find existing benchmarks, profilers, telemetry, fixtures, local databases, ignored development directories, and
  command runners. Extend a good existing system instead of creating a parallel one.

Read [references/implementation.md](references/implementation.md) and
[references/schema.md](references/schema.md) before designing the system.

## Build the system

Create a concrete plan, then implement the smallest complete version that provides:

1. A development-only instrumentation boundary that ordinary production builds exclude or leave effectively free.
2. An ignored local SQLite database with append-only runs, raw phase samples, counters, scalar measurements, revision
   and dirty-state metadata, workload identity, build/runtime context, and evolving dimensions.
3. A deterministic standard workload that follows the product's real control flow in an optimized or production-like
   build.
4. Separately named diagnostic modes for exhaustive depths, fault injection, cache bypasses, or stress work that would
   distort normal totals.
5. A real-session collection path when synthetic work cannot represent important behavior.
6. Project-native commands for running, querying, and validating evals.
7. A project-owned ongoing `evals` skill. Read
   [references/project-skill.md](references/project-skill.md) before creating it.

Do not transplant one language's implementation into another. Use the project's native conditional-build,
dependency, migration, testing, and command mechanisms.

## Prove the loop

Run the evaluator before making a product optimization. Inspect the resulting database for integrity, comparability,
hot phases, outliers, per-subject costs, fallbacks, cache behavior, and resource tradeoffs.

If the first evidence exposes a workload or instrumentation mistake, repair the evaluator and establish a new baseline.
Then complete one evidence-backed improvement when the data reveals a worthwhile target. Run focused checks, the full
project gate, and the exact same eval command afterward. Keep or reject the change based on both the measurements and
the code.

Preserve rejected runs. They are evidence, not clutter.

## Propose repository instructions

Read [references/agents-proposal.md](references/agents-proposal.md). Inspect every applicable `AGENTS.md` first.

- If one exists, propose a focused patch that adds the evaluation workflow, project autonomy, readable-code standard,
  and permission for clear, concise checkpoint commits.
- If none exists, propose a small complete `AGENTS.md` containing those policies and any project-specific commands or
  boundaries discovered during setup.
- Present the exact Markdown and rationale. Do not edit `AGENTS.md` unless the user separately approves applying the
  proposal or explicitly included that approval in the request.

Autonomy and commit permission stay inside the repository. They do not authorize pushes, force operations, releases,
deployments, external messages, production mutations, or bypassing approval requirements.

## Validate and hand off

Verify:

- the skill and schema are valid;
- the database passes integrity and foreign-key checks;
- standard and diagnostic modes exercise the intended control flow;
- feature-off and feature-on builds both pass;
- the normal artifact excludes evaluation-only dependencies and flags where the ecosystem permits;
- project formatting, linting, tests, and link checks pass;
- the local database is ignored and no generated measurements are staged;
- the ongoing eval skill tells future agents exactly which commands, paths, queries, comparison rules, and stopping
  conditions to use.

Finish with a compact inventory of files and commands, the proposed `AGENTS.md` change, verification results, and an
honest table of the initial runs. Include wins, regressions, noise, external bottlenecks, and accepted tradeoffs.
