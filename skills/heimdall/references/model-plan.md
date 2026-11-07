# Model Plan — Detection, the Plan, Switching, and Pinning

Read at Step 0, at every phase boundary, on resume, after any switch, and before every dispatch (section 4). This file is the single source for which model Heimdall runs as, which model each phase should use, how a switch happens, and how every dispatch pins its model and effort. calibration.md, agent-model-map.md, execution-loop.md, and the harness files cite it by section number.

Verified 2026-11-07 against Claude Code 2.1.319 and Codex 0.166.0. Anything not checked against those versions is marked UNVERIFIED, and an UNVERIFIED fact is never relied on until it has been checked on the user's build.

## 1. Detection

Heimdall detects the model it runs as, and the effort, before it says anything about either. For each one it records three things: the value, its source, and a confidence level. Detection never guesses silently. Use the first rung of this ladder that gives an answer.

1. **The system prompt or the harness names the model id.** Confidence: confirmed. This includes a statusline or SessionStart hook payload that carries the model (Claude Code: `model.id` in the statusline JSON) and the `system/init` event of a stream-json run, when the harness exposes them to you. A system prompt that names the model is observed in practice but is not a documented contract, so record its source as "system prompt".
2. **Harness configuration, read by key only.** Confidence: unconfirmed, a hint only. A configuration key is the default a session starts from; a `/model` change, a flag, or a host setting can override it without leaving a trace the shell can read, so it never counts as proof of the running model. Read one key at a time and print only its value. Never read a whole settings file, and never read `auth.json` or any file that holds tokens. The keys are:
   - **Claude Code:** the `ANTHROPIC_MODEL` environment variable and the `model` key in `settings.json` (verified 2026-11-07). The precedence between them, and between project and user settings, is UNVERIFIED. When they disagree, treat the result as unconfirmed (rung 3).
   - **Codex CLI:** the top-level `model` key in `~/.codex/config.toml`. Codex reads that key (verified 2026-11-07). Its exact form and its precedence over a `-m` flag at launch are UNVERIFIED, so prefer asking the user when the result is in doubt. Read it with `grep -m1 -E '^model *=' ~/.codex/config.toml`, which prints one line.
   - **Muse Code:** a model key in its settings file. The key name is UNVERIFIED. Ask the user to name the model rather than guessing the key.
   - **Other harnesses:** no configuration key is verified. Use rung 3 or rung 4.

   A configured value shows the model the session started with. Use it to name the likely model in the calibration question, and treat the answer as unconfirmed until the user confirms it or rung 1 names the model. After any `/model` change in this session, the configured value is out of date.
3. **Self-knowledge only.** Confidence: unconfirmed. Name the model you believe you run as, and say why. The calibration message then asks the user to confirm it (calibration.md, section 5). Until the user confirms, apply the tier rules to the model named here and say that the model is unconfirmed.
4. **Unknown.** Confidence: unknown. Ask the user which model this session runs, with numbered options. Put the most likely model first as the recommended answer. Apply no tier until the user answers.

Effort is detected by the same ladder. Claude Code exposes the effort level in the `CLAUDE_EFFORT` environment variable (verified 2026-11-07). That variable carries effort only, never the model. For Codex, the effort key is `model_reasoning_effort` (the name agent-model-map.md uses); the key's place in `config.toml` and the effective value at run time are UNVERIFIED. Muse Code and the other harnesses are UNVERIFIED for effort.

Re-detect at every phase boundary (each gate lock from G1 on, and each switch point), on resume, and after any switch. A re-detection that differs from the recorded model goes to the switch protocol (section 3).

Record the result in the `Model plan:` line of STATE.md (assets/state.md) and in the Session Capability Profile (calibration.md, section 6). For example: `model claude-sonnet-5-5 (system prompt, confirmed); effort high (CLAUDE_EFFORT)`.

## 2. The model plan

In Build mode the plan has two parts. The first is the agent roster from calibration.md, section 5: the agent for each purpose, with its recommended tier, effort, and dispatch method, as agent-model-map.md, role defaults, describes. The second is one orchestrator row per phase, because the session that runs the gates is itself a model choice. Each orchestrator row names its recommended tier and its switch point:

| Orchestrator row | Recommended tier | Switch point |
|---|---|---|
| Planning, G0–G3 | Frontier. Standard is the floor. Light declines these gates (calibration.md, section 3). | none. A Standard session meets the floor, and Q1 shows the gap to Frontier; if the user changes the model, that is their own command. |
| Build loop, G4–G5 | Standard. Light only under the Light-tier conditions in production-orchestrator.md, section 3. | G3→G4 |
| QA and ship, G6–G7 | Standard | G5→G6 |

Each row also says how to switch in the detected harness, using the commands in the list below. The plan is written to the `Model plan:` line of STATE.md with one clause per row, for example: `Model plan: planning G0–G3 Frontier (now claude-opus-5-5, confirmed); build loop G4–G5 Standard, switch at G3→G4 with /model sonnet and /effort high; QA and ship G6–G7 Standard, switch at G5→G6 with the same command.` The clause for an unconfirmed model says so.

How to switch, per harness. The user runs these commands. Heimdall runs one only through a host tool, under section 3.

