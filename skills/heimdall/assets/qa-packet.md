# QA PACKET — <project-slug> — G6 — HANDOFF v<N>

For: <harness> / <model id> / effort <level> (family <family>; prefer a family other than the coders')
Dispatch: <subagent | headless: `<command>` | same session | user-driven>
Checkout: <absolute path to a clean checkout of <integration-branch> @ <tip sha>>   Bootstrap commit: <sha>
Mode: <Prototype | MVP | Production>   Part: <whole-build review | QA run>

<!-- Orchestrator (references/production-orchestrator.md, G6): dispatch two packets from this template, one per Part,
     in parallel when the harness allows. Fill every <…>; adapt the Prompt to the executor's family
     (references/prompting-<family>.md). Save as .heimdall/packets/G6-review.md and .heimdall/packets/G6-qa.md;
     reports go to .heimdall/reports/G6-review.md and .heimdall/reports/G6-qa.md. Every blocking finding becomes a
     ticket through the normal loop; non-blocking findings join the G6 cleanup ticket. Never put secrets in a packet. -->

## Prompt

You are the <Part> for a finished build. You did not write this code. You report findings only — no fixes, no rewrites, no praise. Each finding carries evidence and a proposed ticket.

<context>
- Spec: <absolute path to .heimdall/spec.md> — Success Criteria, user stories, Non-functional Requirements
- HANDOFF: <absolute path to .heimdall/HANDOFF.md> — Settled Decisions, module map, Testing Decisions, Standards, Commands, Design Contract
- Repo standards files: <CONTRIBUTING.md, CODING_STANDARDS.md, AGENTS.md, … or "none documented">
- Prototype (UI builds): <absolute path to .heimdall/design/prototype/index.html, or "n/a">
- Diff since the bootstrap commit: `git -C <checkout> diff <bootstrap sha>...<tip sha>`
- Run: <Install, Dev / run, Full suite, End-to-end commands from HANDOFF>
</context>

<procedure_whole_build_review>  <!-- keep this block for Part = whole-build review; delete the other -->
1. Run the full suite, the type checker, and the linter. Record the results.
2. **Spec axis:** for every user story and every Success Criterion in the spec, find where it is implemented and tested. Report: missing or partial requirements, behavior nobody asked for, requirements that look implemented but are wrong. Quote the spec line.
3. **Standards axis:** violations of the documented repo standards (cite file and rule), then the smell baseline from the review protocol (references/agent-roles.md, Reviewer) across the whole build: duplicated logic between tickets, drifted conventions, dead code left by fix rounds. Label smells "possible <smell>" and quote the hunk.
4. Keep the axes separate. Blocking: any Spec finding; hard Standards violations. Smells are non-blocking.
</procedure_whole_build_review>

<procedure_qa_run>  <!-- keep this block for Part = QA run; delete the other -->
1. Install and start the application with the HANDOFF commands (services with podman when needed). If it cannot start, stop with `QA: BLOCKED: environment` and the exact error.
2. **Success Criteria:** exercise each one as a user would (HTTP, CLI, or the UI through the harness's browser tool if it has one). Record pass or fail with the steps taken.
3. **Lenses**, one section each: security (no secrets in the repo or its history — `git log -p -S` on the usual key shapes; input validation at trust boundaries; authentication and authorization on every protected path; dependency audit with the stack's tool); performance (obvious N+1 queries, unbounded lists, missing indexes, slow startup); UX (dead ends, missing feedback, broken navigation); accessibility (labels, contrast, keyboard path for the core journey); documentation (README runs as written; `.env.example` complete); release readiness (build from clean, CI green, migrations reversible or backed up, license and privacy line present for user-facing apps); destructive-change caution (any migration or script that deletes or rewrites data has a backup step).
4. **Design (UI builds):** compare each shipped screen with its prototype screen. A difference in layout, flow, copy, or states is a finding.
</procedure_qa_run>

<rules>
- Do not edit, commit, or push anything. Leave `git -C <checkout> status --porcelain` empty.
- Cite evidence for every finding: file:line, a quoted spec line, a command and its output line, or the steps that reproduce it.
- Ask nothing interactively; if you cannot proceed, say so in the report with the reason.
- Your final message is the report below and nothing else.
</rules>

<report_format>
QA: <DONE | BLOCKED: environment>
QA REPORT — <project-slug> — <whole-build review | QA run> — <integration-branch> @ <tip sha>
Agent: <harness> / <model> / effort <level>
Checks: full suite <command> → <result>; type-check → <result>; lint → <result>; build from clean → <result>

## Success Criteria  <!-- QA run -->
| # | Criterion | Result | Steps taken |
|---|---|---|---|
| 1 | <…> | PASS | <…> |

## Findings  <!-- one line each; group by axis or lens -->
- [blocking | non-blocking] <axis or lens>: <finding> — <evidence> — proposed ticket: <title; kind bug | feature | prefactor; touch set>

Summary: blocking <n> | non-blocking <n> | criteria <passed>/<total>
</report_format>
