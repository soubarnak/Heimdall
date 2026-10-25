# Harness Adapters

Verified 2026-10-25 against vendor docs (Context7 and official pages) and the locally installed CLIs: Claude Code 2.1.310, Codex CLI 0.163.0, Muse Code 1.4.13, OpenCode 2.1.4, pi 1.4.0, Antigravity CLI 1.4.6; section 1 re-checked 2026-10-26 when the per-harness adapters moved to their own files. Rows marked UNVERIFIED come from a third-party summary only.

Use this file to: detect the harness (calibration.md), pick the dispatch method for each role (production-orchestrator.md, G2; agent-roles.md), write headless commands for coder, reviewer, merger, and researcher packets (execution-loop.md), and know which question tool to use.

## Contents

1. Dispatch methods
2. Harness table (skills, instructions, questions)
3. Per-harness adapters (one file per harness)
4. Chat apps (chat profile)
5. Cross-vendor models inside one harness

## 1. Dispatch methods

Pick one per role at G2 and record it in Settled Decisions (the execution topology). Prefer the first that the harness supports. Coders always work in their own worktree (merge-protocol.md, L4): a subagent gets the absolute worktree path and does all work there (`git -C <worktree> …` or `cd <worktree>`); a headless run starts with the worktree as its working directory.

| Method | When | How |
|---|---|---|
| **Subagent** | Harness has subagents (Claude Code, Codex, Muse Code, OpenCode, Gemini CLI, Cursor) | Spawn a background child with the packet's Prompt section, the pinned model and effort, and write access to its worktree. Its final message is the report; save it to `.heimdall/reports/`. |
| **Headless harness** | Executor is a different harness or vendor (tandem), or the user wants isolation | Run the harness's non-interactive command (its file in section 3) with the packet file as input. Needs explicit user consent: it spends that vendor's quota and runs with that tool's permissions. |
| **Same session** | No subagents (pi without extensions) or a tiny packet | Checkpoint STATE.md, adopt the role, follow the packet exactly in the worktree, write the report, switch back. Cap 1 (execution-loop.md, section 10). |
| **User-driven** | Executor is a GUI tool (Cursor, Copilot in an IDE) or the user wants control | Emit numbered next steps (production-orchestrator.md, section 6). |

Rules for every method:

- Subagents and headless runs cannot ask the user questions (Claude Code subagents have no AskUserQuestion; `vibe --prompt` disables `ask_user_question`; Muse `--user-input-auto-resolve` cancels prompts). Gates therefore always run in the orchestrating session. Packets tell executors to stop and report when blocked.
- Never pass a permission-bypass flag (`--dangerously-skip-permissions`, `--dangerously-bypass-approvals-and-sandbox`, `--yolo`, `--auto`, `-s danger-full-access`, `--permission-mode bypassPermissions`) unless the user asks for it for that run.
- One worktree and branch per ticket (`heimdall/t<nn>-<slug>`), created by the orchestrator from the integration tip. A harness's own worktree isolation is acceptable only if it bases the worktree on the integration tip.
- Coders need network access only for dependency installs (for example Codex `-c sandbox_workspace_write.network_access=true` for the tickets that hold the `deps` hotspot). Reviewers need none. Coders and reviewers never need tracker access or push rights. The orchestrator's ticket checks (execution-loop.md, section 5) run the Install command in a scratch worktree, so the orchestrating session needs the network for that step unless the package cache is warm.
- **Working directory:** run every headless command from the main checkout, in a subshell that enters the worktree — `(cd <worktree> && <command>)` — or with the CLI's own directory flag (`-C <worktree>` for Codex). Packet and report paths are always absolute, under the main checkout's `.heimdall/`.
- **Report capture:** every headless run must leave its final message at `.heimdall/reports/T<nn>-<role>-<r>.md`; the per-harness line below says how (an output flag, or stdout redirected). If the file is missing or empty afterwards, treat the run as an executor failure (execution-loop.md, section 8).
- **Shell for coders, reviewers, and mergers:** a headless coder runs the test runner and the package manager and commits; a reviewer runs tests and read-only git commands and no scripts; a merger needs what a coder needs plus taking one side of a mechanical conflict. Grant exactly those commands. A linked worktree commits into the main checkout's `.git`, so sandboxes that confine writes to the worktree (Codex `workspace-write`) also need the main checkout's `.git` as a writable root for coders and mergers. The ticket checks' scratch worktree lives under `<worktree-root>` and is created by the orchestrator, not by an agent.
- **Directories:** agents read packets, HANDOFF, and the spec under the main checkout's `.heimdall/` and work under `<worktree-root>`, which sits outside the project directory. Harnesses that confine file tools to the working directory need both granted (harness-claude-code.md for Claude Code). The hello-world check (assets/setup-packet.md, step 6) exercises exactly these grants before the loop starts: it reads from `.heimdall/`, writes and commits in a scratch worktree, and runs git there.
- **Liveness:** subagents never outlive the orchestrating session. For every background headless run, record its PID in STATE.md (In flight) so a resumed session can test it with `kill -0 <pid>` (execution-loop.md, section 9).

## 2. Harness table

