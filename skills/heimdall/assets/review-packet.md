# REVIEW PACKET — T<nn> <ticket title> — round <r> — HANDOFF v<N>

For: <harness> / <model id> / effort <level> (reviewer family <family>; coder family <family>)
Dispatch: <subagent | headless: `<command>` | same session | user-driven>
Worktree: <absolute path>   Base: <base sha>   Head: <head sha>   Last reviewed: <sha, or "none">
Mode: <Prototype | MVP | Production>   Risk: <H | M | L>   Kind: <feature | prefactor | bug | env | acceptance>
Ticket checks: <the first line of the checks report, e.g. "CHECKS: PASS"> — red-at-base <RED | NO-RED | SETUP-ERROR | SKIPPED: reason | not run: no test files>

<!-- Orchestrator: fill every <…>, adapt to the reviewer's family (references/prompting-<family>.md), save as
     .heimdall/packets/T<nn>-review-<round>.md. Always a fresh context, never the coder's session. -->

## Prompt

You are the reviewer for one ticket in a multi-agent build. You did not write this code. Review the change at exactly head `<head sha>` and return a verdict. Findings only: no praise, no rewrites.

<context>
- Working directory: `<worktree>` — every command below runs there (a subagent runs `cd <worktree>` first; a headless run starts there).
- Ticket: <absolute path to .heimdall/tickets/T<nn>-<slug>.md>
- Spec: <absolute path to .heimdall/spec.md> — user stories <US-nn, …>
- HANDOFF: <absolute path to .heimdall/HANDOFF.md> — Settled Decisions, module map, Testing Decisions (seams), Standards, Commands
- Repo standards files: <CONTRIBUTING.md, CODING_STANDARDS.md, AGENTS.md, … or "none documented">
- Coder's report: <absolute path to .heimdall/reports/T<nn>-coder-<r>.md>
- Design (UI tickets): HANDOFF Design Contract; prototype screen <absolute path, or "n/a">; the coder's screenshot <path from the report, or "none">
- Previous review (round 2+): <absolute path, or "none">
- Diff: `git diff <base sha>...<head sha>` (the base is the integration tip the coder last merged, so this is only the ticket's change)
- Commits: `git log --reverse --no-merges --format='%h %s' <base sha>..<head sha>`   Round 2+: the fix commits are `git log --reverse --first-parent --no-merges --format='%h %s' <last reviewed>..<head sha>`; check the open findings first, then the rest of the diff for regressions
- Checks report: <absolute path to .heimdall/reports/T<nn>-checks-<r>.md> — the orchestrator's mechanical checks at this head: head, clean tree, base, scope, lockfile drift, commit order, and red-at-base with its test output. Read it; do not re-run it.
- Touch set: <module: path globs; tests: path globs; hotspots>
</context>

<procedure>
1. Confirm `git rev-parse HEAD` equals `<head sha>`. If not, stop with `VERDICT: STALE`.
2. Run the full suite and the type checker with the HANDOFF commands. Record the results.
3. **Spec:** requirements missing or partial; behavior nobody asked for; requirements that look implemented but are wrong. Quote the ticket or spec line for each. UI tickets: compare the coder's screenshot (or the running screen) with the prototype screen; a difference in layout, flow, copy, or states is a Spec finding.
4. **Standards:** violations of documented repo standards (cite file and rule). Then the smell baseline — <the orchestrator pastes the smell list from references/agent-roles.md, Reviewer, unchanged> — each labelled "possible <smell>" with the hunk quoted. A documented repo standard overrides the baseline. Skip anything tooling enforces.
5. **TDD audit:** test commits precede or accompany the behavior they cover; every new test sits at a seam listed in the ticket; no implementation-coupled, tautological, or horizontally sliced tests; the report's red column is plausible. From the checks report: `COMMIT-ORDER`, `NO-RED`, and `NO-TESTS` are findings unless the coder's report explains them (characterization tests may pass on the base code). Judge the red-at-base output: a failure because a module, function, or route this ticket creates does not exist yet is red; a failure from a missing installed dependency or broken tooling is a setup problem — say so in Checks, not as a TDD finding. Acceptance tickets: the test drives the running application and asserts the Success Criterion's observable result.
6. **Security:** secrets in code or history, missing input validation at trust boundaries, injection, missing authentication or authorization checks, risky dependencies.
7. **Scope:** the checks report's scope line is PASS (the paths are inside the touch set). Also judge whether every in-scope change belongs to this ticket.
8. **Verdict:** APPROVE only if no blocking finding remains. Blocking: any Spec, Security, or Scope finding; hard Standards violations; TDD anti-patterns or missing red-first evidence (MVP and Production). Smells are judgement calls and non-blocking unless they make the change wrong or unmaintainable.
</procedure>

<rules>
- Do not edit, commit, or push anything. Leave `git status --porcelain` empty.
- Keep the axes separate; do not merge or rerank findings across axes.
- Cite evidence for every finding: file:line, a quoted spec line, or a command output line.
- Ask nothing interactively; if you cannot review (missing file, broken environment), say so in the report with `VERDICT: CHANGES_REQUESTED` and the reason.
- Your final message is the review report below and nothing else.
</rules>

<report_format>
<paste assets/review-report.md here>
</report_format>
