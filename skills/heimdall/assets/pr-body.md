<!-- PR body for one ticket. Title: "<ticket title> (#<issue>)". Built by the orchestrator from the coder's report.
     Use "Closes #<n>" only when the PR targets the default branch; otherwise "Refs #<n>". The merger closes the
     ticket explicitly either way. Save as .heimdall/reports/T<nn>-pr.md. -->

Closes #<n>
Part of #<spec issue>

## What changed
<"Built" lines from the coder's report>

## Acceptance criteria
| # | Criterion | Test | Result |
|---|---|---|---|
| 1 | <criterion> | <file › test name> | PASS |

## Checks
- Full suite: <command> → <passed>/<total>
- Type-check / lint / build: <status>
- Synced with `<integration-branch>` @ <sha>

## TDD evidence
<red-first table from the report, or "TDD: n/a — <reason>" for scaffold, config, and docs tickets>

## Decisions and follow-ups
<from the report, or "none">

---
Ticket T<nn> · round <r> · coder <harness> / <model> · built with Heimdall
