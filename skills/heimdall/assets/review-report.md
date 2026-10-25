VERDICT: <APPROVE | CHANGES_REQUESTED | STALE>
REVIEW — T<nn> <ticket title> — round <r> — head <sha>
Reviewer: <harness> / <model> / effort <level>   Coder family: <family>
Checks: full suite <command> → <result>; type-check → <result>; ticket checks → <first line of the checks report>; red-at-base → <RED, judged real | RED, but a setup failure (for the orchestrator) | NO-RED (finding unless characterization) | SETUP-ERROR | SKIPPED: reason | not run: no test files (NO-TESTS)>

## Spec
- [blocking] <finding> — "<quoted ticket or spec line>" — <file:line>
<or "No findings.">

## Standards
- [blocking | judgement] <finding or "possible <smell>"> — <standard file and rule, or the quoted hunk> — <file:line>

## TDD audit
- [blocking | judgement] <finding> — <commit sha or test name>

## Security
- [blocking] <finding> — <file:line>

## Scope
- [blocking] <path outside the touch set>

Summary: Spec <n> (worst: <…>) | Standards <n> (worst: <…>) | TDD <n> | Security <n> | Scope <n>
Non-blocking, for the G6 cleanup list: <findings, or "none">
