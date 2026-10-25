# Harness — Claude Code

Per-harness adapter (harness-adapters.md, section 3). Verified 2026-10-26 against Claude Code 2.1.310 (`claude --help` and live headless runs) and code.claude.com. Read when the topology uses Claude Code, at G2 and whenever a packet is dispatched to it.

## Subagents

- The Agent tool, or `.claude/agents/<name>.md` with `model:` (`haiku|sonnet|opus|fable|<full id>|inherit`), `effort:` (`low`–`max`), `tools:`, `isolation: worktree`. Subagents cannot call AskUserQuestion.
- Subagents from the orchestrating session work outside the project directory (`<worktree-root>`): add it with `/add-dir <worktree-root>` or `permissions.additionalDirectories` first.
- Subagents never outlive the session that spawned them. On resume, an `in-progress` ticket dispatched as a subagent has no live agent (execution-loop.md, section 9).

## Headless runs

Run every command from the main checkout. Launch, wait, and capture follow harness-adapters.md, section 1: background with `exec`, record `$!` in STATE.md (In flight), and treat the run as finished only when that PID has exited.

- **Coder:** `(cd <worktree> && exec claude -p "$(cat <abs packet>)" --model <alias> --effort <level> --permission-mode acceptEdits --add-dir <main checkout> --allowedTools "Bash(git add:*),Bash(git commit:*),Bash(git merge:*),Bash(git status:*),Bash(git diff:*),Bash(git log:*),Bash(git rev-parse:*),Bash(git show:*),Bash(git restore:*),Bash(<test runner>:*),Bash(<package manager>:*)" --max-turns <n> --output-format json > <abs report base>.json 2> <abs report base>.log) & echo $!`.
  - `acceptEdits` alone denies every shell command in `-p` mode (verified 2026-10-26: `git commit` was refused and reported under `permission_denials`). `--allowedTools` grants exactly the commands the packet needs — not `Bash(git:*)`, which would also allow `git push`, and never bare `Bash`.
  - `Bash(git restore:*)` lets the coder undo incidental lockfile drift (`git restore --source=<base> -- <lockfile>`) without the power to switch branches.
  - `--add-dir <main checkout>` lets the run read `.heimdall/`.
- **After the PID has exited:** `jq -r .result <abs report base>.json > <abs report>` writes the report. `jq -c '{is_error, num_turns, total_cost_usd, permission_denials}' <abs report base>.json` shows the outcome, the cost, and every refused command; record refused commands and the cost in STATE.md Health. Never pipe the JSON straight into the report at launch: the pipe creates an empty report file while the run is still working.
- **Reviewer:** the same command with `--allowedTools "Bash(git diff:*),Bash(git log:*),Bash(git rev-parse:*),Bash(git show:*),Bash(git status:*),Bash(<test command>:*),Bash(<type-check command>:*),Read,Grep,Glob" --disallowedTools "Edit,Write"`. The two prefixes are the full commands from HANDOFF Commands, for example `Bash(node --test:*)` and `Bash(npm run typecheck:*)`; never `Bash(node:*)`, `Bash(npm:*)`, or `Bash(python:*)`, which would let the reviewer run any code. The reviewer runs no scripts: the red-at-base result comes from the orchestrator's check report (`.heimdall/reports/T<nn>-checks-<round>.md`).
- **Merger:** the coder's grants plus `Bash(git checkout:*)` (taking one side of a mechanical conflict).
- `-p` skips the workspace-trust dialog: use it only in trusted project directories.
- User-level instruction files (`~/.claude/CLAUDE.md`, `~/.claude/rules/`) load in headless runs too. If they route models or roles, they override the topology's model choice for that run: calibration records them (calibration.md, section 4).

## Models

- Model and effort in session: `/model`, `/effort`.
- Other vendors' models via `ANTHROPIC_BASE_URL` (DeepSeek, Kimi, GLM, MiniMax, Meta): the slot names (`opus`, `sonnet`, `haiku`) then map to that vendor's models. Record the real model in STATE.md.
