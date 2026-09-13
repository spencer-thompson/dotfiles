---
name: simplify
description: Use when asked to simplify code, clean up tech debt, improve readability, reduce complexity, or make a codebase easier to maintain.
---

# Simplify

Make the requested code easier to understand and change while preserving behavior unless a behavior change is requested.
Prefer fewer concepts, direct control flow, meaningful names, and good locality over mechanically reducing line counts.

## Choose useful changes

- Look for dead code, redundant wrappers, obsolete configuration, and duplication that can be removed or consolidated.
  Confirm intended use through call sites, types, tests, or documented behavior before deleting code.
- Challenge speculative extension points, repeated validation, impossible-state branches, and error-hiding fallbacks.
  Preserve defenses for reachable failures and real boundaries: untrusted input, external systems, security, stored
  data, concurrency, and resource cleanup.
- Extract or inline according to whether the boundary improves understanding, testing, or change locality. A helper
  used once is a candidate to inspect, not an automatic deletion. Keep helpers that name non-obvious concepts, isolate
  side effects, separate levels of detail, or make tests clearer.
- Consolidate duplication only when the shared version is easier to understand and change. Small, obvious duplication
  can be clearer than an abstraction joining code with different reasons to change.
- Add interfaces, factories, utilities, or configuration only when they solve a concrete problem in scope. Moving code,
  renaming symbols, or adding layers is useful only when it improves understanding or maintenance.
- Prefer early returns, clear local variables, and straightforward conditionals. Rename vague symbols when their
  meaning is not already obvious from the local context.

Choose actions that address the actual complexity; this is not a checklist of transformations to perform on every task.

## Verification

Run checks proportionate to the changed behavior and required repository gates. Run a baseline before editing when it
helps establish uncertain behavior or distinguish existing failures. After relevant checks pass, repeat or broaden them
only for new changes, failures, or unresolved concerns. Preserve tests that protect meaningful behavior.

## Optional Subagents

Use subagents only when broad, separable, read-heavy discovery would materially improve speed or coverage. Handle
focused or tightly coupled cleanup directly.

If using subagents:

- Give each one a disjoint package, module, or question to inspect.
- Keep discovery agents read-only and ask for evidence-backed simplification candidates.
- Keep implementation and final verification with one owner unless the user explicitly requests parallel edits.
- Do not let multiple agents edit the same files or overlapping control flow.

## Report

Briefly explain what became simpler, how behavior was verified, and any material limitations. Include counts or
before/after examples when they help explain the result; omit irrelevant reporting categories.
