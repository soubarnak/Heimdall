# Harness Adapters

Verified 2026-10-25 against vendor docs (Context7 and official pages) and the locally installed CLIs: Claude Code 2.1.310, Codex CLI 0.163.0, Muse Code 1.4.13, OpenCode 2.1.4, pi 1.4.0, Antigravity CLI 1.4.6. Rows marked UNVERIFIED come from a third-party summary only.

Use this file to: detect the harness (calibration.md), pick the dispatch method for each role (production-orchestrator.md, G2; agent-roles.md), write headless commands for coder, reviewer, merger, and researcher packets (execution-loop.md), and know which question tool to use.

## Contents

1. Dispatch methods
2. Harness table (skills, instructions, questions)
3. Per-harness adapters: Claude Code · Codex CLI · Muse Code · OpenCode · pi · Gemini CLI · Antigravity CLI · Qwen Code · Mistral Vibe · Grok Build · Kimi Code CLI · Cursor · GitHub Copilot
4. Chat apps (chat profile)
5. Cross-vendor models inside one harness

## 1. Dispatch methods

Pick one per role at G2 and record it in Settled Decisions (the execution topology). Prefer the first that the harness supports. Coders always work in their own worktree (merge-protocol.md, L4): a subagent gets the absolute worktree path and does all work there (`git -C <worktree> …` or `cd <worktree>`); a headless run starts with the worktree as its working directory.

| Method | When | How |
|---|---|---|
| **Subagent** | Harness has subagents (Claude Code, Codex, Muse Code, OpenCode, Gemini CLI, Cursor) | Spawn a background child with the packet's Prompt section, the pinned model and effort, and write access to its worktree. Its final message is the report; save it to `.heimdall/reports/`. |
| **Headless harness** | Executor is a different harness or vendor (tandem), or the user wants isolation | Run the harness's non-interactive command (section 3) with the packet file as input. Needs explicit user consent: it spends that vendor's quota and runs with that tool's permissions. |
| **Same session** | No subagents (pi without extensions) or a tiny packet | Checkpoint STATE.md, adopt the role, follow the packet exactly in the worktree, write the report, switch back. Cap 1 (execution-loop.md, section 10). |
| **User-driven** | Executor is a GUI tool (Cursor, Copilot in an IDE) or the user wants control | Emit numbered next steps (production-orchestrator.md, section 6). |

Rules for every method:

- Subagents and headless runs cannot ask the user questions (Claude Code subagents have no AskUserQuestion; `vibe --prompt` disables `ask_user_question`; Muse `--user-input-auto-resolve` cancels prompts). Gates therefore always run in the orchestrating session. Packets tell executors to stop and report when blocked.
- Never pass a permission-bypass flag (`--dangerously-skip-permissions`, `--dangerously-bypass-approvals-and-sandbox`, `--yolo`, `--auto`, `-s danger-full-access`, `--permission-mode bypassPermissions`) unless the user asks for it for that run.
- One worktree and branch per ticket (`heimdall/t<nn>-<slug>`), created by the orchestrator from the integration tip. A harness's own worktree isolation is acceptable only if it bases the worktree on the integration tip.
- Coders need network access only for dependency installs (for example Codex `-c sandbox_workspace_write.network_access=true` for the tickets that hold the `deps` hotspot). They never need tracker access or push rights.
- After a headless run, read the report file; if it is missing, read the command's final output and treat the run as an executor failure (execution-loop.md, section 8).

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

### Claude Code

- Subagents: the Agent tool, or `.claude/agents/<name>.md` with `model:` (`haiku|sonnet|opus|fable|<full id>|inherit`), `effort:` (`low`–`max`), `tools:`, `isolation: worktree`. Subagents cannot call AskUserQuestion.
- Headless (from the worktree): `claude -p "$(cat <main checkout>/.heimdall/packets/T<nn>-review-<r>.md)" --model <alias> --effort <level> --permission-mode acceptEdits --output-format json` (add `--allowedTools` to restrict). `-p` skips the workspace-trust dialog: use it only in trusted project directories.
- Model and effort in session: `/model`, `/effort`.
- Other vendors' models via `ANTHROPIC_BASE_URL` (DeepSeek, Kimi, GLM, MiniMax, Meta): the slot names (`opus`, `sonnet`, `haiku`) then map to that vendor's models — record the real model in STATE.md.

### Codex CLI

- Subagents: `spawn_agent` / `wait_agent` (`features.multi_agent`, on by default); roles in `.codex/agents/*.toml`; defaults `agents.default_subagent_model`, `agents.default_subagent_reasoning_effort`. GPT-6 "may delegate less often than desired" — say explicitly when to spawn.
- Headless: `codex exec -m <model> -c model_reasoning_effort="<level>" -s workspace-write -C <worktree> -o .heimdall/reports/T<nn>-coder-<r>.md "$(cat .heimdall/packets/T<nn>-coder-<r>.md)"` (run from the main checkout so the `-o` path lands in `.heimdall/`). `--json` streams JSONL; `--output-schema <file>` constrains the final message; `--ephemeral` keeps no session files.
- Sandbox `-s read-only|workspace-write|danger-full-access`; approvals `-a <policy>` (top-level `codex`).
- AGENTS.md over 32 KiB is silently truncated (`project_doc_max_bytes`).

