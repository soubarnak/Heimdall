`# Framework Capability Map`

`Read at G2 (selection) and G4 (packet writing). Update this file — not the orchestrator — when frameworks change or new ones are added.`

`## Selection rules (G2)`

`Score dimensions already known from G0–G1 — ask nothing new: project longevity (one-off vs ongoing), user experience (guided vs self-directed), autonomy preference (hands-off vs in-control), project size.`

`- Guided user OR full application → **superpowers** (default; auto-enforcing process protects uninformed users)`

`- Ongoing product, repeated cycles on one repo → **compound-engineering**`

`- Experienced user OR small scope OR wants control → **mattpocock/skills**`

`- Tie/ambiguous → superpowers, state why`

`Present: recommendation + one-line reason + runner-up + the trade-off of choosing differently. User decides; honor overrides immediately, state the trade-off once, never relitigate. Override adaptation = vocabulary translation + gap compensation per the table below.`

`## Capability table`

`### superpowers (obra) — Claude Code, Cursor, OpenCode, Codex, others`

`` - **Install (Claude Code):** `/plugin install superpowers@claude-plugins-official` ``

`- **Enforces automatically:** skill triggering as mandatory workflows; brainstorm→worktree→plans (2–5 min tasks)→subagent-driven dev with two-stage review→TDD (red-green-refactor)→code review between tasks→branch finishing.`

`- **Leaves to user:** initial direction; plan approval; go/no-go points.`

`- **Artifact-accepting entry:** brainstorming skill accepts an existing design doc. Packet instruction: "An approved design document (HANDOFF.md) is attached. Validate for gaps against the codebase; do NOT re-open decisions in Settled Decisions; proceed to writing-plans."`

`- **Packet style:** lean — discipline is enforced in-agent. Name the entry, attach HANDOFF, state exit + return report.`

`- **Debug entry:** systematic-debugging skill (4-phase root-cause process) + verification-before-completion.`

`- **Compensation needed:** minimal.`

`### compound-engineering (EveryInc) — Claude Code, Cursor, Codex, many others`

`` - **Install (Claude Code):** `/plugin marketplace add EveryInc/compound-engineering-plugin` then `/plugin install compound-engineering` ``

`- **Enforces automatically:** the loop brainstorm→plan→work→simplify→review→compound; learnings written to docs ground later cycles; /lfg autonomous mode (plan→implement→review→PR→CI-green).`

`- **Leaves to user:** when to run each command; strategy direction.`

`- **Artifact-accepting entry:** /ce-plan accepts a requirements-only plan directly — a complete HANDOFF.md SKIPS /ce-brainstorm. If Open Questions is non-empty: /ce-brainstorm scoped to those items only, then /ce-plan.`

`- **Packet style:** command sequence per milestone (/ce-plan → /ce-work → /ce-simplify-code → /ce-code-review → /ce-compound), or /lfg for hands-off milestones.`

`- **Debug entry:** /ce-debug (explicitly for bug inputs: reproduce → root cause → fix), then /ce-code-review → /ce-compound.`

`- **Compensation needed:** low; add explicit exit criteria since /lfg defines its own done.`

`### mattpocock/skills — Claude Code and Agent-Skills-standard harnesses`

``- **Install:** `npx skills@latest add mattpocock/skills` (copies, hackable) or `/plugin install mattpocock-skills@mattpocock` (managed); then `/setup-matt-pocock-skills` once per repo``

`- **Enforces automatically:** NOTHING auto-triggers by design — user-invoked, composable, user-controlled.`

`- **Leaves to user:** the entire process order.`

`- **Artifact-accepting entry:** /grill-with-docs with HANDOFF.md attached (updates CONTEXT.md/ADRs; delta interview scoped to Open Questions). Empty Open Questions → skip grilling: /to-spec → /to-tickets → /implement (drives /tdd) → /code-review.`

`- **Packet style:** the packet IS the process owner — name every skill, exact invocation order, exit condition per step.`

`- **Debug entry:** /diagnosing-bugs (reproduce → minimise → hypothesise → instrument → fix → regression-test).`

`- **Compensation needed:** highest — stricter G5 review since less review is enforced in-agent; packet carries the sequencing discipline.`

`### bigpowers (danielvm-git) — pattern source, NOT recommended as a dependency`

`- Near-zero adoption/single release = maintenance risk. Do not standardize users on it. Its hierarchy-of-truth artifact structure (CONTEXT/SCOPE/ADR/STATE) is already absorbed into this orchestrator's HANDOFF/STATE design.`

`### No framework / unlisted agent`

`- **Packet style:** heaviest — embed HANDOFF content in the prompt with the do-not-relitigate instruction; inline the spec structure, TDD instruction, and a self-review prompt; return report mandatory. Gates hold regardless of what's installed.`

`- **Git discipline (mandatory on this path):** branch per milestone, commit on each acceptance-criteria pass — the rollback point for failure-protocol unwinding.`
