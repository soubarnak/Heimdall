STATUS: <DONE | BLOCKED: touch-set | BLOCKED: seam | BLOCKED: spec | BLOCKED: environment | BLOCKED: dependency | BLOCKED: secret | BLOCKED: destructive | FAILED>
RETURN REPORT — T<nn> <ticket title> — round <r> — HANDOFF v<N>
Coder: <harness> / <model> / effort <level>
Branch: heimdall/t<nn>-<slug> @ <head sha>   Synced with: <integration-branch> @ <sha>
Built: <at most 8 lines>

Acceptance criteria:
| # | Criterion | Test (file › name) | Red: failure seen | Green |
|---|---|---|---|---|
| 1 | <criterion> | <tests/booking.test.ts › books a free court> | <"expected 'confirmed', received undefined"> | PASS |

Checks:
- Full suite: <command> → <passed>/<total>, <failed> failed
- Type-check / lint / build: <command> → <status>
- UI evidence: <screenshot paths, or n/a>

Scope: <n> files changed, all inside the touch set: <yes | no — list>
Decisions: <non-obvious choices, one line each, or "none">
Debt and follow-ups: <or "none">
Blocker: <kind — what is needed — the smallest question — your proposed answer, or "none">
Review fixes (round 2+): <finding → fix → commit sha, or "n/a">