### Muse Code

- Subagents: native (lead session spawns children; `/subagents`, `/tasks`); `--subagent-worktree-isolation` isolates only children that ask.
- Headless (from the worktree): `muse exec --prompt-file <main checkout>/.heimdall/packets/T<nn>-coder-<r>.md --model <id> --reasoning-effort <level> --trust-workspace --user-input-auto-resolve`; `--json` for events; `--output-schema <file>` (Meta provider only); `--max-model-steps <n>` caps runaway loops. Exit 0 = completed, 1 = failed or step cap, 2 = usage error. Keep the default approval mode and sandbox unless the user chooses otherwise.
- Install from a local path: `muse skills validate <path>` then `muse skills install <path> --scope user`. `muse skills list --source all` shows what loaded.
- Default model differs between docs (`muse-spark-1.2`) and the local catalog (`muse-wonder-1.0`): pin the model explicitly.

### OpenCode

- Subagents: `.opencode/agents/<name>.md` with `mode: subagent`, `model: provider/model`, `permission:` (e.g. `edit: allow`, `bash: ask`), `steps:`; run in child sessions via the `subagent` tool. Commands with `subtask: true` also spawn a subagent.
- Headless (from the worktree): `opencode run -m <provider/model> --agent <agent> -f <main checkout>/.heimdall/packets/T<nn>-coder-<r>.md "Execute the attached packet."` (`--format json` for events). `--auto` approves everything not explicitly denied — consent required.
- Muse via OpenCode loses reasoning across turns (`@ai-sdk/openai-compatible`); prefer Muse Code for Muse executors.

### pi

- No built-in subagents ("Pi ships with powerful defaults but skips features like sub-agents and plan mode"). Use same-session execution, or headless pi runs, or the community `pi-subagents` package (`pi install npm:pi-subagents`) if the user installs it.
- Headless: `pi -p "<prompt>" --model <provider/id> --thinking <off|minimal|low|medium|high|xhigh|max>`; `--mode json` for events; `--tools <allowlist>` to restrict tools; `--approve` trusts project-local files for one run.
- Install from Git: `pi install git:github.com/<owner>/<repo>` (private-repo auth UNVERIFIED — clone with `gh` and use `--skill <path>` or copy into `~/.agents/skills/` instead).

### Gemini CLI

- Subagents: `.gemini/agents/*.md` (`name`, `description`), invoked as `@name`; on by default.
- Install from Git: `gemini skills install https://github.com/<owner>/<repo>.git --path skills/heimdall --consent` (`--scope user|workspace`). Private-repo auth UNVERIFIED.
- Add `"context": {"fileName": ["AGENTS.md", "GEMINI.md"]}` so project AGENTS.md files load.
- Gemini CLI was replaced by Antigravity CLI for unpaid and Google One users on 2026-06-18.

### Antigravity CLI (`agy`)

- Headless: `agy -p "<prompt>" --model <id> --effort <low|medium|high|xhigh|max> --mode <accept-edits|plan|auto> --output-format json`. `--dangerously-skip-permissions` only on explicit request.
- Plugins: `agy plugin install <target>`, `agy plugin validate`. Skill directories UNVERIFIED — install into `~/.agents/skills/` and check with the CLI.

### Qwen Code

- Skills: `~/.qwen/skills/<name>/SKILL.md` (personal), `.qwen/skills/<name>/SKILL.md` (project). Reads `QWEN.md` and `AGENTS.md`.
- Extensions: `qwen extensions install <owner>/<repo>` (seen in third-party READMEs).
- Serve self-hosted Qwen with the right parsers and sampling (prompting-qwen.md) before dispatching.

### Mistral Vibe

- Headless `vibe --prompt …` auto-approves when `--agent` is omitted and disables `ask_user_question`. Always pass `--agent plan` (review packets) or `--agent accept-edits` (build packets).
- Never set a custom system prompt for Heimdall (it replaces Vibe's default); rely on AGENTS.md and the skill.

### Grok Build (beta)

- Reads `AGENTS.md` and Claude Code files with "zero configuration". Skills from `~/.grok/skills/`, `~/.agents/skills/`, `.grok/skills/` (project `.agents/skills/` not listed).
- Plugins: marketplace sources in `~/.grok/config.toml`, `--plugin-dir <path>`. Headless flags UNVERIFIED (Agent Client Protocol is the official programmatic route).

### Kimi Code CLI

- Skills: `~/.kimi-code/skills/`, `~/.agents/skills/`, `.kimi-code/skills/`, `.agents/skills/` (project wins). The old `kimi-cli` is archived.

### Cursor

- Skills from `.agents/skills/`, `.cursor/skills/`, and the Claude/Codex directories. Subagents in `.cursor/agents/` (`model`, `readonly`, `is_background`), invoked as `/name`.
- Coder packets are usually user-driven: open the ticket's worktree folder in Cursor. Turn auto model selection off for Standard and Frontier tickets (consistency).

### GitHub Copilot

- Skill locations "depend on the surface"; `.github/skills`, `.agents/skills`, `.claude/skills` (project), `~/.copilot/skills` or `~/.agents/skills` (user). Plugins: `copilot plugin marketplace add <owner>/<repo>`, `copilot plugin install <plugin>@<marketplace>`.

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
