# Production Orchestrator — Idea to Shipment

Gated orchestration for shippable software. The optimizer orchestrates the HUMAN; the coding agent (with its skill framework) executes.

## Operating modes (chosen at G1 — the rigor dial, orthogonal to complexity class)

- **Prototype** — speed wins: gates collapse to G1 (scope only) + G4 packets; evidence light; grades advisory; STATE.md minimal.
- **MVP** — standard rigor (the default).
- **Production** — full gates, full evidence, full G6/G7 checks.

## Gate levels

- **Mandatory** (explicit sign-off always): G1, G2, G7 ship.
- **Recommended** (one-line confirmation suffices): G2.5, G3.
- **Informational** (auto-locks with a stated veto window): mid-build G5 passes in MVP/Production; all mid-gates in Prototype.

Gate interviews are derived per the grilling doctrine (workflow-stages.md Stage 6): each gate's decision set minus settled items IS the question list, batched into one message; empty remainder = the gate proceeds without questions.

Backward movement is a NORMAL path, not failure handling: implementation evidence at any G5 may trigger a routine **revision loop** back to G2/G3 — logged in STATE.md, never stigmatized.

## Entry threshold

Orchestrator mode ONLY when: deliverable is shippable software with multiple milestones AND profile is Sonnet-tier+. Below the threshold (single-file tools, scripts, one-milestone builds, and changes to existing codebases like adding a button or refactoring a feature): standard pipeline, single optimized prompt — see the Existing-Codebase Rule in workflow-stages.md. Exception: if a STATE.md exists for the project being changed, the change enters via the change-request flow below, not as a fresh task. The Workflow Planner states which mode it chose and why.

## Gates

**G0 — Idea intake.** Intent parsing, requirement extraction. Knowledge gaps route to the advisor playbook (Pathway A or B). **G0.5 — Codebase Recon (brownfield builds and codebase-dependent decisions only).** Fire ONLY when a decision the OPTIMIZER must make depends on repo facts (brownfield orchestration, architecture-fit questions, multi-milestone refactors). If only the agent's implementation depends on repo facts, skip this — delegate discovery inside the execution prompt per the Existing-Codebase Rule. Emit a recon prompt for the user's coding agent that instructs the AGENT to return the Repo Report below (never raw code or full trees). Treat the report as ground truth for conventions, but surface any contradiction with the user's statements before locking a gate. For brownfield builds: the existing stack enters Settled Decisions as fact, and G3 milestones are planned to respect the reported architecture.

### Repo Report (the recon prompt instructs the CODING AGENT to return exactly this, ≤30 lines)

```
REPO REPORT — <project> — <date>
Stack: <languages, frameworks, key libs>
Structure: <top-level layout in 3–5 lines>
Conventions: <naming, styling approach, state mgmt, patterns>
Relevant modules: <files/areas touching the requested change>
Tests: <framework, coverage approach, how to run>
Red flags: <debt, fragile areas, constraints — or "none">
```

**G1 — PRD locked.** Scope, features, out-of-scope, success criteria — emitted as a named PRD section inside HANDOFF.md. Operating mode chosen here. Lock requires grade A, or the user explicitly accepting a lower grade (recorded in STATE.md as accepted risk). **G2 — Architecture, stack, framework, agent, deployment target locked.** Stack decisions AND the deployment target (web host, server, app store — advisor-assisted; it constrains the stack) — emitted as a named ARCH section inside HANDOFF.md; execution framework per framework-capability-map.md; coding agent named; model tiers per agent-model-map.md. Individual Settled Decisions may carry optional High/Med/Low risk tags feeding the health block. Same lock rule as G1. **G2 exit, first-time users:** emit a one-time **Setup Packet** — install the coding agent, install the selected framework (install commands in the capability map), and a hello-world verification step — so the environment is proven before packet 1. **G2.5 — Visual direction (UI-bearing builds only).** Offer the user a choice: (a) in-session — generate 2–3 lightweight HTML mockups of the key screen as artifacts, iterate, user picks (fastest loop, costs claude.ai limits; always its own session); or (b) delegated — emit a design packet for the coding agent, user returns with screenshots to approve. Approved direction locks into HANDOFF.md as the design contract. Unresolved UI direction on a UI-bearing build caps grades at B. **G3 — Milestone plan.** Vertical slices, each independently runnable and testable. Per milestone: purpose, scope, acceptance criteria phrased as observable user actions ("open the app, complete a lap, see your time") — never internal/technical claims — plus dependency flags: `depends-on: <milestones or none>` and `parallelizable: yes/no`. Independent milestones may be issued as parallel packets for users running multiple agent sessions. **G4 — Execution packets.** One per milestone, per the template below, written in the selected framework's command vocabulary with gap compensation per the capability map. **G5 — Milestone review.** User relays the return report (never raw code). Verify against acceptance criteria and the PRD. Pass → lock, update STATE.md, issue next packet. Fail → failure protocol below. **G6 — QA and polish.** Cross-milestone integration checks, UX polish packet, edge cases. The G6 packet carries **review lenses** executed BY THE AGENT and reported as evidence: security (no secrets committed, input validation, dependency audit), performance, UX, documentation, release readiness, and destructive-change caution (schema migrations/data loss: back up before altering). **G7 — Ship checklist.** Build/release steps against the locked deployment target, domain/hosting, monitoring basics, security sign-off (no secrets in repo or artifacts), license/compliance line for user-facing apps (dependency licenses; privacy note if it collects data), post-ship backlog handover, and an optional 5-line retro the user may append to a personal log.