- **Claude Code CLI:** `/model <alias or id>` and `/effort <level>` in the session (for example `/model sonnet` and `/effort high`). A new session in the same project also works: start `claude --model <alias or id>`, set the effort with `/effort <level>`, and then say "continue Heimdall". No model-callable tool in the CLI changes the session model (verified 2026-11-07).
- **Claude desktop app:** a host tool named `set_session_model` (listed as `mcp__ccd_session_mgmt__set_session_model`) sets the session model. Load its schema if it is deferred, and call it only after the user's yes (section 3).
- **Codex CLI:** `/model` in the session (agent-model-map.md). A new session started with the model flag is also possible; the headless form `codex exec -m <id>` is listed in agent-model-map.md, and the interactive form of the flag is UNVERIFIED. No model-callable tool is verified to change the session model (UNVERIFIED).
- **Muse Code:** a new session with the chosen model, or the model profile described in harness-muse-code.md. The in-session command is UNVERIFIED.
- **Other harnesses** (OpenCode, pi, Gemini CLI, Antigravity CLI, Qwen Code, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, GitHub Copilot): the model picker or `/model`, as harness-others.md and agent-model-map.md list it. Any command they do not list is UNVERIFIED and is not given to the user as fact.

Direct and Prompt modes do not plan phases and do not keep STATE.md. They print one line after detection:

The line reads: `Running as <model> (<tier>, <source>). Recommended for this task: <tier and model>.`

The recommendation follows the tiers in agent-model-map.md. For a small Direct change (C0 or C1), Standard. For hard debugging, Frontier. For a Prompt-mode request, Standard for a single prompt or packet, Frontier for a multi-stage workflow plan (workflow-stages.md). A question follows the line only when the current model is below the recommended tier or unconfirmed. Its options are "switch now (Recommended)", which runs section 3 without the checkpoint step, and "continue anyway". The answer is printed in the Session Capability Profile of the Delivery in Prompt mode, and it is noted in the reply in Direct mode.

## 3. The switch protocol

Heimdall never changes the model on its own. Run this protocol at each switch point (G3→G4 and G5→G6 in Build mode; the Direct and Prompt question in section 2), and whenever a re-detection differs from the plan.

1. **Checkpoint.** In Build mode, write STATE.md now: the current gate, the `Model plan:` line with the pending switch (for example "switch to claude-sonnet-5-5 pending at G3→G4"), and the approvals. Direct and Prompt modes have no STATE.md, so skip this step.
2. **Host tool, if one is listed.** Look in the tool list for a tool that sets the session model, detected by its name: `set_session_model` (in the Claude desktop app, `mcp__ccd_session_mgmt__set_session_model`). Load its schema if it is deferred. Ask the user for a yes, naming the model: "Switch this session's model to <model> for the build loop? Yes or no." Call the tool only after a yes, then re-detect. The tool sets the model only. If the plan names an effort, the user sets it with `/effort <level>`, unless a listed host tool sets effort too (none is verified; UNVERIFIED). Any other host: UNVERIFIED, so assume no such tool exists until it is seen in the list.
3. **Otherwise, stop and give numbered steps.** Give the exact command for the detected harness (section 2). For example: 1. Run /model sonnet, then /effort high, in this session. 2. Say "continue Heimdall". A new session in the same project works as well, with the command shown in section 2. Then end the turn. Do not run any further phase.
4. **On the next turn, re-detect** (section 1) and compare the result with the plan.
   - **Match:** proceed with the phase.
   - **No match:** ask the user, with the recommended answer first. Options: switch again (Recommended; the steps in step 3 again), or continue on the current model. Continuing updates the `Model plan:` line to the model that is running. When that model is below the tier of the phase, it also records an accepted risk in STATE.md ("<phase> orchestrated at <tier> model"), as the resume protocol does (production-orchestrator.md, section 5, step 2).

Never continue past a switch point on a model that is not in the plan without that answer. The resume protocol's changed-model step (production-orchestrator.md, section 5, step 2) applies to every detected change: say so in the message, re-check the topology, and apply the tier rules to the model running now.

Two things do not switch the model. The Agent tool's model parameter sets a subagent's model, not the session's. A skill's `model:` frontmatter is turn-scoped and is not a pin (verified 2026-11-07).

## 4. Pinning and executor verification

Every dispatch pins the model and the effort explicitly, and every dispatch is checked before it leaves.

1. **Pin on dispatch.** Pass the model and the effort in the dispatch itself. In Claude Code, that is the model parameter of the Agent tool, and its effort field when the roster names an effort; or the `model:` and `effort:` keys of `.claude/agents/<name>.md` (harness-claude-code.md). For a headless run, that is `--model` (or `-m`) with the effort flag (agent-model-map.md, "Selecting model and effort per harness"). Never pass `inherit`, and never leave the flag out: an omitted model falls back to the harness default, which can be the session's own model.
2. **Pre-flight.** Before each dispatch, compare three things: the `For:` line of the packet (model and effort), the roster row in the Topology line of STATE.md, and the command's flags or the subagent's model parameter. If any two differ, do not dispatch. Fix the one that is wrong, or ask the user. execution-loop.md, section 5, step 4 runs this check.
3. **Verify after the run.** When a headless run has exited (execution-loop.md, section 5, step 5), read the effective model from its output where the harness reports it. For Claude Code run with `--output-format json`, the output carries `modelUsage`, keyed by model name. That is documented, but confirm it on your build with `claude -p "ok" --output-format json | jq '.modelUsage'`. Other harnesses: UNVERIFIED, so do not assume a field exists. Where nothing reports the model, use the return report's `Coder:` or `Reviewer:` line (`<harness> / <model> / effort`) as a self-report, and record in Health that it is self-reported. A mismatch between the effective or self-reported model and the pinned one is recorded in Health, and it becomes a `needs-human` item for that ticket (execution-loop.md, section 8).
4. **Harness that cannot pin.** If a harness cannot pin the model, say so in the packet and require the red-at-base check for that ticket (agent-model-map.md, pinning rules).
