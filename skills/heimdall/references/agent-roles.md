# Agent Roles

Who does what in Build mode. Each role gets its own context, a packet built from an asset template, and a fixed report format. Agents never talk to each other or to the user directly: everything flows through the orchestrator and the tracker.

## Roles at a glance

| Role | Runs as | Writes | Never | Minimum tier |
|---|---|---|---|---|
| Orchestrator | the session where the user invoked Heimdall | spec, HANDOFF, tickets, packets, STATE, tracker status; clean merges | edits product code while coders run; reads whole diffs | Standard (Frontier preferred for G1–G3) |
| Researcher | one per research question, in parallel | `.heimdall/research/<topic>.md` digests; throwaway spikes outside the repo | edits product code; merges spikes; handles secrets | Standard (Light for single-library doc lookups) |
| Scout | read-only subagent or headless run | `.heimdall/REPO_REPORT.md`, `.heimdall/research/<topic>.md` | edits code | Light |
| Coder | one per ticket, in its own worktree | code and tests on `heimdall/t<nn>-<slug>`; the return report | edits outside its touch set; pushes; merges; touches the tracker | per ticket: Light / Standard / Frontier |
| Reviewer | fresh context per review round | the review report | edits tracked files; pushes; approves its own work | Standard |
| Merger | one at a time, only when a merge needs resolution | merge commits on the ticket branch | resolves non-mechanical conflicts; force-pushes | Standard |
| QA agent | G6 only | the QA report; reproduction steps | fixes what it finds (findings become tickets) | Standard |
| Human | the user | gate sign-offs, needs-human answers, outward-action approvals | — | — |

## Orchestrator

Runs every gate and the scheduler (execution-loop.md). It writes packets from the asset templates, scores them against checklist-and-grading.md, adapts them to the executor's family (`prompting-<family>.md`), and dispatches them (harness-adapters.md). It performs clean merges with tracker commands, because those need no code reading. A Light-tier model never runs the planning gates (G0–G3) or G6–G7; it may run the build loop of a planned build, or Build-lite on the user's explicit request, under the Light-tier conditions (production-orchestrator.md, section 3), and it may always be a coder for Light tickets.

## Researcher

