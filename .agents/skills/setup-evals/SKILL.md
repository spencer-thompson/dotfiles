---
name: setup-evals
description: Set up a project-owned, development-only SQLite evaluation system and its ongoing eval skill when the user explicitly invokes setup-evals. Not for running existing evals or ordinary optimization work.
---

# Set up evidence-driven evals

Build the smallest useful feedback system that future agents can use without prior conversation context. Adapt it to
the project's language, runtime, and existing conventions.

## Inspect the project

Resolve the repository root, read applicable instructions, and inspect status so unrelated work stays intact. Look for
existing measurement tools, fixtures, commands, and the code needed to choose one representative workload. Extend a
useful existing system. Use structural outlines before broad reads; expand investigation when the evidence calls for it.

## Choose a measurement contract

Identify the primary outcome and the measurements needed to explain it. Define a representative, versioned workload,
its expected results, and the conditions that make runs comparable. Read
[references/implementation.md](references/implementation.md) for collection and comparison rules.

## Implement the evaluator

Use the project's native build, dependency, and command mechanisms to provide:

- a development-only collection boundary;
- an ignored local SQLite database with run identity, context, outcomes, and raw observations;
- a standard workload command in an optimized or production-like build;
- tested queries for inspecting and comparing runs.

Read [references/schema.md](references/schema.md) when designing storage. Start with the primary outcome and enough
instrumentation to explain it. Add counters, resource measurements, diagnostic modes, or real-session capture when they
answer a concrete question the standard workload cannot.

## Validate a baseline

Run the evaluator and inspect its output for correct units, expected outcomes, intended control flow, and repeatability.
Repair workload or instrumentation mistakes before establishing a baseline. Check database integrity, foreign keys,
ignore rules, and the queries. Verify the collection boundary as appropriate to the ecosystem and run the project's
required checks plus focused validation for the changed code.

Setup is complete with a validated baseline and usable project skill. If product optimization is also requested, use
that baseline to evaluate a focused change through the ongoing workflow below.

## Document the ongoing workflow

Create a project-owned `evals` skill using [references/project-skill.md](references/project-skill.md). Give it exact
commands, paths, queries, comparison rules, and stopping conditions.

Where useful, document the eval command and skill location in existing repository instructions. Follow the user's
authorization for instruction-file edits; keep additions focused on evaluation.

Finish with the files and commands, verification results, and a compact table of baseline measurements with exact run
IDs, observed variation, and limitations. Include before/after results if optimization was part of the request.
