---
name: jev
description: Use and develop with TypeSafe AI's Jev decision model. Apply when asked to use Jev, design typed judgments, integrate its API or SDKs, or evaluate a Jev workflow.
license: MIT
---

# Jev

Use Jev for semantic decisions inside software: application state and questions
go in; typed answers and probabilities come out. Code owns execution and exact
rules. Jev does not generate prose, code, or reasoning explanations.

## Start with the task

Identify the desired application behavior and the judgment Jev should supply.
Preserve the existing stack and scope. For a concrete request, implement the
relevant path; brainstorming and evaluation infrastructure are not prerequisites.

Read only the supporting reference needed for the current work:

- **Get a decision right now:** [On-demand usage](references/on-demand.md) explains
  `scripts/jev`, authentication, and direct calls for all three primitives and batches.
  Use it to make the requested call, not merely describe how to integrate Jev.
- **Design questions or explore applications:** [Design](references/design.md)
  covers primitives, state, composition, and links to selected cookbooks.
- **Develop an application integration:** [Integration](references/integration.md)
  covers SDK entry points, a minimal example, and runtime behavior.
- **Test, tune, or debug:** [Evaluation](references/evaluation.md)
  covers uncertainty, representative cases, and failure diagnosis.
- **Apply our measured lessons:** [Local findings](references/local-findings.md)
  records the September 17, 2026 experiments. Read for state-addressing problems,
  confidence-based decisions, or a proposed browser delegation loop.

## Essential constraints

- Typed output guarantees an interface, not truth. Treat probabilities as model
  judgments; validate consequential decisions on the target data.
- Choice selects one candidate; Noul estimates whether a condition holds; Score
  measures a described dimension. Do not use probability as an intensity rating.
- Independent questions can share one request but cannot see each other's answers.
  Keep dependent stages in separate calls when new evidence or options are needed.
- Keep deterministic checks, permissions, and side effects in code. Confidence
  does not grant permission, and a model judgment does not establish observed fact.

## Current documentation

Use the [live index](https://docs.typesafe.ai/llms.txt) to find relevant pages.
Before coding, read the chosen SDK/API page and applicable primitive guidance;
for a new design, inspect the closest cookbook. Follow targeted links rather
than loading the whole documentation site. Markdown pages use a `.md` suffix.

If live docs are unavailable, try the normal HTML page, then installed SDK types
or local documentation. State the limitation and avoid inventing API contracts,
model identifiers, limits, prices, or performance claims.

Adapted from the
[TypeSafe reference skill](https://github.com/typesafe-ai/skills/blob/main/skills/typesafe-ai/SKILL.md).
