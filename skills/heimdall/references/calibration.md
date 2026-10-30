# Calibration — Step 0 of Every Session

Run before any other work, on the first message of a session that invokes Heimdall. Calibration is mostly **detection**, with at most one calibration message (section 5; a second round only when the user changes single roster rows or a question is still open). In Build mode that message is always sent, because it asks the user which agent serves each purpose (the agent roster). In the other modes it is sent only when the evidence is unclear.

## 1. Resume check

- Agent profile: if `.heimdall/STATE.md` exists in the project, this is a resumed build. Run sections 2–4 as usual (detection only), skip the message in section 5 (the roster is already in STATE.md), then follow the resume protocol (production-orchestrator.md, section 5): it compares what you detected with the recorded profile, applies the tier rules to the model running now, and migrates STATE.md. Section 6 updates the profile in STATE.md.
- Chat profile: if the message contains a pasted STATE.md, the same applies.
- A repository with a GitHub or Gitea remote but no `.heimdall/` folder may be a build started on another machine: look for an open issue labelled `heimdall:spec` (`gh issue list --label heimdall:spec` / `tea issues list --labels heimdall:spec`). If one exists, it is a resumed build (the resume protocol rebuilds `.heimdall/` from it).

## 2. Detect the harness and profile

Use the evidence you already have; do not ask.

| Evidence | Harness |
|---|---|
| Tools `AskUserQuestion` and `Agent`; `CLAUDECODE=1` in the shell environment (`CLAUDE_EFFORT` holds the effort level) | Claude Code |
| Tools `spawn_agent` / `wait_agent` | Codex CLI |
| Tool `request_user_input` | Muse Code |
| Tool `question`; `.opencode/` directory | OpenCode |
| Tool `ask_question` and no subagent tool | pi |
| Tool `ask_user_question` | Mistral Vibe |
| The system prompt names the harness | that harness |
| No file or shell tools at all | a chat app → **chat profile** |

File and shell tools present → **agent profile**. If the harness is still unknown, say so and use the generic rules in harness-adapters.md (number the options in plain text; same-session dispatch).

## 3. Detect the model and tier

State which model you are running as (from the system prompt or self-knowledge) and map it to a tier with agent-model-map.md. The tier decides what you may do:

- **Light:** Direct mode and Prompt mode with merged analysis stages and a mechanical checklist; one interview round; no critic loop. In Build mode: decline the planning gates G0–G3 and the QA and ship gates G6–G7 ("re-run Heimdall with a Standard or Frontier model for this gate"); you may run the build loop G4–G5 of a build whose G3 is already locked, and Build-lite on the user's explicit "orchestrate anyway", under the Light-tier conditions in production-orchestrator.md, section 3. You may always serve as a coder for Light tickets.
- **Standard:** everything, with standard bounds.
- **Frontier:** everything, plus deeper adversarial critique of specs, ADRs, and packets.

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

- **No repository:** an empty folder or loose files. Greenfield; G0 runs `git init -b main` (production-orchestrator.md, G0).
- **No git identity:** the bootstrap commit at G3 would fail. G0 asks the user to set one for this repository; never set it yourself.
- **No remote:** the local tracker, unless the user accepts the G2 offer of a new private repository.
- **The instructions already loaded in this session** (user-level and project-level instruction files such as `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, or the project's AGENTS.md) may fix models, effort, or which agent handles which kind of work. They override Heimdall's defaults: the agent roster (section 5) shows each purpose they fix as already decided, marked "from your instructions", and does not ask about it again. Record each override in STATE.md's Topology line (for example "coders: user rule → Sonnet at medium"). Headless runs load the same user-level files.

## 5. The calibration message

One message, using the harness's question tool (harness-adapters.md, section 2) or numbered options. Every question in it has one option marked "(Recommended)" from the evidence (workflow-stages.md, Stage 6). It can hold:

- the **agent roster**: Build mode (Build-lite included) only, and always asked there (below), except when section 3 makes this session decline the gate; Build-lite on "orchestrate anyway" still asks it;
- the **budget**: tight (small plan or rate limits — fewer agents, fewer research questions), standard, or generous (many parallel agents); recommended: standard when nothing points either way;
- the model or effort, only if you could not determine it.

Skip any question the user's request already answers. Skip the message entirely in Direct mode, and in Prompt mode when nothing is unclear.

### The agent roster (Build mode)

Heimdall never picks the agents on its own. Before the first dispatch (discovery researchers start at G0), ask the user which agent serves each purpose. When the mode is not yet certain at calibration, send the roster as the first message of Build mode, before G0's discovery research.

1. **Show the roster** as a table, one row per purpose: researcher (G0–G2 and per-ticket research), scout (G0.5 and loop pre-reads; brownfield only), coder for Light tickets, coder for Standard tickets, coder for Frontier tickets, reviewer, merger (conflicts only; the orchestrator does clean merges), and QA agent (G6). Each row shows the recommended agent (harness, model, effort), the dispatch method that agent implies (harness-adapters.md, section 1), and the alternatives available.
2. **Recommended rows** come from the role defaults in agent-model-map.md (the lowest capable tier), the purposes the instruction files fix (section 4), and agent-roles.md's family rule (a reviewer from another family when one is available). **Alternatives** are only what detection found: the session's own harness and models, the harnesses on `PATH` (section 4), and "my own tool" (user-driven). In the chat profile detection cannot see the user's tools: offer the families in agent-model-map.md, and the coding-agent harness that takes over the loop confirms on resume that each chosen agent is available there.
3. **Ask** with up to three questions, one per group: research (researcher, scout), coding (the three coder tiers), and review (reviewer, merger, QA agent). The budget is the fourth. The first option of each group is its recommended rows; the others are real alternatives, such as another vendor's agent or a cheaper or stronger set, and the user may name their own. A group that the instruction files fix entirely is shown in the table, not asked. When the model or effort question is also needed, or the user wants to change single rows, a second round follows (at most two rounds).
4. **Name what another vendor costs.** A row that uses another vendor's harness says so: the run spends that vendor's quota and runs with that tool's permissions. Choosing that row is the consent production-orchestrator.md, section 2, requires.
5. **Record** the answers as the roster in the session profile (section 6). "Just proceed" takes the recommended rows: record them as the roster and state them as assumptions (workflow-stages.md, Stage 6). From then on only the user changes the roster: at G2, on resume when a chosen agent is missing, or through a `needs-human` question from the loop (execution-loop.md, section 8). Never dispatch to an agent the user did not choose.

The orchestrator is not a roster row: it is the session the user invoked, and its tier rules are in section 3.

## 6. Lock the Session Capability Profile

Record: harness, model, effort, tier, profile (agent / chat), budget, question tool, available executor CLIs, tracker candidates, and in Build mode the agent roster. In Build mode it goes into STATE.md (the roster in its Topology line); in Prompt mode it is printed in every Delivery. Tell the user once: "Please don't change model or effort mid-session — if you must, tell me and I'll recalibrate."
