---
name: perfect-functions
description: Design, write, and review functions for local reasoning, explicit dependencies, useful signatures, enforced invariants, and one level of abstraction. Use for function implementation, refactoring, API design, or focused function review. Do not use for broad cleanup unrelated to function boundaries.
---

# Goal

Write functions that make the surrounding program easier to reason about.

"Perfect" is directional. Prefer the clearest boundary for the current code over mechanical compliance with a rule.

## The model

An **honest function** accesses the outside world only through its arguments, including an explicit receiver. Its
signature accounts for every input and output. It may mutate an argument or receiver and still be honest.

A **dishonest function** reads or writes hidden state such as globals, clocks, randomness, files, networks, UI, or
process state. Dishonest work is necessary, but infectious: a function that calls it becomes dishonest too.

Build core logic from honest functions. Inject dishonest values or operations at the highest practical level.

Framework hooks invert ordinary abstraction: they hide the call site rather than the implementation. Treat hooks such
as `main`, event handlers, and frame callbacks as a third boundary category. Keep them small, then enter ordinary
application code quickly.

The terms describe dependency visibility, not code morality. Pure functions are honest, but honesty also permits
controlled mutation.

## Design functions

- Start at the call site. Write the function you wish existed, then implement the boundary it implies.
- Do not wait for duplication. Consider extracting the first occurrence when it creates a useful concept, test seam,
  or abstraction. Leave coherent code inline when a new name would add nothing.
- Expose required state through parameters. Return results or mutate only explicitly supplied state.
- Ask for the weakest capability the implementation needs. Prefer an iterable or span over a concrete container when
  storage is irrelevant. Do not accept a whole object when a few values are enough.
- Make invalid calls difficult. Use parameter objects, strong types, result types, or proof objects when they remove a
  real ambiguity or enforce a meaningful precondition. A proof object must identify the exact resource or condition,
  not merely share its type.
- Encode an invariant in a type only if the type can preserve it after construction. Do not expose mutation that can
  silently break the invariant.
- Prefer producing data separately from acting on it. Choose eager results, callbacks, iterators, or streams according
  to ownership, memory, and caller needs.
- Name functions at the caller's level of intent. The signature should let a caller predict the contract without
  opening the body.

## Write bodies

Keep every line at one level of abstraction. A function should compose a few conceptual operations without opening
one operation and implementing its machinery inline.

Extract a lower-level operation when it gives a real concept a name, isolates a side effect, removes fragile
algorithmic detail, or earns independent tests. Prefer a trusted library algorithm when one already represents the
operation.

Do not split code into tiny forwarding helpers merely to make functions shorter. Preserve locality when the code is
already one coherent operation. Comments that label several phases often reveal abstraction jumps, but they are a
prompt to inspect, not an automatic refactor order.

## Review checklist

Before finishing, ask:

- Are any inputs or outputs hidden from the signature?
- Can core logic receive time, randomness, or an injected operation instead of discovering them globally?
- Does the signature require more data, ownership, storage, or ordering guarantees than the body needs?
- Can the type system enforce an important invariant or call-order rule without adding more machinery than value, and
  is the proof tied to the exact state it claims to protect?
- Does the body mix business intent with loops, parsing, lookup algorithms, encoding details, or resource plumbing?
- Would an extraction clarify a concept, or only make the reader jump between files?
- Do tests cover the honest core and the dishonest boundary in proportion to their risk?

Read [references/examples.md](references/examples.md) before a non-trivial design or review. It contains the video's
worked examples, tradeoffs, and failure modes. Skip it when a tiny function is already covered by the guidance above.
