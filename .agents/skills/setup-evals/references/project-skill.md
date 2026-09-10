# Ongoing project eval skill

Create a project-owned skill, normally named `evals`, for running and interpreting evaluations, investigating performance, and
assessing changes with a plausible performance effect. Follow the repository's skill location; if none exists, keep one
tracked source and document how agents discover it. Preserve any project preference for manual invocation.

## Project-specific instructions

Name the exact commands, database path, standard workload and version, warm-up and repetition settings, required tools,
and applicable correctness checks. Link a project-owned schema/query reference with queries tested against the database.
Document additional collection modes only if implemented, including which results are comparable.

Translate the relevant collection and comparison rules from this setup skill into project-specific instructions. The
result must work without this installer or prior conversation context, including source identification, timing
semantics, sampling units, variation, and inconclusive results.

## Workflow and scope

Use evals to assess the requested change. Pursue additional optimizations only when they fall within the user's scope;
ordinary cleanup does not automatically require a performance investigation.

For measurement-only requests, run, query, and report without requiring a code change. For implementation work:

1. Inspect status and preserve unrelated work; run a relevant baseline before changing product code.
2. Make the requested change, using evidence to select a target when optimization is the task.
3. Run focused correctness checks and the project's required gates, then repeat the same eval command.
4. Compare explicit run IDs under equivalent conditions. Consider correctness, performance, readability, and resource
   tradeoffs relevant to the change. Keep negative runs; safely revert rejected code without discarding unrelated work.

Complete the requested task before pursuing another target. In an open-ended optimization task, stop when remaining
costs are noise, external, deliberate, or require disproportionate complexity. A correct cleanup may be worthwhile
without a measurable speedup; judge it against the actual goal.

## Reporting

Show exact run IDs, sample counts, variation, and relevant results in a concise table. Use before/after columns only for
comparisons. State wins, regressions, inconclusive measurements, external bottlenecks, and accepted tradeoffs when
present. Report verification results and any limits on the conclusion.
