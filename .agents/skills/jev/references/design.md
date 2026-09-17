# Designing Jev judgments

## Choose the meaning of the answer

| Need | Primitive | Interpretation |
| --- | --- | --- |
| Select one of the supplied candidates | [Choice](https://docs.typesafe.ai/primitives/choice.md) | Competing options and their probabilities |
| Decide whether a condition holds | [Noul](https://docs.typesafe.ai/primitives/noul.md) | Probability of yes; no separate confidence |
| Rate a single dimension | [Score](https://docs.typesafe.ai/primitives/score.md) | Probability-weighted position across ordered levels |

Use separate Nouls for labels that may apply simultaneously. Use comparable
per-item Scores for graded ranking. A Noul of 0.5 means yes and no have similar
probability, not medium severity or half-completion.

## Supply enough evidence

Put source material and application facts in named state fields. Include relevant
identities, relationships, policies, and timing. Keep observed state distinguishable
from inferred state. For an agent loop, retain the goal, recent actions, and their
observed results; check that a result still applies before executing against
changed state.

Put the complete judgment in instructions and define possible answers in criteria.
Question IDs are for code and are not sent to the model: a descriptive key cannot
replace instructions. Reference nested state explicitly, such as
`ticket.messages[0].text`.

Ask one coherent judgment per question. Separate independent dimensions without
removing context necessary to interpret them. Structured instructions and criteria
can express definitions, exclusions, and examples. Score levels should describe
concrete situations and make sense individually.

Include no-match or insufficient-evidence outcomes where appropriate. For source
extraction, first enumerate candidate values or spans in code, then ask Jev to
select and copy the chosen source value. A missing candidate cannot be selected;
do not ask Jev to generate arbitrary strings.

Read [state guidance](https://docs.typesafe.ai/concepts/state.md) and
[structured questions](https://docs.typesafe.ai/primitives/advanced.md) when refining
ambiguous inputs.

## Compose judgments in code

Batch independent questions over shared state. Speculative branch questions can
also run together if each states its premise explicitly; consume only the answers
for the branch actually taken. Do not refer to another question's pending answer.
Use a subsequent request when an answer determines new evidence or candidates.

Keep raw judgments separate from policy. Changing weights, thresholds, or display
filters need not rerun inference when evidence and question meanings are unchanged.
A weighted average fits compensating preferences; an "any serious violation"
condition needs its own checks rather than averaging violations away.

## Find a useful pattern

Choose the closest recipe, then adapt it to the actual task:

- Tool or handler selection: [function calling](https://docs.typesafe.ai/cookbooks/function_calling.md)
  and [speculative fan-out](https://docs.typesafe.ai/patterns/fan-out.md).
- Retrieval and candidate selection: [reranking](https://docs.typesafe.ai/cookbooks/rerank_typesafe.md)
  and [hierarchical classification](https://docs.typesafe.ai/cookbooks/hierarchical_classification.md).
- Extract existing values: [pre-parsed extraction](https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook.md).
- Score reusable dimensions: [composite scoring](https://docs.typesafe.ai/patterns/composite-scoring.md).
- Verify generated work: [citation checks](https://docs.typesafe.ai/cookbooks/citation_check.md)
  and [extraction cascades](https://docs.typesafe.ai/cookbooks/sde_cascade.md).
- Broader exploration: [use-case map](https://docs.typesafe.ai/concepts/use-case-map.md).

These are starting points, not a fixed catalog. For an Operator step verifier,
for example, judge whether the observed result satisfies the intended action;
keep retry budgets and final execution in code. This is a proposed application,
not a claim about an existing integration.