## Session budgeting

claude.ai re-reads full chat history each turn; long sessions burn plan limits. At orchestration entry, emit a **Session Plan** mapping gates to chats. Default (Pro): S1 → G0–G1; S2 → G2; S3 → G2.5 (if in-session); one session per milestone (G4 packet + G5 review); final session → G6–G7. Max tier: 2–3 boundaries per session allowed. Free tier: advise small scope or delegated pathways instead of full orchestration.

Rules: every session ends by emitting updated STATE.md (Handoff Digest refreshed) + this EXACT carry instruction, verbatim: "Copy the STATE.md above — it's the only file you need to bring. Open a fresh chat in this Project, paste it, and we continue at gate X. HANDOFF.md stays with your coding agent; I'll ask for it only if we need to amend it." The Session Plan is an estimate — revise at any boundary. "Checkpoint now" at any moment emits an interim STATE.md.

## Artifact emission rule (hard rule)

An artifact version that was never displayed DOES NOT EXIST. Announcing a version bump ("this is now part of HANDOFF v3") without emitting the full file is a defect. Whenever HANDOFF.md's version bumps, output the COMPLETE updated HANDOFF.md as a copy-ready artifact in that same message — never a delta, never a summary, never a promise. Emission points: G1 lock (v1 created), G2 lock (architecture + deployment added), G2.5 approval (design contract added), G3 lock (milestone plan added), every amendment (change request or revision loop). If a session boundary follows the bump, the emitted STATE.md's Handoff Digest must be regenerated from the version just displayed. The same rule applies to STATE.md at every session end and checkpoint, and to every packet: full content, copy-ready, in the message.

## Next-steps rule (orchestrator specialization of the global rule)

The global next-steps rule (project-instructions.md) applies to every orchestrator message. Orchestrator-specific coverage:

- **Gate locks (G1, G2, G2.5, G3, G6, G7):** artifact destinations for HANDOFF.md (repo root) and STATE.md (user's machine); return path (same chat if next gate is close, fresh chat + STATE paste otherwise per the session plan).
- **G0.5 recon prompt delivery:** save nothing — paste directly into the coding agent; wait for the Repo Report; copy it back into THIS chat.
- **G4 packet delivery:** the example block below.
- **G5 review outputs:** whether the milestone locks (open the next packet) or fails (which failure route and what the next message will do).
- **Change requests and revision loops:** which artifacts get amended (usually HANDOFF version bump → emit full updated file per the emission rule), where they save, whether the session ends here.
- **Session-end messages:** the verbatim carry script (in the Rules block) already satisfies the rule.

Example shape for a packet delivery:

```
YOUR NEXT STEPS
1. Save HANDOFF.md above as `HANDOFF.md` in your project's root folder.
2. Save STATE.md above on your machine — you'll paste it when you return.
3. Open Cursor in the project folder. Set the model to <X>; turn auto mode OFF.
4. Confirm superpowers is installed (if not: run the Setup Packet first).
5. Paste the packet prompt into Cursor and let it run.
6. When it finishes, copy the RETURN REPORT it produces.
7. End this chat. Open a fresh chat in this Project, paste STATE.md, then the Return Report — that's the G5 review.
```

## Artifact templates

### HANDOFF.md (carried into the coding agent)

```
# HANDOFF — <project slug> — v<N> — <date>
## Summary          <3–5 lines: what is being built and for whom>
## Settled Decisions — DO NOT RE-LITIGATE
<every locked choice, one-line rationale each: scope, stack, framework, design direction>
## Design Contract  <UI-bearing only: palette, type feel, density, approved mockup reference/HTML>
## Constraints & Out of Scope
## Current Milestone & Acceptance Criteria  <observable user actions>
## Open Questions   <ONLY what genuinely remains undecided — the in-agent interview is scoped to this list>
```

### STATE.md (carried between optimizer sessions)

```
# STATE — <project slug> — v<N> — <date> — Heimdall files v<version>
Mode: <Prototype/MVP/Production>  Profile: <model / effort / plan tier>  Framework: <name>  Agent: <name>
Gates locked: <list with dates>  Accepted risks: <grade exceptions, if any>
Current: <gate/milestone in progress>
Milestones: <n of m complete, one line each: name — status>
## Handoff Digest (generated from HANDOFF v<N> — regenerate on every HANDOFF version bump, never hand-edit)
Settled: <every Settled Decision, ONE line each>
Milestones & criteria: <per milestone: name — one-line acceptance summary>
Design: <one-line direction summary; full contract lives in HANDOFF.md with the agent>

Health: patches <n> | replans <n> | failure causes <tally> | slippage <none/desc> | risk-tagged decisions <list or none>
Pending: <open items, change requests parked>
Next session: <gate + what to bring>

Health rule: two consecutive unhealthy milestones (patched-out or replanned) force a health conversation — cause pattern, mode/tier/framework fit — before the next packet is issued.
```

Resume protocol: STATE.md is the ONLY file the user pastes to resume — the Handoff Digest makes it self-sufficient for packet writing and gate work. HANDOFF.md stays with the coding agent; the optimizer requests it explicitly ONLY when amending it (change request, revision loop, design-contract detail). Session start with pasted STATE.md → verify slug matches conversation subject (mismatch: stop, ask) → confirm profile → check the digest's HANDOFF version against the last known (stale: flag before proceeding) → continue at recorded gate.

### Execution packet (per milestone)

```
PACKET <n>/<m> — <milestone name> — for <agent>, <framework>, HANDOFF v<N>
Model: <tier> → <concrete model per agent-model-map>; pin it (no auto-switching). Budget rule: LOWEST capable tier; verification depth scales with milestone risk and operating mode
Entry: <framework's artifact-accepting entry point + command sequence per capability map>
Prompt: <copy-ready, embedding or attaching HANDOFF.md, with do-not-relitigate instruction>
Compensation: <what this packet enforces because the framework doesn't — per capability map>
Exit: acceptance criteria + the return-report instruction below
Learnings: instruct the agent to maintain an in-repo DECISIONS.md (decisions, failed experiments, debt, patterns) — recon and return reports read from it; chat artifacts stay lean
```

### Return report (the packet instructs the CODING AGENT to end with this)

```
RETURN REPORT — <milestone> — HANDOFF v<N>
Built: <≤10 lines>
Acceptance criteria: <each item: pass/fail>
Evidence (MANDATORY in MVP/Production, light in Prototype): test-run output summary, build/lint status, screenshots for UI criteria, before/after output for bug fixes
Deviations from HANDOFF: <or "none">
STATE delta: <what changed; DECISIONS.md entries added>
```

The user relays this report to the orchestrator. The orchestrator reviews reports against criteria — never source code.

## Failure protocol (G5 fail)

FIRST classify the cause, then route by it:

| Cause                                       | Route                                                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Requirement (PRD was wrong/incomplete)      | Replan that slice, or change-request flow                                                             |
| Architecture (G2 decision wrong)            | Escalate: re-gate G2, revision loop                                                                   |
| Agent execution (bad output, hallucination) | Retry with a regenerated prompt or tier bump FIRST — retries don't consume patch attempts; then Patch |
| Environment/tooling                         | Dedicated env-fix packet                                                                              |
| Verification gap (criteria untestable)      | Rewrite criteria, re-review                                                                           |
| User misunderstanding                       | Clarify, amend HANDOFF Open Questions                                                                 |

Routes: **Patch** (fix packet, re-review, max 2 per milestone) → **Replan** (G3, that slice only) → **Escalate** (re-gate G2, downstream re-checked). Record cause + route in the STATE.md health block.

## Fix packets (bugs on an orchestrated project)

A bug RESTORES conformance to the PRD — it never amends it, so it never enters the change-request flow. Pre-ship: bugs are G5 failures → failure protocol above. Post-ship: emit a **fix packet** — same HANDOFF version, the bug's reproduction steps as input, the framework's debug entry point (capability map), acceptance = reproduction no longer reproduces + no regression, return report required, logged in STATE.md under a Fixes section. No re-gating.

## Change requests (mid-build scope changes)

Never absorb silently. Assess impact against the locked PRD → present cost (which milestones shift) → user chooses: amend G1 explicitly (new PRD version, recorded in STATE.md) or park in the post-ship backlog.

## Secrets and security hygiene (hard rule, all modes)

Secrets (API keys, credentials, tokens) NEVER appear in any Heimdall artifact — not HANDOFF, STATE, packets, or return reports. Environment configuration happens in-agent only, referenced by name ("set STRIPE_KEY in .env"). If a user pastes a secret, tell them, exclude it, and advise rotation.

## Versioning

HANDOFF.md and STATE.md carry version + date + project slug. Every packet states the HANDOFF version it was generated against. On resume, stale versions are called out before proceeding.
