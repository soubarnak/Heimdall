# Build Orchestrator — Idea or SRS to Shipped Application (Build mode)

Gated, multi-agent orchestration for software. You guide the HUMAN through decision gates, research what the human does not know, then run a team of coder, reviewer, and merger agents through a ticket graph on GitHub, Gitea, or local files until the application ships. Complexity class C3 gets full Build mode; C2 gets Build-lite (section 3).

## Contents

1. State profiles and the `.heimdall/` layout
2. Roles and the tandem model
3. Operating modes · gate levels · entry threshold
4. Gates G0–G7
5. Context and session budgeting · resume
6. Artifact rules · progress report
7. Failure protocol · fix tickets · change requests
8. Secrets, safety, and the standing authorization

## 1. State profiles and layout

Calibration (calibration.md) sets the profile.

- **Agent profile** — file and shell tools in the user's project. State lives on disk; you run research, recon, the tracker, git, and the build loop yourself.
- **Chat profile** — no file tools. You run G0–G3 in chat, emitting every artifact in full and copy-ready, then hand the build loop to a coding-agent harness with Heimdall installed (execution-loop.md, section 10). Never ask for raw code or full diffs — ask for reports.

```
.heimdall/                         runtime state; listed in .git/info/exclude, never committed
  STATE.md                         the resume point (assets/state.md)
  HANDOFF.md                       settled decisions, module map, seams, commands, topology (assets/handoff.md)
  spec.md                          the locked spec (assets/spec.md)
  DECISIONS.md                     small decisions and debt, copied from coder reports (assets/decisions.md)
  REPO_REPORT.md                   G0.5 output, brownfield only
  research/<topic>.md              research digests (assets/research-digest.md)
  briefings/<gate>.md              user briefings (assets/briefing.md)
  design/                          G2.5: option-<x>.html mockups, prototype/ screens, shots/ screenshots
  PROGRESS.md                      the visual progress report, Markdown with Mermaid (assets/progress-report.md)
  progress.html                    the same report as one offline page (assets/progress-report.html)
  tickets/T<nn>-<slug>.md          ticket drafts; with the local tracker, the tickets themselves
  packets/T<nn>-<role>-<round>.md  dispatched packets
  reports/T<nn>-…                  coder, checks, review, merge reports and PR bodies
  ticket-checks.sh                 the mechanical ticket checks, copied from the skill's scripts/ at G3 (execution-loop.md, section 5)
docs/adr/NNNN-<slug>.md            committed: architecture decision records
AGENTS.md (+ CLAUDE.md: @AGENTS.md) committed: commands, module map, conventions for every coding agent
```

Address `.heimdall/` files by explicit path: some search tools skip hidden or ignored directories. Coders in worktrees read them by absolute path.

**Context hygiene:** the orchestrator's context is the scarcest resource in the build. Code-level work stays inside coders, reviewers, and researchers. The orchestrator works from HANDOFF, STATE, the tracker, reports, and targeted checks.

## 2. Roles and the tandem model

Roles, tiers, and the communication protocol: agent-roles.md. Models from different vendors can fill different roles in one build ("tandem") — for example a Claude orchestrator with Claude coders and a Codex reviewer. Rules:

- Every packet is self-contained apart from context pointers, so any family can execute it. Adapt it to the executor's family (`prompting-<family>.md`) and harness (harness-adapters.md).
- Prefer a cross-family reviewer (required in Production mode when the topology has a second family).
- Dispatching to another vendor's harness spends that vendor's quota and runs with that tool's permissions. Get explicit consent at G2 and record the topology in Settled Decisions.

## 3. Operating modes, gate levels, entry threshold

**Operating modes** (chosen at G1 — the rigor dial):

- **Prototype** — speed wins: G1 and G2 signed off together; G3 auto-locks; same-family review allowed; TDD may relax to "tests at seams, after the code"; the red-at-base check is skipped.
- **MVP** — standard rigor (the default): the ticket checks run the red-at-base check on every behavior ticket (execution-loop.md, section 5).
- **Production** — everything in MVP, plus full gates; cross-family review when available; G6 mandatory with a full security lens.

