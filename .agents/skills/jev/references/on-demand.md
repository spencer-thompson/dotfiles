# Use Jev on the spot

Use the bundled `scripts/jev` for an immediate judgment, rather than creating an
SDK project. It requires Bash, curl, and jq. Paths below assume installation at
`~/.agents/skills/jev`; resolve relative to this skill if installed elsewhere.

If the user asks for a Jev decision, construct the relevant state and questions,
run the helper, and interpret the actual answers. A request to classify or score
something does not authorize executing a selected action.

## Authentication and execution

The helper reads `TYPESAFE_API_KEY` from the environment. If absent, explain that
the user needs to configure it in the execution environment; do not ask them to
paste it into chat or search unrelated files for credentials. You can still prepare
and dry-run the request. Do not describe a dry-run as a model result.

```bash
# Validate the envelope and inspect a request without making an API call.
~/.agents/skills/jev/scripts/jev --dry-run request.json

# Submit a saved request, preserving probabilities, confidence, and usage.
~/.agents/skills/jev/scripts/jev request.json

# Discover model names available to the account.
~/.agents/skills/jev/scripts/jev --models
```

`--model ID` overrides the request's model; otherwise a missing model defaults to
`jev-latest`. `--timeout SECONDS` defaults to 30. Files and stdin both accept the
same JSON body. The helper performs basic envelope validation; the server validates
the question schemas. It preserves structured instructions/criteria and additional
request fields, rather than imposing its own question language.

## All three primitives in one call

```bash
~/.agents/skills/jev/scripts/jev <<'JSON'
{
  "state": {
    "message": "I was charged twice and need a refund today."
  },
  "questions": {
    "route": {
      "type": "choice",
      "instructions": "Which team should handle `message`?",
      "criteria": {
        "billing": "Charges, invoices, and refunds",
        "technical": "Product errors and troubleshooting",
        "other": "Neither team fits or there is insufficient information"
      }
    },
    "refund_requested": {
      "type": "noul",
      "instructions": "Does `message` explicitly ask for a refund?"
    },
    "urgency": {
      "type": "score",
      "instructions": "How time-sensitive is the request in `message`?",
      "criteria": [
        "No deadline or urgency expressed",
        "Requests action within a few days",
        "Requests action today or immediately"
      ]
    }
  }
}
JSON
```

Remove unneeded questions for a single decision. Add independent questions for
multi-label classification, per-candidate ranking, verification, or multiple score
dimensions. These use the same endpoint; they do not need separate scripts.
For extraction, enumerate source candidates and use Choice to select one. For
dependent decisions, build the next request from the first response in a separate
call. See [design](design.md) for those patterns.

## Read and act on results

The JSON response contains `model`, `answers`, and `usage`. For example, save stdout
to a file and inspect it with:

```bash
jq '.answers.route | {choice, probabilities, confidence}' response.json
jq '.answers.refund_requested.noul' response.json
jq '.answers.urgency | {score, legend, probabilities, confidence}' response.json
```

Choice selects an option. Noul gives probability of yes, with no separate confidence.
Score is a weighted level index; inspect its returned legend rather than assuming
a 0–1 scale. Preserve uncertainty when reporting the decision; do not invent an
explanation as though Jev generated it.

The helper makes one request with no automatic retries. HTTP, transport, or JSON
errors produce a nonzero exit; never consume failed output as a decision. Curl
reports the HTTP status but suppresses error bodies. For persistent validation
errors, check the [HTTP contract](https://docs.typesafe.ai/api.md). On rate limiting
or overload, use bounded backoff appropriate to the task rather than a tight loop.

The endpoint and example were checked against the HTTP docs on 2026-09-17. For new
API features or changed behavior, read the current contract before changing the
helper. Ordinary calls using this documented interface need no SDK installation.
