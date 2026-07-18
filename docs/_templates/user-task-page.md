---
title: <Outcome in user language>
doc_type: user_task
audience: <operator|supervisor|administrator|support>
kernel_area: <area>
status: <available|partial|planned|deprecated>
roles:
  - <role>
paired_technical_docs:
  - <path>
screenshots:
  - <path or none>
last_verified: <YYYY-MM-DD>
---

# <Outcome in user language>

## What this lets you do

Describe the result and when a user would need it. If the task is not available, say so here and do not provide fictional steps.

## Before you start

- Required role or permission in product language.
- Required site, device, data, or preceding state.
- Consequences the user should understand before acting.

## Steps

1. Give one action using the exact visible label.
2. Explain only the choice needed at that step.
3. Add a screenshot immediately after the step it clarifies.

Use this pattern after the step that needs an image:

```markdown
![Meaningful description of the state and relevant control](../../assets/screenshots/<page>/<image>.png)

*Caption that tells the reader what to notice; do not repeat the alt text.*
```

## Confirm the result

Explain the visible success state, changed records, notifications, and where the operation appears in history.

## If it does not work

| What you see | Likely reason | What to do |
|---|---|---|
| <exact visible message or state> | <plain-language cause> | <safe recovery> |

Cover permission denial, invalid input, changed data, offline/connectivity behavior, and safe retry where applicable. Do not expose internals that do not help recovery.

## What Actualis records

Explain audit or evidence behavior in user language, including any privacy-relevant details.

## Related tasks and concepts

Add links to the prerequisite, next task, concept explanation, and support path that genuinely help this task.
