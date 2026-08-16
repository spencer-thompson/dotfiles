---
name: simplify
description: Use when asked to simplify code, clean up tech debt, improve readability, reduce complexity, or make a codebase easier to maintain.
---

# Goal

Improve the codebase by making it simpler, clearer, more maintainable, and easier to reason about.

The goal is **not** to make the code look more architected. The goal is to make future changes safer and easier.

Optimize for:

- Less code
- Fewer concepts
- Fewer private/helper functions when they do not improve clarity
- Less duplication
- Clearer names
- More direct control flow
- Smaller public/API surface area
- More obvious behavior
- Better locality of related logic
- Fewer unnecessary abstractions
- Tests that protect behavior

## Principles

### Prefer deletion over abstraction

Before creating a new abstraction, look for code that can be deleted, inlined, merged, or simplified.

Good cleanup often means removing:

- Dead code
- Unused functions and parameters
- Redundant wrappers
- Trivial private helpers
- Duplicate logic
- Obsolete comments
- Unneeded config
- Overly defensive code that is not needed

Do not add abstractions just because two things look similar. Abstract only when the abstraction makes the code easier
to understand and change.

The best cleanup often has a negative diff.

### Inline weak helpers

Private functions should earn their existence.

Inline private functions when they are:

- Used only once
- Shorter than their name implies
- Merely forwarding arguments
- Hiding important logic from the reader
- Causing the reader to jump around unnecessarily
- Splitting one simple flow into many tiny fragments

Keep private helpers when they:

- Encapsulate a genuinely reusable concept
- Give a meaningful name to non-obvious logic
- Isolate side effects
- Make tests clearer
- Separate different levels of detail
- Reduce meaningful duplication

### Avoid

Do not "clean up" by adding layers.

Do not count as cleanup:

- New abstractions without clear payoff
- Interfaces with one implementation
- Factories/builders/registries without need
- Generic utilities for two call sites
- Moving code without simplifying it
- Extracting many tiny functions and/or helpers
- Adding configuration instead of simplifying code
- Reformatting large files without semantic improvement
- Renaming without improving meaning

### Consolidate carefully

Consolidate duplicated logic only when the shared version is clearer.

Small obvious duplication is better than confusing reuse.

Do not create awkward abstractions for code that merely looks similar.

### Rename for meaning

Use names that explain intent, not mechanics.

Avoid vague names like `handle`, `process`, `run`, `execute`, `data`, `item`, `manager`, `helper`, `utils`, `result`,
and `config` unless the scope makes them obvious.

### Prefer direct control flow

Use straightforward code.

Prefer early returns, explicit conditionals, clear local variables, and nearby related logic.

Avoid clever chains, deep nesting, vague service layers, generic utility modules, and premature extension points.

### Preserve behavior

Do not change behavior unless asked.

Before and after changes, run relevant tests, type checks, and linters when available.

## Optional Subagents

Use subagents only when broad, separable, read-heavy discovery would materially improve speed or coverage. Handle
focused or tightly coupled cleanup directly.

If using subagents:

- Give each one a disjoint package, module, or question to inspect.
- Keep discovery agents read-only and ask for evidence-backed simplification candidates.
- Keep implementation and final verification with one owner unless the user explicitly requests parallel edits.
- Do not let multiple agents edit the same files or overlapping control flow.

## Process

1. Understand the target area(s).
2. Find complexity hotspots.
3. Delete dead/redundant code.
4. Inline weak helpers.
5. Simplify control flow.
6. Consolidate meaningful duplication.
7. Rename unclear symbols.
8. Remove unnecessary abstractions.
9. Verify behavior.
10. Summarize what became simpler.

## Final Response

Report:

- What was removed
- What was inlined
- What was consolidated
- What was renamed
- What was verified
- Any risks or follow-up opportunities

Use concrete numbers when useful:

- Lines removed
- Functions removed
- Files simplified
- Duplicate paths merged
- Abstractions removed
- Public API reduced

When in doubt, make the code more boring, direct, and obvious.