Answers one research question per dispatch (project-research.md): discovery at G0, architecture options at G2, library and integration details for tickets. It uses documentation lookup (Context7 or the vendor's docs), web search, the repository, and time-boxed spikes in a scratch location, and returns a digest (assets/research-digest.md) with sources, retrieval dates, and a confidence level. Several researchers run in parallel; the orchestrator merges their digests into one decision brief. A researcher never decides for the user: it recommends. Packet: assets/research-packet.md (role researcher).

## Scout

Optional. At G0.5 it maps a brownfield repository into the Repo Report (assets/repo-report.md, at most 30 lines). During the loop it can pre-read the code areas a group of tickets will touch and save notes to `.heimdall/research/`, so coders implement instead of exploring; packets then point to those notes. Packet: assets/research-packet.md (role scout).

## Coder

Implements exactly one ticket, test-first (tdd-protocol.md), inside its touch set (merge-protocol.md, L3–L5). It starts from the integration tip in its own worktree, commits with the `test(T<nn>)` / `feat(T<nn>)` convention, syncs with the integration tip before reporting, runs the full suite, and ends with the return report (assets/return-report.md). It stops and reports instead of guessing when it hits a touch-set, seam, spec, environment, dependency, secret, or destructive-action question. Packet: assets/coder-packet.md.

**Tier per ticket** (set at G3): Light = mechanical, one module, an obvious seam; Standard = a typical vertical slice; Frontier = cross-module, ambiguous, algorithmic, or security- or concurrency-critical work.

## Reviewer

Reviews one ticket at one head SHA in a fresh context, along five separate axes, and returns APPROVE or CHANGES_REQUESTED (assets/review-report.md). It may run the test runner and read-only git commands, and read the code, the ticket, the spec, HANDOFF, and the orchestrator's checks report (`.heimdall/reports/T<nn>-checks-<round>.md`: head, clean tree, base, scope, lockfile drift, commit order, red-at-base). It runs no scripts and creates no worktrees. It must leave `git status` clean in the ticket's worktree. Packet: assets/review-packet.md.

- **Spec:** requirements missing or partial, behavior not asked for (scope creep), requirements implemented wrongly. Quote the ticket or spec line.
- **Standards:** violations of the repo's documented standards (cite file and rule), plus the smell baseline from Matt Pocock's `code-review` skill (Fowler, *Refactoring*, ch. 3) — the single source of this list; the orchestrator pastes it into review and QA packets — Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent Change, Speculative Generality, Message Chains, Middle Man, Refused Bequest. Smells are always judgement calls; a documented repo standard overrides the baseline; skip what tooling enforces.
- **TDD audit:** tdd-protocol.md, sections 3, 6, and 8, judged from the commit list, the checks report, and the code.
- **Security:** secrets in code or history, input validation at trust boundaries, injection, authentication and authorization checks, unsafe dependencies.
- **Scope:** only touch-set paths changed (the checks report's scope line); nothing outside the ticket.

Blocking findings: any Spec finding, hard Standards violations, TDD anti-patterns or missing red-first evidence (MVP and Production), any Security finding, any Scope finding. Smells are non-blocking unless they make the change wrong or unmaintainable; non-blocking findings go to the G6 cleanup list.

**Family choice:** prefer a reviewer from a different model family than the coder — a different family catches errors the coder's family is blind to. Required in Production mode when the topology has a second family; recommended in MVP; optional in Prototype. Same-family review still uses a fresh context, never the coder's session.

## Merger

The orchestrator performs clean merges itself. A merger agent is dispatched only when the pre-check reports conflicts or the update step needs mechanical resolution (merge-protocol.md, L6–L7). It works in the ticket's worktree, regenerates lockfiles and generated files instead of hand-editing them, runs the full suite, and reports `MERGED-READY` (with the new head SHA) or `SEMANTIC-CONFLICT` (with the conflicting ticket and failing output). Packet: assets/merge-packet.md.

## QA agent

At G6, runs the acceptance tests (one per Success Criterion), exercises the integrated application against each criterion itself (browser, HTTP, or CLI), and runs the review lenses on the whole build: security (secrets, dependency audit, input validation), performance, UX, accessibility, documentation, release readiness. Every finding becomes a ticket that goes through the same loop. Packet: assets/qa-packet.md (two parts: the whole-build review and the QA run).

## Communication protocol

- **Down:** a packet with context pointers (absolute paths, issue numbers, SHAs) and the exact report format.
- **Up:** the agent's final message is its report. Its first line is a status token the orchestrator can parse: `STATUS: DONE`, `STATUS: BLOCKED: <touch-set | seam | spec | environment | dependency | secret | destructive>`, `STATUS: FAILED`, `VERDICT: APPROVE`, `VERDICT: CHANGES_REQUESTED`, `VERDICT: STALE` (head moved after the packet was written), `MERGE: MERGED-READY`, `MERGE: SEMANTIC-CONFLICT`, `RESEARCH: DONE`, or `QA: DONE` / `QA: BLOCKED: environment`.
- **Sideways:** none. Agents never message each other; shared knowledge lives in files and the tracker.
- **To the user:** never. Subagents and headless runs cannot ask questions reliably (harness-adapters.md); they stop and report, and the orchestrator asks.

## Example topologies (recorded at G2)

| Setup | Orchestrator | Coders | Reviewer | Notes |
|---|---|---|---|---|
| Single vendor, Claude Code | Opus 5.5 | Sonnet 5.5 subagents (Haiku 5.5 for Light) | Opus 5.5 subagent, fresh context | cheapest setup; same-family review |
| Tandem Claude + Codex | Claude Code, Opus 5.5 | Claude subagents | `codex exec` with GPT-6.1 Sol at high | cross-family review |
| Tandem Codex + Claude | Codex, GPT-6.1 Sol | Codex subagents | `claude -p` with Opus 5.5 | cross-family review |
| Muse Code | Muse Wonder 1.0 | Muse Spark 1.3 subagents | headless Claude or Codex | cross-family review |
| No subagents (pi, plain chat harness) | the session | the same session, cap 1 | a headless CLI from another vendor, or a fresh session | execution-loop.md, section 10 |

Concrete model ids, effort levels, and selection flags: agent-model-map.md. Dispatch commands: harness-adapters.md. A headless Codex or Muse reviewer is limited by its sandbox and the packet, not by named commands (harness-codex.md, harness-muse-code.md); cross-family review is usually worth that trade, so record it at G2. When the topology has both, a Claude Code or OpenCode reviewer can be held to exact command prefixes.
