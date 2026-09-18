# Local Jev findings — September 17, 2026

These are observations from `jev-1.13.0` synthetic tests and a small Operator browser experiment, not general accuracy
guarantees or evidence about later models. Recheck the relevant cases when the model, input representation, or workflow
changes; do not rerun the whole evaluation for an unrelated integration.

## State addressing

In a 32-message test, questions referring to numeric array positions passed 21/32 checks. Removing background text
raised this to 25/32; explaining zero-based indexing gave 22/32. Named fields and questions containing their own target
text each passed 32/32 in that sample. A separate block-classification test selected the wrong block at 0.99 confidence.

Resolve positions in code and pass the intended text directly, retaining relevant attribution and context. For a batch,
make each question's target unambiguous. Keep the failing indexed cases as regression candidates; these small adaptive
tests do not establish universal reliability for the replacement representation.

## Confidence and evidence

An incomplete Choice menu produced 1.0 confidence on an unsuitable option. A timezone comparison also failed with high
confidence. Include a suitable unknown/no-match outcome, keep exact arithmetic and timestamp comparisons in code, and
ask whether the supplied evidence establishes a claim. Confidence alone does not verify completion or authorize action.

## Browser delegation

The Operator experiment did not establish a repeatable speed or reliability improvement from Jev browser delegation.
Fewer main-model calls sometimes added elapsed time through delegation, planning, and repair. Some passing runs never
used the exposed Jev tool, so their results cannot demonstrate a Jev benefit. A completion judgment could also reject
a visibly completed stage.

Treat these architectures as experiments. Verify actual tool use and independently grade completion before comparing
latency or total cost, including delegated calls and recovery. Prefer a small, falsifiable trial over making an
unvalidated delegation loop the default.

## Evidence

- [Synthetic evaluation report](/home/sthom/jev-evaluation-2026-09-17/REPORT.md)
- [Operator experiment and retained fixes](/home/sthom/work/outrival/context-service/joma-context/operator-service/docs/history/jev-experiment-20260917.md)

The reports identify their runs and private artifacts. Open raw traces only when the summaries cannot answer the
current question; do not copy private browser data into this skill.
