# Calibration — Step 0 of Every Session

Run before any other work, on the first message of a session that invokes Heimdall. Calibration is mostly **detection**, not questions: at most one calibration question, and none when the evidence is clear.

## 1. Resume check

- Agent profile: if `.heimdall/STATE.md` exists in the project, this is a resumed build. Follow the resume protocol (production-orchestrator.md, section 5) and skip the rest of this file except section 6.
- Chat profile: if the message contains a pasted STATE.md, the same applies.

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
for c in claude codex muse opencode pi agy gemini qwen vibe grok kimi gh tea podman chromium chromium-browser google-chrome; do command -v "$c" >/dev/null && echo "$c"; done
gh auth status 2>&1 | head -3        # signed-in account only
tea login list 2>/dev/null           # login names and hosts only
ls AGENTS.md CLAUDE.md .heimdall 2>/dev/null
```

These answers decide: greenfield or brownfield, the tracker candidates (execution-loop.md, section 2), and which harnesses can serve as headless coders, reviewers, or researchers in the topology (agent-roles.md). A headless-capable browser (Chromium or Chrome, or the harness's own browser tool) lets the progress report carry screenshots of the design screens; without one, the report embeds the HTML screens instead.

## 5. The one calibration question (only if needed)

Ask only what detection cannot answer, in one message, using the harness's question tool (harness-adapters.md, section 2) or numbered options, with one option marked "(Recommended)" from the evidence (budget: standard when nothing points either way):

- the **budget**: tight (small plan or rate limits — fewer agents, fewer research questions), standard, or generous (many parallel agents);
- the model or effort, only if you could not determine it.

Skip the question entirely when the user's request already states these, or the work is Direct mode.

## 6. Lock the Session Capability Profile

Record: harness, model, effort, tier, profile (agent / chat), budget, question tool, available executor CLIs, tracker candidates. In Build mode it goes into STATE.md; in Prompt mode it is printed in every Delivery. Tell the user once: "Please don't change model or effort mid-session — if you must, tell me and I'll recalibrate."
