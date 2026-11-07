# Harness — Claude Code

Per-harness adapter (harness-adapters.md, section 3). Verified 2026-10-26 against Claude Code 2.1.310 (`claude --help` and live headless runs) and code.claude.com. Models and invocation re-checked 2026-11-07 against Claude Code 2.1.319 (live headless runs and the stream-json `system/init` event). Read when the topology uses Claude Code, at G2 and whenever a packet is dispatched to it.

## Subagents

- The Agent tool, or `.claude/agents/<name>.md` with `model:` (`haiku|sonnet|opus|fable|<full id>|inherit`), `effort:` (`low`–`max`), `tools:`, `isolation: worktree`. Subagents cannot call AskUserQuestion. In every Agent tool call, pass `model` and `effort` explicitly; never `inherit` (harness-adapters.md, section 1; model-plan.md, section 4).
- Subagents from the orchestrating session work outside the project directory (`<worktree-root>`): add it with `/add-dir <worktree-root>` or `permissions.additionalDirectories` first.
- Subagents never outlive the session that spawned them. On resume, an `in-progress` ticket dispatched as a subagent has no live agent (execution-loop.md, section 9).

## Headless runs

Run every command from the main checkout. Launch, wait, and capture follow harness-adapters.md, section 1: background with `exec`, record `$!` in STATE.md (In flight), and treat the run as finished only when that PID has exited.

- **Coder:** `(cd <worktree> && exec claude -p "$(cat <abs packet>)" --model <alias> --effort <level> --permission-mode acceptEdits --add-dir <main checkout> --allowedTools "Bash(git add:*),Bash(git commit:*),Bash(git merge:*),Bash(git status:*),Bash(git diff:*),Bash(git log:*),Bash(git rev-parse:*),Bash(git show:*),Bash(git restore:*),Bash(<test runner>:*),Bash(<package manager>:*)" --max-turns <n> --output-format json > <abs report base>.json 2> <abs report base>.log) & echo $!`.
  - `acceptEdits` alone denies every shell command in `-p` mode (verified 2026-10-26: `git commit` was refused and reported under `permission_denials`). `--allowedTools` grants exactly the commands the packet needs — not `Bash(git:*)`, which would also allow `git push`, and never bare `Bash`.
  - `Bash(git restore:*)` lets the coder undo incidental lockfile drift (`git restore --source=<base> -- <lockfile>`) without the power to switch branches.
  - `--add-dir <main checkout>` lets the run read `.heimdall/`.
- **After the PID has exited:** `jq -r .result <abs report base>.json > <abs report>` writes the report. `jq -c '{is_error, num_turns, total_cost_usd, permission_denials}' <abs report base>.json` shows the outcome, the cost, and every refused command; record refused commands and the cost in STATE.md Health. `jq -r '.modelUsage | keys[]' <abs report base>.json` lists the model ids the run actually used (checked 2026-11-07); record them in STATE.md and in the report's `Coder:` or `Reviewer:` line, and treat any other id as a mismatch (model-plan.md, section 4). Never pipe the JSON straight into the report at launch: the pipe creates an empty report file while the run is still working.
- **Reviewer:** the same command with `--allowedTools "Bash(git diff:*),Bash(git log:*),Bash(git rev-parse:*),Bash(git show:*),Bash(git status:*),Bash(<test command>:*),Bash(<type-check command>:*),Read,Grep,Glob" --disallowedTools "Edit,Write"`. The two prefixes are the full commands from HANDOFF Commands, for example `Bash(node --test:*)` and `Bash(npm run typecheck:*)`; never `Bash(node:*)`, `Bash(npm:*)`, or `Bash(python:*)`, which would let the reviewer run any code. The reviewer runs no scripts: the red-at-base result comes from the orchestrator's check report (`.heimdall/reports/T<nn>-checks-<round>.md`).
- **Merger:** the coder's grants plus `Bash(git checkout:*)` (taking one side of a mechanical conflict).
- `-p` skips the workspace-trust dialog: use it only in trusted project directories.
- User-level instruction files (`~/.claude/CLAUDE.md`, `~/.claude/rules/`) load in headless runs too. If they route models or roles, they override the topology's model choice for that run: calibration records them (calibration.md, section 4).

## Models

- **Switch:** `/model <alias>` and `/effort <level>` in the session, or `claude --model <alias>` at launch. The user runs them. Claude Code has no model-callable tool that changes the session model (checked 2026-11-07), so Heimdall gives the command and waits, unless a host tool exists (model-plan.md, section 3).
- **Desktop app:** the Claude desktop app exposes `set_session_model` through its session tools (in the desktop session's tool list it is `mcp__ccd_session_mgmt__set_session_model`, deferred: load it with ToolSearch first). Heimdall calls it only after the user's yes. Other hosts are UNVERIFIED.
- **Detection, strongest first:** the session's system prompt names the model id; the stream-json `system/init` event carries `model` (checked 2026-11-07 with `claude -p "ok" --output-format stream-json --verbose`); the statusline's JSON `model.id`; a SessionStart hook's `model` field. The settings `model` key and `ANTHROPIC_MODEL` set the default only, and `/model` overrides them, so they are a hint, not a report. No documented environment variable reports the running model; `CLAUDE_EFFORT` reports effort only.
- **Headless default is not the session model:** a `claude -p` run with no `--model` uses the default from the user's settings `model` key or environment, which can differ from the model the interactive session is running (checked 2026-11-07). The `--output-format json` result carries `modelUsage`, keyed by full model id. Every headless command passes `--model` and `--effort`.
- **Skills:** a skill's `model:` frontmatter applies for one turn; it is not a pin. The Agent tool's `model` parameter sets one subagent's model, not the session's.
- Other vendors' models via `ANTHROPIC_BASE_URL` (DeepSeek, Kimi, GLM, MiniMax, Meta): the slot names (`opus`, `sonnet`, `haiku`) then map to that vendor's models. Record the real model in STATE.md.
