# Calibration — Step 0 of Every Session

Run before any other work, on the first message of a session that invokes Heimdall (SKILL.md, "Activation — user-invoked only"). Calibration is mostly **detection**: the model by model-plan.md, section 1, and the harness and environment by sections 2–4. It then sends at most two rounds of questions (section 5). In Build mode the first round is always sent, because it asks which agent serves each purpose, which model runs each phase, and the budget. The second round asks for the approvals. In Direct and Prompt modes the only output is a one-line model check.

## 1. Resume check

- Agent profile: if `.heimdall/STATE.md` exists in the project, this is a resumed build. Run sections 2–4 as usual (detection only), skip the message in section 5 (the roster is already in STATE.md), then follow the resume protocol (production-orchestrator.md, section 5): it compares what you detected with the recorded profile, applies the tier rules to the model running now, and migrates STATE.md. Section 6 updates the profile in STATE.md. Show the recorded approvals in one line (the `Approvals:` line of STATE.md) and do not ask them again. Compare the re-detected model with the `Model plan:` line and follow model-plan.md, section 3, when they differ. A STATE.md from before 1.5.0 has no `Approvals:` or `Model plan:` line: then ask the approvals question (round 2 below) and show the model plan once, because those facts are new; this is not a repeated question.
- Chat profile: if the message contains a pasted STATE.md, the same applies.
- A repository with a GitHub or Gitea remote but no `.heimdall/` folder may be a build started on another machine: look for an open issue labelled `heimdall:spec` (`gh issue list --label heimdall:spec` / `tea issues list --labels heimdall:spec`). If one exists, it is a resumed build (the resume protocol rebuilds `.heimdall/` from it).

## 2. Detect the harness and profile

Use the evidence you already have; do not ask.

| Evidence | Harness |
|---|---|
| Tools `AskUserQuestion` and `Agent`; `CLAUDECODE=1` in the shell environment | Claude Code |
| Tools `spawn_agent` / `wait_agent` | Codex CLI |
| Tool `request_user_input` | Muse Code |
| Tool `question`; `.opencode/` directory | OpenCode |
| Tool `ask_question` and no subagent tool | pi |
| Tool `ask_user_question` | Mistral Vibe |
| The system prompt names the harness | that harness |
| No file or shell tools at all | a chat app → **chat profile** |

File and shell tools present → **agent profile**. If the harness is still unknown, say so and use the generic rules in harness-adapters.md (number the options in plain text; same-session dispatch). This table decides the harness and the profile only. The model and the effort are detected by model-plan.md, section 1, never from this table.

## 3. Detect the model and tier

Detect the model and the effort with model-plan.md, section 1. Each detected value carries a confidence: **confirmed** (named by the system prompt or the harness itself) or **unconfirmed** (read from a configuration default, or self-knowledge only). Map the model to a tier with agent-model-map.md. The tier decides what you may do:

- **Light:** Direct mode and Prompt mode with merged analysis stages and a mechanical checklist; one interview round; no critic loop. In Build mode: decline the planning gates G0–G3 and the QA and ship gates G6–G7 ("re-run Heimdall with a Standard or Frontier model for this gate"); you may run the build loop G4–G5 of a build whose G3 is already locked, and Build-lite on the user's explicit "orchestrate anyway", under the Light-tier conditions in production-orchestrator.md, section 3. You may always serve as a coder for Light tickets.
- **Standard:** everything, with standard bounds.
- **Frontier:** everything, plus deeper adversarial critique of specs, ADRs, and packets.

An unconfirmed model is tiered by what it says it is, and the calibration message asks the user to confirm it (section 5).

## 4. Detect the environment (agent profile)

Run cheap, read-only checks. Never read or print credential files or token values.

```bash
git rev-parse --show-toplevel 2>/dev/null && git remote get-url origin 2>/dev/null
git config user.name >/dev/null && git config user.email >/dev/null && echo "git identity set"   # presence only
for c in claude codex muse opencode pi agy gemini qwen vibe grok kimi gh tea podman chromium chromium-browser google-chrome; do command -v "$c" >/dev/null && echo "$c"; done
gh auth status 2>&1 | head -3        # signed-in account only
tea login list 2>/dev/null           # login names and hosts only
ls AGENTS.md CLAUDE.md .heimdall 2>/dev/null
```

