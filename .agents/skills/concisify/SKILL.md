---
name: concisify
description: Make writing, files, outputs, or code as concise as possible while preserving important meaning and easy understanding. Use when asked to shorten, tighten, or remove verbosity; use compress for aggressive size reduction that sacrifices readability.
---

# Concisify

Produce the shortest clear version that serves the intended reader or user. Optimize for both brevity and ease of
understanding: fewer words or lines are useful only when they reduce the work of understanding.

## Edit for purpose

- Infer the audience, purpose, and required content from context. Ask only when uncertainty would materially change
  what can be removed.
- Remove repetition, filler, unnecessary framing, and details that do not serve the purpose. Preserve important
  meaning, qualifications, constraints, evidence, and actionable next steps. Do not turn uncertainty into certainty.
- Prefer direct language, precise terms, and useful structure. Combine or reorganize sections, replace prose with a
  table, or reshape code when that communicates more efficiently. Preserve required formats and interfaces.
- Keep enough context for the result to stand on its own in its intended setting. Avoid cryptic abbreviations,
  unexplained shorthand, and compression that makes readers reconstruct missing connections.

## Code and structured files

Preserve behavior, externally used names, data, and format requirements unless changes are requested. Remove redundant
logic and unnecessary indirection; keep meaningful names and straightforward control flow. Avoid dense one-liners,
code golf, and abstractions that merely hide the same complexity elsewhere. Retain comments that explain necessary
intent or constraints; remove comments that only repeat the code.

## Finish

Work within the requested scope. Check that every retained part earns its space and that further shortening would
lose useful meaning or make understanding harder. Verify prose against the original intent and validate code or
structured files with checks proportionate to the changes.

For a requested rewrite, return the result directly. For file edits, briefly report the outcome and relevant
verification. Include size comparisons only when useful or requested.