| Harness | User skill dir | Project skill dir | Instruction file | Question tool |
|---|---|---|---|---|
| Claude Code | `~/.claude/skills/` (or plugin) | `.claude/skills/` | `CLAUDE.md`; `AGENTS.md` only when no CLAUDE.md exists (v2.1.277+) | `AskUserQuestion` (1–4 questions, 2–4 options; main session only) |
| Codex CLI | `~/.agents/skills/` (also `~/.codex/skills/` in source) | `.agents/skills/` | `AGENTS.md` (+ `~/.codex/AGENTS.md`) | none documented — number options in text |
| Muse Code | `~/.agents/skills/`, `$XDG_CONFIG_HOME/muse/skills`; also reads `~/.claude/skills`, `~/.codex/skills` | `.agents/skills/`, `.claude/skills/`, `.codex/skills/` (after workspace trust) | `AGENTS.md` > `CLAUDE.md` > `.agents/AGENTS.md` > `.claude/CLAUDE.md` | `request_user_input` |
| OpenCode | `~/.config/opencode/skills/`, `~/.agents/skills/`, `~/.claude/skills/` | `.opencode/skills/`, `.agents/skills/`, `.claude/skills/` | `AGENTS.md` (CLAUDE.md fallback: docs conflict) | `question` (enable `"permission": {"question": "allow"}`) |
| pi | `~/.agents/skills/` (plus settings `skills` array) | `.agents/skills/` (after trust) | `AGENTS.md` or `CLAUDE.md` (first per directory) | `ask_question` (behavior UNVERIFIED) |
| Gemini CLI | `~/.gemini/skills/` or `~/.agents/skills/` | `.gemini/skills/` or `.agents/skills/` (trusted folder) | `GEMINI.md`; AGENTS.md only if added to `context.fileName` | UNVERIFIED |
| Antigravity CLI (`agy`) | `~/.gemini/antigravity-cli/skills/` (UNVERIFIED) | `.agents/skills/` (UNVERIFIED) | UNVERIFIED | UNVERIFIED |
| Qwen Code | `~/.qwen/skills/` | `.qwen/skills/` | `QWEN.md`; also reads `AGENTS.md` | UNVERIFIED |
| Mistral Vibe | `~/.vibe/skills/`, `~/.agents/skills/` | `.vibe/skills/`, `.agents/skills/` (trusted) | `AGENTS.md` (trusted folders) | `ask_user_question` (disabled in `vibe --prompt`) |
| Grok Build | `~/.grok/skills/`, `~/.agents/skills/` | `.grok/skills/` | `AGENTS.md`, `CLAUDE.md`, `.claude/rules/` | UNVERIFIED |
| Kimi Code CLI | `~/.kimi-code/skills/`, `~/.agents/skills/` | `.kimi-code/skills/`, `.agents/skills/` | `AGENTS.md` (`~/.kimi-code/`, `~/.agents/`, project) | UNVERIFIED |
| Cursor | `~/.cursor/skills/`, `~/.agents/skills/` (also `~/.claude/skills`, `~/.codex/skills`) | `.agents/skills/`, `.cursor/skills/` | UNVERIFIED | UNVERIFIED |
| GitHub Copilot | `~/.copilot/skills/` or `~/.agents/skills/` | `.github/skills/`, `.agents/skills/`, `.claude/skills/` | UNVERIFIED | UNVERIFIED |

Key consequence: **one copy in `~/.agents/skills/heimdall` serves every harness above except Claude Code and Qwen Code.** Claude Code needs `~/.claude/skills/heimdall` or the plugin; Qwen Code needs `~/.qwen/skills/heimdall`. INSTALL.md at the repo root has the commands.

Invocation: Claude Code `/heimdall` (plugin: `/heimdall:heimdall`); Codex `$heimdall` or `/skills`; other harnesses `/heimdall` or the skill picker; every harness also activates it from the description ("use Heimdall", "take this idea to shipment").

## 3. Per-harness adapters

Each harness's subagent mechanism, its headless command per role (coder, reviewer, merger), report capture, and install notes live in one file per harness. Load only the files for the harnesses in the topology.

| Harness | File |
|---|---|
| Claude Code | harness-claude-code.md |
| Codex CLI | harness-codex.md |
| Muse Code | harness-muse-code.md |
| OpenCode, pi, Gemini CLI, Antigravity CLI, Qwen Code, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, GitHub Copilot | harness-others.md |

## 4. Chat apps (chat profile)

claude.ai, ChatGPT, Meta AI, Gemini app, and other chat surfaces have no file or shell tools. Run Heimdall in the chat profile:

- Upload SKILL.md and the references as project knowledge (claude.ai Projects, a custom GPT, a Gem) or paste SKILL.md as custom instructions and attach references when a stage needs them.
- Every artifact is emitted in full in the message; the user saves files and relays reports. Build mode's loop runs in a coding-agent harness (execution-loop.md, section 10).
- Use the app's deep-research or web-search mode for research Pathway B (research-advisor-playbook.md).

## 5. Cross-vendor models inside one harness

Several vendors document running their models inside another vendor's harness: DeepSeek, Kimi, GLM, MiniMax, and Meta (Claude Code via `ANTHROPIC_BASE_URL`; Codex via `base_url` + `wire_api = "responses"`; OpenCode via providers; pi via `provider/model`). Rules:

- The **model's** family file decides prompting and effort (prompting-<family>.md); the **harness** decides tools, dispatch, and file layout (this file).
- Harness features the endpoint ignores stay off: DeepSeek's Anthropic endpoint ignores `cache_control`; Kimi rejects custom sampling; Meta hosted rejects `tool_choice` other than `auto`.
- Record the effective model, not the harness's slot alias, in STATE.md and every report.