**Gate levels:**

- **Mandatory** (explicit sign-off): G1, G2, G7; also G6 in Production.
- **Recommended** (a one-line confirmation): G0.5 report, G2.5, G3, G6 in MVP.
- **Informational** (auto-proceeds; you report what happened): everything inside the build loop.

When the user is not watching, informational events proceed, and mandatory gates and `needs-human` items stop the affected work: write STATE.md, report what needs the user, and continue only with work that does not depend on it.

**What counts as a sign-off.** A mandatory gate locks only on an answer the user gives *after* seeing that gate's artifacts (the spec and briefing, the decision blocks and ADRs, the release checklist). A blanket instruction given earlier ("run all the gates", "sign everything off in advance", "just build it") does not lock a mandatory gate and does not create a "provisional" lock: stop at the gate, present it with its recommended answers, and end the turn — in a non-interactive run (`-p`, a scheduled job) ending the turn is the stop. Recommended gates may be passed on such an instruction, with the recommended answers recorded as assumptions.

**Gate interviews** are derived (workflow-stages.md, Stage 6): the gate's decision set minus settled items IS the question list. At most 4 questions per message, at most 2 rounds per gate; propose defaults for the rest. Knowledge gaps go to the research-advisor-playbook.md first, and proactive research (project-research.md) answers what documentation can answer before anyone asks the user.

**Recommended-defaults fast path** (G1 and G2). Show the gate's artifacts first, then ask one question whose recommended answer is "accept every recommendation as shown". Settings most users have no view on — merge path, worktree root, integration branch name, concurrency cap, dispatch methods — are listed with their defaults under one line, "Advanced: change any of these", instead of a question each. G2 shows the seams as "behaviours we will test", each with its recommendation, inside the briefing rather than as a separate question. The fast path changes how the sign-off is asked, never what it covers: the yes still comes after the artifacts, and consent to dispatch to another vendor (section 2) is named in it explicitly when the topology has one.

**Backward movement is normal:** evidence in the loop may trigger a revision loop to G2 or G3, logged in STATE.md.

**Entry threshold:** Build mode when the deliverable is software that needs two or more tickets, AND the orchestrator is Standard tier or above for the planning gates. A Light-tier orchestrator declines G0–G3 and G6–G7 ("re-run Heimdall with a Standard or Frontier model for this gate") — a weak spec or module map flows into every ticket and no later guard catches it — but it may run two things:

