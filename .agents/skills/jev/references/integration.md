# Calling and integrating Jev

## Select the existing stack

Read the current reference for the project's language before editing code:

- [JavaScript/TypeScript SDK](https://docs.typesafe.ai/sdk/javascript.md):
  package `@typesafe-ai/sdk`, `TypeSafeClient`, and `client.systemOne(...)`.
- [Python SDK](https://docs.typesafe.ai/sdk/python.md): package `typesafe-sdk`,
  import module `typesafe_sdk`, synchronous `TypeSafeClient` or asynchronous
  `AsyncTypeSafeClient`, and `system_one(...)`.
- [HTTP API](https://docs.typesafe.ai/api.md): use when a native SDK does not suit
  the project; read current authentication, request, response, and error contracts.

Both SDK guides use `TYPESAFE_API_KEY`. Keep it in the project's secret/environment
mechanism and server-side in web applications. Do not print credentials or put them
in examples, client bundles, or committed fixtures.

Inspect the installed version and lockfile. Use the project's package manager.
Confirm model selection and availability with the [models docs](https://docs.typesafe.ai/models.md)
and the installed client. Record the actual model/version when measuring results;
a moving alias may change behavior.

## Minimal TypeScript shape

The following follows the SDK guide checked on 2026-09-17. Confirm it against the
current SDK before use; it illustrates a call, not a complete runtime policy.

```ts
import { choice, TypeSafeClient } from "@typesafe-ai/sdk";

const client = new TypeSafeClient();
const result = await client.systemOne({
  state: { message: "I was charged twice. Please fix this." },
  questions: {
    route: choice("Which team should handle `message`?", {
      billing: "Charges, invoices, or refunds",
      technical: "Product errors or technical troubleshooting",
      other: "Neither team fits, or the request is unclear",
    }),
  },
});

const answer = result.answers.route;
console.log(answer.choice);
```

For Noul/Score constructors, response fields, async lifetime, or advanced client
options, follow the selected SDK's reference rather than translating syntax from
another language. Inspect typed answers directly; do not add an LLM text-to-JSON
parsing layer.

## Fit the call into the application

- Separate state construction, questions, and decision policy enough to inspect
  failures. Avoid introducing a framework for a single call.
- Batch independent questions where useful, but measure token budgets and total
  latency; extra speculative questions are not costless.
- Select timeouts and bounded retries for the application's latency budget,
  accounting for SDK retries. Distinguish unavailable service from uncertain answers.
- Define the useful fallback: existing logic, a reasoning model, another observation,
  or human review. Do not silently treat an API failure as a negative judgment.
- Log sufficient redacted state/question identifiers, model information, answers,
  usage, and latency to reproduce a failure without exposing secrets.

For an older integration, find the current migration guidance through the
[documentation index](https://docs.typesafe.ai/llms.txt). For unexpected behavior,
continue with [evaluation](evaluation.md).