These answers decide: greenfield or brownfield, the tracker candidates (execution-loop.md, section 2), and which harnesses and models the agent roster can offer for each purpose (section 5; agent-roles.md). A headless-capable browser (Chromium or Chrome, or the harness's own browser tool) lets the progress report carry screenshots of the design screens; without one, the report embeds the HTML screens instead.

- **No repository:** an empty folder or loose files. Greenfield. G0 runs `git init -b main`, but only after the user says yes to that step. `git init` needs its own yes and is never bundled into another approval (production-orchestrator.md, section 4, G0, and section 8).
- **No git identity:** the bootstrap commit at G3 would fail. G0 asks the user to set one for this repository; never set it yourself.
- **No remote:** the local tracker, unless the user accepts the G2 offer of a new private repository. Creating a remote repository is also asked individually.
- **The instructions already loaded in this session** (user-level and project-level instruction files such as `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, or the project's AGENTS.md) may fix models, effort, or which agent handles which kind of work. They override Heimdall's defaults: the agent roster (section 5) shows each purpose they fix as already decided, marked "from your instructions", and does not ask about it again. Record each override in STATE.md's Topology line (for example "coders: user rule → Sonnet at medium"), and a model or effort they fix as a user rule in the `Model plan:` line. Headless runs load the same user-level files.

## 5. The calibration message

One message per round, using the harness's question tool (harness-adapters.md, section 2) or numbered options. Every question has exactly one option marked "(Recommended)" from the evidence (workflow-stages.md, Stage 6), except the approvals question, which is explained below. A message holds at most four questions, and a session has at most two rounds.

### Build mode, round 1

Build-lite included. Except when section 3 makes this session decline the gate, round 1 is always sent. Four questions, in this order:

- **Q1, the orchestrator model plan.** The table in model-plan.md, section 2, with the recommended plan. When the model is unconfirmed, this one question also asks the user to confirm the model it runs as. Its options: "Plan as shown, running as <detected model> (Recommended)"; "Keep <model> for every phase"; "I am on a different model, or I will name my own plan". Switch points follow section 3.
- **Q2, the coders.** One question covering the three coder tiers (Light, Standard, Frontier). The first option is the recommended row for all three.
- **Q3, the supporting agents.** One question covering researcher, scout (brownfield only), reviewer, merger, and QA agent. The first option is the recommended row for each.
- **Q4, the budget.** Tight (small plan or rate limits: fewer agents, fewer research questions), standard, or generous (many parallel agents). Recommended: standard when nothing points either way.

**Pre-start disclosure.** Say this once in the round-1 message: until the approvals are answered, Heimdall only runs read-only checks, writes untracked `.heimdall/` files, and dispatches the agents the user chose.

### Build mode, round 2

Sent after round 1 is answered, with the approvals question. Single-row changes join it only when the user asks for them.

- **Approvals (one multiSelect question).** "Which classes may this build run without asking again?" The four options are the four classes of production-orchestrator.md, section 8: tracker writes; pushes and pull requests; merges and closes; reverts. Each ticked class is allowed for this build. Each unticked class is asked each time it comes up. The four classes fill the four options, so the recommended answer (all four, because the loop cannot run unattended without them, and each stays inside this build's tracker and branches) is written in the question text as "Recommended: all four" rather than as an option tag.
- **Single-row changes:** any roster row or plan row the user wants changed. Each is its own question, within the four-question limit.

### Direct and Prompt modes

No roster, no budget, and no approvals. The only calibration output is the one-line model check (model-plan.md, section 2), with its question when the model is below the recommended tier or unconfirmed.

### Rules for every round

- Skip any question the user's request already answers.
- "Just proceed" takes the recommended answers for the roster, the model plan, and the budget, and states them as assumptions (workflow-stages.md, Stage 6). It does not answer the approvals question. Until the approvals are answered, Heimdall only runs read-only checks, writes untracked `.heimdall/` files, and dispatches the agents the user chose (production-orchestrator.md, section 8). A blanket "just build it" never grants an approval.

### The agent roster (Build mode)

Heimdall never picks the agents on its own. Before the first dispatch (discovery researchers start at G0), ask the user which agent serves each purpose. When the mode is not yet certain at calibration, send the roster as the first message of Build mode, before G0's discovery research.

1. **Show the roster** as a table, one row per purpose: researcher (G0–G2 and per-ticket research), scout (G0.5 and loop pre-reads; brownfield only), coder for Light tickets, coder for Standard tickets, coder for Frontier tickets, reviewer, merger (conflicts only; the orchestrator does clean merges), and QA agent (G6). Each row shows the recommended agent (harness, model, effort), the dispatch method that agent implies (harness-adapters.md, section 1), and the alternatives available.
2. **Recommended rows** come from the role defaults in agent-model-map.md (the lowest capable tier), the purposes the instruction files fix (section 4), and agent-roles.md's family rule (a reviewer from another family when one is available). **Alternatives** are only what detection found: the session's own harness and models, the harnesses on `PATH` (section 4), and "my own tool" (user-driven). In the chat profile detection cannot see the user's tools: offer the families in agent-model-map.md, and the coding-agent harness that takes over the loop confirms on resume that each chosen agent is available there.
3. **Ask** with the calibration questions of round 1: Q2 covers the three coder tiers and Q3 covers the supporting agents. The first option of each is its recommended rows; the others are real alternatives, such as another vendor's agent or a cheaper or stronger set, and the user may name their own. A group that the instruction files fix entirely is shown in the table, not asked. Single-row changes follow in round 2.
4. **Name what another vendor costs.** A row that uses another vendor's harness says so: the run spends that vendor's quota and runs with that tool's permissions. Choosing that row is the consent production-orchestrator.md, section 2, requires.
5. **Record** the answers as the roster in the session profile (section 6). "Just proceed" takes the recommended rows: record them as the roster and state them as assumptions (workflow-stages.md, Stage 6). From then on only the user changes the roster: at G2, on resume when a chosen agent is missing, or through a `needs-human` question from the loop (execution-loop.md, section 8). Never dispatch to an agent the user did not choose.

The orchestrator is not a roster row. Its models are the model plan (Q1 above; model-plan.md, section 2), and its tier rules are in section 3.

## 6. Lock the Session Capability Profile

Record: harness, model with its source and confidence, effort, tier, profile (agent / chat), budget, question tool, available executor CLIs, tracker candidates, the agent roster, the model plan, and in Build mode the approvals. In Build mode they go into STATE.md: the roster in its Topology line, the plan in its `Model plan:` line, and the answers in its `Approvals:` line. In Prompt mode the profile is printed in every Delivery. Tell the user once: "Switch only at the plan's switch points, or tell Heimdall; it re-detects and follows model-plan.md, section 3."
