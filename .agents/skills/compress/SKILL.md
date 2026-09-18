---
name: compress
description: Aggressively minimize the representation of text, files, outputs, or code when compactness takes priority over readability, including minification and code golf. Use for requests to sacrifice readability for size; ordinary clear shortening belongs to concisify.
---

# Compress

Seek the smallest representation that preserves the required meaning or behavior. Readability is expendable; accuracy
and usability by the intended consumer are not. Do not add obscurity that saves no space.

## Establish the target

Infer what must survive and how the result will be consumed. Preserve all substantive meaning or observable behavior
unless the user authorizes omissions or changes. Clarify only ambiguities that materially affect the result.

Optimize the requested measure: tokens, bytes, characters, or a hard size limit. Without one, minimize characters for
text and source code. Fewer characters do not necessarily mean fewer model tokens. Include any required legend,
decoder, imports, or other added machinery in the total; moving content elsewhere is not compression.

## Reduce aggressively

- For text, remove grammatical scaffolding and repetition; use dense notation, abbreviations, symbols, and compact
  structure. Preserve necessary relationships, negation, quantities, units, conditions, and uncertainty. Required
  meaning must remain recoverable by the intended consumer, even if it takes effort.
- For code, use minification, short internal names, terse expressions, and compact equivalent algorithms. Preserve
  public interfaces, side effects, evaluation order, reachable errors, and language semantics. Remove whitespace and
  comments only where safe; retain required notices and functional directives.
- For structured files, remove optional formatting and redundancy while respecting the consumer's schema. Rename
  keys or change formats only when compatible with their use.
- Use encoded or binary representations when the destination accepts them and the complete representation is smaller.
  Do not assume an undeclared dictionary, decoder, or external context.

## Verify and deliver

Compare the result with the original for preserved meaning or behavior. Parse, execute, test, or round-trip as
appropriate to the artifact and risk. Measure with the relevant counter when reporting savings or meeting a hard
limit; do not claim token counts without the relevant tokenizer or a globally minimal solution without proof.

Continue while there are useful, valid reductions. Return compressed output directly when requested; for file edits,
report the result and relevant validation briefly. Keep explanations outside an artifact subject to a size limit,
and provide a readable companion only when requested.
