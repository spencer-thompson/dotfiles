# Evaluating and debugging Jev

## Verify the application decision

Scale testing to the change. A small integration needs representative success,
ambiguity, and service-failure cases; a production routing replacement needs a
held-out comparison and clear acceptance criteria.

Compare against existing behavior and simple deterministic checks where applicable.
Label examples from human review or observed outcomes, rather than treating another
model's answer as ground truth. Keep tuning examples separate from final evaluation.

Include ordinary cases and the failures that matter: missing or conflicting evidence,
no matching candidate, multiple plausible options, stale state, and relevant edge
cases. For a step verifier, distinguish visible confirmation from merely attempting
an action, and measure false success reports explicitly.

Measure downstream errors and completion rates, fallback/abstention frequency,
p50/p95 latency, and total cost including retries and fallback calls. Do not substitute
vendor benchmark claims for measurements on the application's state and network path.

## Interpret uncertainty correctly

Read [confidence semantics](https://docs.typesafe.ai/confidence.md) before choosing
thresholds. Choice/Score confidence summarizes concentration of their probability
distribution; it is not a direct probability that the entire workflow is correct.
Noul has no separate confidence field.

Evaluate probabilities against outcomes using reliability bins or a suitable scoring
rule, and examine error rates versus automatic-decision coverage as thresholds change.
Tune thresholds to the consequences of each action. Cookbook cutoffs are examples,
not universal defaults. Several acceptable options can spread probability without
making a harmless selection invalid. Ignore uncertainty on unused branches.

## Diagnose before changing the prompt

Inspect the exact input state, question definitions, candidate coverage, raw answers,
policy composition, and observed outcome. Separate:

- Missing or stale evidence: improve state collection or take another observation.
- Ambiguous criteria or missing candidates: repair the question and option set.
- Model error despite adequate evidence: change decomposition or use a fallback.
- Code error: fix branch selection, score interpretation, or execution logic.
- Service failure: fix authentication, limits, transport, or timeout handling.

Consult current model-specific limitations via the
[documentation index](https://docs.typesafe.ai/llms.txt) when a failure pattern persists.
For consequential workflow changes, replay first and consider shadow mode before
enabling actions. Report what was actually tested, the model used, and unresolved
limitations. Mocked tests verify integration behavior, not Jev's judgment quality.
