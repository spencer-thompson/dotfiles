# Ongoing project eval skill

Create a project-owned skill, normally named `evals`, that future agents can discover during performance, regression,
profiling, simplification, or performance-sensitive refactoring work. Follow the repository's established project-skill
location. If no convention exists, keep one tracked source of truth and document any local discovery link or install.

## Required content

The skill must name exact project commands, the local database path, standard scenario and workload version, default
repetitions, required tools, and the full correctness gate.

Its workflow should require:

1. inspect status and preserve unrelated changes;
2. run the standard eval before editing;
3. query the new run and find the largest actionable project-owned issue;
4. inspect the owning code and tests;
5. make one coherent evidence-backed change;
6. run focused checks, then the complete project gate;
7. rerun the identical eval command;
8. compare matching run IDs, conditions, subjects, and dimensions;
9. keep or reject the change based on speed, correctness, memory, size, complexity, and readability;
10. repeat only while another worthwhile target remains.

Stop when the remaining cost is noise, external, deliberate, or would require disproportionate complexity. Never alter
the workload or environment to manufacture a win. Keep negative runs.

## Collection modes

Document the standard deterministic command first. Then document separately named diagnostic modes and the real-session
capture path. Explain which results are comparable and which are exploratory.

## Query reference

Link a project-owned schema/query reference. Test every included query against the created database. Queries should
cover recent runs, phase hotspots, per-subject costs, algorithm outcomes, resources, counters, and explicit before/after
run IDs.

## Reporting contract

Require a concise table:

| Metric | Before run | After run | Change | Read |
| --- | ---: | ---: | ---: | --- |
| User-visible latency | `run 12: 18.7 ms` | `run 13: 14.2 ms` | `-24%` | Good |
| Peak memory | `run 12: 35.3 MiB` | `run 13: 39.8 MiB` | `+13%` | Bad, accepted tradeoff |

The report must include both good and bad results, noise, external bottlenecks, unfair comparisons, and accepted
tradeoffs. It should state whether the complete project gate passed and name the next worthwhile target, if one exists.

## Invocation

Automatic invocation is usually useful for the ongoing project skill because it should guide ordinary performance work.
Respect an existing project policy or explicit user preference that requires manual invocation instead.
