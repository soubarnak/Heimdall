# Framework Capability Map (optional)

Heimdall runs its own spec, ticket graph, test-first coding, review, and merge loop, so **no execution framework is required**. Read this file at G2 only when the user already uses one of these frameworks, or asks for one. A framework then supplies entry points *inside* Heimdall's roles; it never replaces the scheduler, the touch sets, or the serial merger.

## Rules

- Inside a coder packet, a framework may supply the test-first or debugging procedure. It must not start its own orchestration (planning, parallel subagents, PR creation, merging): that collides with Heimdall's touch sets and serial merger.
- Record the choice in Settled Decisions; name the exact entry points in packets.
- Present a framework as a recommendation with one line of reason and the trade-off; honor the user's choice.

## superpowers (obra) — Claude Code, Cursor, OpenCode, Codex, others

- **Install (Claude Code):** `/plugin install superpowers@claude-plugins-official`
- **Enforces automatically:** brainstorm → worktree → plan → subagent-driven development with two-stage review → TDD (red-green-refactor) → code review → branch finishing.
- **Use inside Heimdall:** coders may follow its TDD and systematic-debugging skills. Tell coders to skip brainstorming, writing-plans, and subagent-driven-development (the ticket is the plan; Heimdall is the orchestrator) and to stop before branch finishing (no merge, no PR).
- **Debug entry:** systematic-debugging, then verification-before-completion.

## compound-engineering (EveryInc) — Claude Code, Cursor, Codex, others

- **Install (Claude Code):** `/plugin marketplace add EveryInc/compound-engineering-plugin`, then `/plugin install compound-engineering`
- **Enforces automatically:** brainstorm → plan → work → simplify → review → compound (learnings written to docs ground later cycles); `/lfg` runs plan → implement → review → PR → CI hands-off.
- **Use inside Heimdall:** `/ce-compound` fits G6–G7 (capture learnings into docs). Never run `/lfg` or `/ce-work` inside a coder packet: they plan and open PRs themselves.
- **Debug entry:** `/ce-debug` for bug tickets (reproduce → root cause → fix).

## mattpocock/skills — Claude Code and Agent-Skills harnesses (MIT)

- **Install:** `npx skills@latest add mattpocock/skills`, or `/plugin install mattpocock-skills@mattpocock`; then `/setup-matt-pocock-skills` once per repo.
- **Relationship:** Heimdall adapts its `to-spec`, `to-tickets`, `tdd`, `code-review`, and `implement-spec` patterns (credited in tdd-protocol.md and agent-roles.md). Nothing auto-triggers; skills are user-invoked.
- **Use inside Heimdall:** coders may call `/tdd`; reviewers may run `code-review` for the Spec and Standards axes; bug tickets may use `/diagnosing-bugs`. Apply its `ready-for-agent` label next to `heimdall:ready` when the repo uses its triage labels (tracker-github.md).

## bigpowers (danielvm-git) — pattern source only

Near-zero adoption and a single release: do not install it as a dependency. Its CONTEXT / SCOPE / ADR / STATE structure is already absorbed into Heimdall's spec, ADRs, HANDOFF, and STATE.

## No framework (the default)

The coder packet carries the full test-first procedure (assets/coder-packet.md), the review packet carries the review axes, and git discipline comes from merge-protocol.md.