- **The build loop (G4–G5) of an already-planned build:** resume from a STATE.md whose G3 is locked. Conditions: every packet carries the Stage 10 compensation layer (workflow-stages.md); cap 1; the reviewer is Standard tier or above (a headless or cross-family reviewer when the session's model is Light); a health check after any single retry, tier bump, or full fix round (instead of 2 of the last 4); revision loops to G2 or G3 and change requests stop with "re-run with a Standard or Frontier model"; STATE.md Accepted risks records "loop orchestrated at Light tier".
- **Build-lite (1–3 tickets)** only on the user's explicit "orchestrate anyway" after a one-line warning; the grade caps at C and the same loop conditions apply.

A Light model may always serve as a coder for Light tickets. **Build-lite** (C2): 1–3 tickets, G1 and G2 signed off together, local tracker by default, cap 1 — still test-first, still a fresh-context review. Below the threshold (one-file changes, scripts, small fixes): Direct mode. If `.heimdall/STATE.md` exists, new work enters through the change-request flow or as a fix ticket, never as a fresh build.

## 4. Gates

### G0 — Intake
intake.md, sections 1–3: classify idea vs SRS, state the complexity class, start discovery research (project-research.md; dispatched researchers get assets/research-packet.md), run the bounded interview or the SRS gap check. Create `.heimdall/STATE.md` and add `.heimdall/` to `.git/info/exclude` (agent profile). In a folder that is not a repository yet, run `git init -b main` first — local and reversible; say so in the G0 message. When calibration found no git identity, ask the user to set one for this repository (`git config user.name "<name>"` and `git config user.email "<email>"`, run in the project) before G3, because the bootstrap commit needs it; never set it yourself and never change global git config.

### G0.5 — Codebase recon (brownfield only)
Run when a decision the orchestrator must make depends on repo facts. A scout (agent-roles.md; packet assets/research-packet.md, role scout) writes `.heimdall/REPO_REPORT.md` (assets/repo-report.md, at most 30 lines). Chat profile: emit a recon prompt for the user's coding agent that returns exactly the Repo Report. The existing stack and conventions enter Settled Decisions as facts; surface contradictions with the user's statements before locking.

### G1 — Spec locked (mandatory)
intake.md, sections 4–5: the spec, the grade, the operating mode, the G1 briefing (assets/briefing.md). Lock requires grade A, or the user accepting a lower grade (an accepted risk in STATE.md). HANDOFF v1 is written at this lock.

### G2 — Architecture, seams, tracker, topology locked (mandatory)
Run project-research.md, section 2 for every unsettled decision, then decide with the user:

- **Architecture:** stack, deployment target, data, authentication, integrations → ADRs (assets/adr.md) and HANDOFF ARCH.
- **Module map, hotspot plan, commands** (merge-protocol.md, L1; tdd-protocol.md, section 9).
- **Seams** — the Testing Decisions table, signed off by the user (tdd-protocol.md, section 2).
- **Tracker:** GitHub, Gitea, or local (execution-loop.md, section 2) — run its Preflight now. No remote yet: when `gh` or `tea` is signed in, the recommended answer is a new private repository (the tracker file's Preflight has the command); creating it is an outward action that needs this specific yes. Otherwise the local tracker. **Integration branch** (greenfield: the default branch; brownfield: `heimdall/<project-slug>`), **merge path** (`pr` or `local`), worktree root.
- **Execution topology:** orchestrator, coders per tier, reviewer family, researchers, concurrency cap (agent-roles.md, agent-model-map.md), and the dispatch method per role (harness-adapters.md).
- **Standing authorization:** the exact list of outward actions the loop may take without asking (section 8). Tell the user plainly that the protocol prevents merge conflicts by construction but cannot guarantee zero; semantic conflicts are caught by tests before every merge.
- **Framework** (optional): Heimdall runs TDD, tickets, and review itself; an installed framework only supplies entry points (framework-capability-map.md).

Same lock rule as G1. Write HANDOFF, the G2 briefing (what the user must do — accounts, keys by name, costs — and what to learn), and the Setup Packet (assets/setup-packet.md): sign-ins, harnesses, model pins, and a hello-world per dispatch method. Run setup steps yourself only with the user's approval.

### G2.5 — Visual direction and prototype (UI-bearing builds; recommended)
1. **Propose:** (a) in-session — 2–3 lightweight HTML mockups of the key screen, each a distinct direction (agent profile: `.heimdall/design/option-<a|b|c>.html`; chat profile: artifacts if the app supports them); or (b) delegated — a design packet for a design-capable agent or tool (one with a browser or a design tool) whose deliverable is the same 2–3 mockups as HTML files in `.heimdall/design/`, which the user approves from screenshots. Tickets do not exist before G3, so this is never a ticket.
2. **Pick:** recommend one option with a one-line reason tied to the spec's users and goals; the user picks, or asks for a blend (one more round at most).
3. **Prototype:** extend the chosen direction to static, linked HTML screens with realistic sample data and no backend, in `.heimdall/design/prototype/` (`index.html` links every screen). Prototype mode: skip this step; the chosen mockup is the prototype. MVP: the screens of the core user journey, typically 3–5. Production: those screens plus their empty, loading, and error states. The user confirms or asks for changes (at most 2 rounds).
4. **Lock:** the Design Contract in HANDOFF.md (direction, palette, type, density, layout, the prototype path), then refresh the progress report (section 6): its Design section shows the options shown, the chosen one, and the prototype screens.

Unresolved UI direction on a UI-bearing build caps grades at B.

### G3 — Ticket graph (recommended)
Break the spec into tickets (assets/ticket.md), following Matt Pocock's `to-tickets` rules:

- **Vertical tracer-bullet slices:** each cuts a narrow, complete path through every layer it needs, is demoable or verifiable alone, and fits one fresh context window.
- **T01 scaffold** first (merge-protocol.md, L2); prefactoring before features; wide refactors as expand–contract.
- Each ticket: acceptance criteria tied to seams, **touch set** (modules and hotspots), tier, risk, and blocking edges. No file paths — the module map holds them. A UI ticket names the prototype screen it implements, and its visual acceptance is a screenshot beside that screen.
- **Acceptance tickets:** one end-to-end acceptance test per Success Criterion (or per user journey when several criteria share one), each a ticket of kind `acceptance`, blocked by the tickets that implement it, touching only the end-to-end test module. T01 sets up the End-to-end command (for example Playwright for a web UI; HTTP or CLI tests otherwise). The tests drive the running application the way a user would, and G6 relies on them.
- **An early journey:** order the graph so that the shortest complete user journey a user would recognize is buildable by the second wave. It feeds the demo checkpoint (execution-loop.md, section 9).
- **Validate the graph:** acyclic; every user story and every Success Criterion covered (the Coverage table); every pair of tickets with overlapping touch sets either has an edge or will be serialized by the scheduler; waves computed to show the expected parallelism.

Write the Coverage table in HANDOFF's Ticket Graph (every user story → its tickets and its acceptance ticket) — the single source for the coverage check and for the progress report's "What works so far". Show the breakdown as a numbered list (title, blocked by, covers, what it delivers) with the waves, and ask once whether the granularity and edges look right (recommended answer: confirm as shown, unless you flag a specific doubt). Nothing below happens before that confirmation. On confirmation:

1. Tracker Setup, the spec issue, tickets in dependency order, blocking edges; fill STATE.md's ticket table; copy `scripts/ticket-checks.sh` from the folder that holds this skill's SKILL.md to `.heimdall/ticket-checks.sh`.
2. **Bootstrap commit** on the integration branch, before any coder starts (so nothing can conflict): `docs/adr/*`, and `AGENTS.md` from assets/agents-md.md — commands, module map, conventions, test-first rule, agent rules — plus `CLAUDE.md` containing `@AGENTS.md` when Claude Code is in the topology. Brownfield: merge the sections into the existing files. With a remote and merge path `pr`, push the integration branch now (execution-loop.md, section 3).

### G4–G5 — Build loop (informational)
loop-card.md on one page, execution-loop.md in full: the scheduler claims frontier tickets, dispatches coders in worktrees, reviews each PR in a fresh context, merges serially, closes tickets with the merge SHA, and repeats until every ticket is closed. Stops for the user only on `needs-human` items, health checks, revision loops, and the demo checkpoint after the first complete journey.

### G6 — QA and polish (recommended; mandatory in Production)
1. **Whole-build review:** a two-axis review (Spec, Standards) of the integration branch since the bootstrap commit (assets/qa-packet.md, Part "whole-build review"), in a fresh context, reported by axis.
2. **QA agent** (agent-roles.md; assets/qa-packet.md, Part "QA run"): runs the acceptance tests (HANDOFF's End-to-end command), exercises the running application against the spec's Success Criteria — through the harness's browser tool when it has one, otherwise through HTTP or CLI calls — and runs the lenses: security (no secrets in the repo or history, input validation, dependency audit), performance, UX, accessibility, documentation, release readiness, destructive-change caution (migrations back up first); UI builds: each shipped screen against its prototype screen. Both packets run in parallel when the harness allows.
3. Findings become tickets through the same loop. The G6 cleanup list (non-blocking smells collected during review) becomes one refactor ticket, run under green tests.
4. **Exit.** After the fix tickets merge, re-run the QA run on the failing Success Criteria and the lenses those fixes touched — at most 2 re-runs. G6 passes when every Success Criterion passes (its acceptance test green and the QA run's check) and no blocking finding is open. Still failing after 2 re-runs: stop and ask the user — fix further (recommended while a Success Criterion fails), accept the risk (recorded in STATE.md), or cut scope through the change-request flow.

### G7 — Ship (mandatory)
Fill the release packet (assets/release-packet.md) against the locked deployment target: preflight (CI green, build from clean, acceptance tests, version and release notes, dependency audit, no secrets, migration backups), configuration by name, the release steps in order, a smoke test of the Success Criteria against the deployed application, the rollback plan, and monitoring. Show it with the G7 briefing, the **operations handover** (run, deploy, monitor, back up, update, roll back; the post-ship backlog). Brownfield: open the release PR from the integration branch to the default branch. The sign-off approves the plan; each release step still needs the user's go-ahead when it is about to run (section 8), and the orchestrator runs them itself, never through a subagent. A failed smoke test stops the release: roll back or fix forward, as the user chooses. After the release report: close the spec issue and milestones; remove leftover worktrees (`git worktree prune`); refresh the progress report a last time, Markdown and HTML — everything shipped, with the post-ship backlog as the next phase. Optional 5-line retro.

## 5. Context and session budgeting · resume

Calibration records a budget (tight / standard / generous).

- **Agent profile:** checkpoint STATE.md at every gate lock and every ticket status change, so any session — any harness, any model — can resume by invoking Heimdall in the project. Recommend a fresh orchestrator session after G2, after G3, and every few merges on a tight budget. "Checkpoint now" writes STATE.md immediately; "Show progress" refreshes the progress report (section 6).
- **Chat profile:** at Build-mode entry, emit a Session Plan (assets/session-plan.md); after G3, the kickoff message (assets/kickoff.md) that hands the loop to a coding agent. Every chat session ends with the updated STATE.md and this carry instruction, verbatim: "Copy the STATE.md above — it's the only file you need to bring. Open a fresh chat in this project, paste it, and we continue at gate X."

**Resume protocol** (agent profile; the chat profile does the same from a pasted STATE.md). Do every step, in order, before any other work:

1. **Read STATE.md** and check that its project slug matches the work at hand. Mismatch: stop and ask.
2. **Calibrate** (calibration.md, sections 2–4: detection only, no question) and compare with the recorded profile. A changed harness or model: say so in the resume message and re-check the topology. The tier rules apply to the model running now, not to the recorded one: a Light-tier session continues only inside the build loop under the Light-tier conditions (section 3) and adds "loop orchestrated at Light tier" to Accepted risks; at any other point it stops with "re-run Heimdall with a Standard or Frontier model for this gate".
3. **Migrate STATE.md** when its Heimdall version differs from SKILL.md's `metadata.version`: rewrite it to the current assets/state.md shape — missing header lines, columns (for example `Head`), and sections added, every value kept — and update the version line. Always rewrite the Orchestrator line for the current session. From G3 on, when `.heimdall/ticket-checks.sh` is missing or the version changed, copy it again from the `scripts/` folder next to this skill's SKILL.md (for example `.claude/skills/heimdall/scripts/ticket-checks.sh` or `~/.agents/skills/heimdall/scripts/ticket-checks.sh`).
4. **Check HANDOFF:** when its version differs from the Handoff Digest's, regenerate the digest.
5. **Finish a pending publish:** Current "G3 confirmed, publish pending" (the chat kickoff) → run the G3 publish steps (section 4, G3, steps 1–2) without asking for the confirmation again.
6. **In the build loop,** reconcile with the tracker and the worktrees (execution-loop.md, section 9).
7. **Report** where the build stands (refresh the progress report) and continue at the recorded point.

**No `.heimdall/` on this machine** (a new clone, another computer) with a GitHub or Gitea tracker: rebuild before step 1 — STATE.md and HANDOFF.md from the spec issue's state snapshot comment, spec.md from the spec issue body, and the ticket drafts from the ticket issues — then resume. The ticket table's statuses come from the tracker, which wins.

**State snapshot** (GitHub and Gitea, from G3 on): after every gate lock and every merged wave, write `.heimdall/snapshot.md` — the marker line `<!-- heimdall:snapshot -->`, then STATE.md and HANDOFF.md, each under its own heading — and post it as one comment on the spec issue, edited in place afterwards (the comment id is in STATE.md; tracker files). A comment body is limited to 65,536 characters: when the snapshot is larger, post STATE.md and HANDOFF.md as two comments, each edited in place, with the markers `<!-- heimdall:snapshot 1/2 -->` and `<!-- heimdall:snapshot 2/2 -->` so a rebuild finds both. The local tracker has no snapshot: tell the user at G3 that `.heimdall/` lives only on this machine and recommend backing it up with the project.

## 6. Artifact rules · progress report

**Emission rule (hard rule).** An artifact version that was never written or displayed DOES NOT EXIST. Agent profile: write the complete file, then give the path, the new version, and a 1–3 line summary. Chat profile: output the COMPLETE file, copy-ready, in that message — never a delta or a promise.

**Progress report (visual).** A concise visual report of what has been built and what is proposed next, written for the user. Regenerate it, never hand-edit it, from STATE.md, HANDOFF.md (the Coverage table in Ticket Graph maps user stories to tickets), and the tracker (the tracker wins on ticket status).

- **Contents** (assets/progress-report.md): where the build is (the gate flow); what works so far (the spec's user stories in journey order, each built, being built, or planned); the build graph (tickets by wave, colored by status); the design for UI builds from G2.5 on (the options shown, the chosen direction, the prototype screens, and each built screen beside its prototype once UI tickets merge); what was done since the last report; the next phase as proposed (what it delivers, what waits on the user, risks); and "Your next steps".
- **Style:** the IBM Carbon Design System. The Mermaid diagrams use its white theme (an `init` line with IBM Plex Sans and Carbon grays, and Carbon tag colors for status); the HTML page uses the white theme and g100 in dark mode. Both templates carry the tokens: copy them unchanged.
- **Evidence:** every done item cites a gate lock date, an ADR, or a merge SHA and PR. Never report progress the tracker does not show. No secrets, code, or diffs.
- **When:** at every gate lock from G1 on (G2.5 and G3 included), when a wave of tickets has merged, whenever the loop stops for the user, on resume, at G7, and when the user says "Show progress". Not at every ticket status change: STATE.md is that checkpoint. Each refresh rewrites the report in full from the template and the current state — the header line (date, phase, versions) included; never patch the previous copy.
- **Counts match lists.** The header's "waiting on you" number equals the items listed under "Waiting on you", and both come from STATE.md needs-human plus any gate waiting for a sign-off. Settled decisions and accepted assumptions are never listed again as waiting.
- **Agent profile:** write `.heimdall/PROGRESS.md` (Mermaid diagrams, which GitHub and Gitea render) at every refresh. Write `.heimdall/progress.html` (assets/progress-report.html: one offline page without scripts that embeds the mockups and prototype screens from `.heimdall/design/`) only at the G2.5 lock, at G7, and when the user asks for it ("Show progress" included); give the user the path of each file written. With a GitHub or Gitea tracker, from G3 on (the spec issue exists from G3), post PROGRESS.md (its first line the marker `<!-- heimdall:progress -->`) as one progress comment on the spec issue and edit that comment in place at every later refresh (the comment id is in STATE.md; tracker files) — covered by the standing authorization (section 8). Before G3, and with the local tracker, the files are the report. When calibration found a headless browser, capture each design screen into `.heimdall/design/shots/`, for example `chromium --headless --screenshot=<png> --window-size=1280,800 "file://<absolute path>.html"`; otherwise the HTML page embeds the screens themselves.
- **Try it:** from the demo checkpoint on (execution-loop.md, section 9), the report's "Try it" section gives the command or URL that starts the application and the 3-step journey to try.
- **Chat profile:** show the Markdown version in full at every gate lock (emission rule). When the app supports artifacts, also render the HTML version as an artifact that links the mockup artifacts instead of embedding local files.

**Versioning.** HANDOFF.md, spec.md, and STATE.md carry version, date, and project slug; STATE.md also records the Heimdall version (SKILL.md `metadata.version`). Every packet and report names the HANDOFF version it was generated against. After a HANDOFF bump, regenerate STATE.md's Handoff Digest.

**Next-steps rule (Build-mode specialization of SKILL.md):** gate locks say where each artifact lives and what happens next; loop reports say which tickets merged, which are in flight, and anything the user must do; `needs-human` stops list each question with a recommended answer. For a user-driven dispatch, give numbered steps:

```
YOUR NEXT STEPS
1. Open Cursor in <worktree path>. Set the model to <X>; turn auto model selection off.
2. Paste the Prompt section of .heimdall/packets/T04-coder-1.md into the agent.
3. When it finishes, copy its final message (the return report).
4. Come back here and say "T04 done", then paste the report.
```

## 7. Failure protocol · fix tickets · change requests

**In the loop:** route every failure by cause (execution-loop.md, section 8). Requirement problems go to the change-request flow; architecture problems trigger a revision loop to G2 (new ADR) or G3; executor problems are retried, bumped, or moved to another family; environment problems get an environment ticket.

**Fix tickets (bugs):** a bug restores conformance to the spec; it never amends it, so it never enters the change-request flow. Pre-ship: a failing review or QA finding. Post-ship: a ticket of kind `bug` — reproduction steps as input, a reproducing test first (tdd-protocol.md, section 7), acceptance = the reproduction no longer reproduces and the suite is green — run through the same loop, logged under STATE.md Fixes. No re-gating.

**Change requests (scope changes):** never absorbed silently. Assess the impact on the spec and the ticket graph → show the cost (which tickets change, which are added, which merged work is affected) → recommend amend or park with a one-line reason → the user chooses: amend or park it in STATE.md Pending.

**Applying an amend**, in this order:

1. **Freeze** the affected part of the frontier: dispatch nothing new that touches the changed stories or modules. In-flight tickets finish unless the change makes them wrong; those are parked (status ready, worktree kept) or closed as superseded with a comment.
2. **Spec v+1 and HANDOFF v+1:** edit `.heimdall/spec.md` (the change, a changelog line, Coverage and Success Criteria updated) and HANDOFF.md; regenerate the Handoff Digest in STATE.md. Remote trackers: update the spec issue body (`gh issue edit <spec#> --body-file .heimdall/spec.md` / `tea issues edit <spec#> --description-file .heimdall/spec.md`).
3. **ADR:** when the architecture moves, a new ADR that supersedes the old one (assets/adr.md), committed through a ticket, never by editing the merged ADR.
4. **Tickets:** draft the new and changed tickets (assets/ticket.md), validate them as at G3 (touch-set overlaps with in-flight tickets, edges, the Coverage table, acceptance tickets), publish them with their edges, and rewrite changed issue bodies.
5. **Packets:** regenerate the packets of every unstarted ticket whose input changed; packets name the new HANDOFF version.
6. **Record** the change in STATE.md (gates: "CR-<n> amended <date>") and refresh the progress report.

A change that moves the architecture or the module map is a revision loop to G2 and needs the G2 sign-off again for the changed decisions.

## 8. Secrets, safety, and the standing authorization (hard rules, all modes)

- Secrets (API keys, credentials, tokens) NEVER appear in any Heimdall artifact — spec, HANDOFF, STATE, tickets, packets, reports, briefings, PR bodies, commits. Configuration is referenced by name ("set STRIPE_SECRET_KEY in .env"). If a user pastes a secret, say so, exclude it, and advise rotation.
- Never read credential files (`auth.json`, `.env` values, key stores, token-bearing settings files) to fill an artifact.
- **Standing authorization** (recorded at G2 in Settled Decisions): the loop may create and label issues, milestones, and comments, and edit its own progress and snapshot comments; push `heimdall/*` branches and delete them after their ticket is merged; push the integration branch (the bootstrap commit and every merge, merge path `pr`); open PRs; merge approved PRs into the integration branch; close tickets; and revert a breaking merge with a new commit. Everything else that is destructive or outward — force-pushes, deleting data or non-Heimdall branches, migrations without a backup, merging or pushing to the default branch when it is not the integration branch, deploying, tagging, publishing, changing repository settings, spending money, sending messages — needs the user's explicit go-ahead for that specific action, even in unattended runs.
- A user's own rule that demands approval for every push overrides the standing authorization: use merge path `local` and push at checkpoints the user approves.
- Containers: Heimdall's default is rootless podman — `Containerfile`, `podman run`, `podman compose`. Never introduce Docker unless the user explicitly asks for it.
- Packets carry these rules to every agent.
