# Harnesses — OpenCode, pi, Gemini CLI, Antigravity CLI, Qwen Code, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, GitHub Copilot

Per-harness adapters (harness-adapters.md, section 3). Verified 2026-10-25 against vendor docs (Context7 and official pages) and the locally installed CLIs OpenCode 2.1.4, pi 1.4.0, and Antigravity CLI 1.4.6. Rows marked UNVERIFIED come from a third-party summary only. Read the section for each harness in the topology, at G2 and whenever a packet is dispatched to it.

Every headless command runs from the main checkout and enters the worktree in a subshell. Record the PID of each background run in STATE.md (In flight). Reviewers run no scripts: the red-at-base result comes from the orchestrator's check report (`.heimdall/reports/T<nn>-checks-<round>.md`).

## OpenCode

- Subagents: `.opencode/agents/<name>.md` with `mode: subagent`, `model: provider/model`, `permission:` (e.g. `edit: allow`, `bash: ask`), `steps:`; run in child sessions via the `subagent` tool. Commands with `subtask: true` also spawn a subagent.
- Headless: `(cd <worktree> && opencode run -m <provider/model> --agent <agent> -f <abs packet> "Execute the attached packet." > <abs report>)`; stdout holds the response in text mode (capture UNVERIFIED on this machine); `--format json` emits events instead. `--auto` approves everything not explicitly denied — consent required. A reviewer agent sets `edit: deny`.
- Muse via OpenCode loses reasoning across turns (`@ai-sdk/openai-compatible`); prefer Muse Code for Muse executors.

## pi

- No built-in subagents ("Pi ships with powerful defaults but skips features like sub-agents and plan mode"). Use same-session execution, headless pi runs, or the community `pi-subagents` package (`pi install npm:pi-subagents`) if the user installs it.
- Headless: `(cd <worktree> && pi -p "$(cat <abs packet>)" --model <provider/id> --thinking <off|minimal|low|medium|high|xhigh|max> > <abs report>)`; stdout holds the final message in text mode (capture UNVERIFIED on this machine); `--mode json` emits events instead; `--tools <allowlist>` restricts tools (a reviewer gets no edit tool); `--approve` trusts project-local files for one run.
- Install from Git: `pi install git:github.com/<owner>/<repo>` (private-repo auth UNVERIFIED — clone with `gh` and use `--skill <path>` or copy into `~/.agents/skills/` instead).

## Gemini CLI

- Subagents: `.gemini/agents/*.md` (`name`, `description`), invoked as `@name`; on by default.
- Install from Git: `gemini skills install https://github.com/<owner>/<repo>.git --path skills/heimdall --consent` (`--scope user|workspace`). Private-repo auth UNVERIFIED.
- Add `"context": {"fileName": ["AGENTS.md", "GEMINI.md"]}` so project AGENTS.md files load.
- Gemini CLI was replaced by Antigravity CLI for unpaid and Google One users on 2026-06-18.

## Antigravity CLI (`agy`)

- Headless: `(cd <worktree> && agy -p "$(cat <abs packet>)" --model <id> --effort <low|medium|high|xhigh|max> --mode <accept-edits|plan|auto> > <abs report>)`; text mode on stdout (capture UNVERIFIED on this machine); `--output-format json` emits structured output instead. `--dangerously-skip-permissions` only on explicit request.
- Plugins: `agy plugin install <target>`, `agy plugin validate`. Skill directories UNVERIFIED — install into `~/.agents/skills/` and check with the CLI.

## Qwen Code

- Skills: `~/.qwen/skills/<name>/SKILL.md` (personal), `.qwen/skills/<name>/SKILL.md` (project). Reads `QWEN.md` and `AGENTS.md`.
- Extensions: `qwen extensions install <owner>/<repo>` (seen in third-party READMEs).
- Serve self-hosted Qwen with the right parsers and sampling (prompting-qwen.md) before dispatching.

## Mistral Vibe

- Headless: `(cd <worktree> && vibe --prompt "$(cat <abs packet>)" --agent <agent> > <abs report>)` (capture UNVERIFIED on this machine). `vibe --prompt` auto-approves when `--agent` is omitted and disables `ask_user_question`. Always pass `--agent plan` (review packets) or `--agent accept-edits` (build packets).
- Never set a custom system prompt for Heimdall (it replaces Vibe's default); rely on AGENTS.md and the skill.

## Grok Build (beta)

- Reads `AGENTS.md` and Claude Code files with "zero configuration". Skills from `~/.grok/skills/`, `~/.agents/skills/`, `.grok/skills/` (project `.agents/skills/` not listed).
- Plugins: marketplace sources in `~/.grok/config.toml`, `--plugin-dir <path>`. Headless flags UNVERIFIED (Agent Client Protocol is the official programmatic route).

## Kimi Code CLI

- Skills: `~/.kimi-code/skills/`, `~/.agents/skills/`, `.kimi-code/skills/`, `.agents/skills/` (project wins). The old `kimi-cli` is archived.

## Cursor

- Skills from `.agents/skills/`, `.cursor/skills/`, and the Claude and Codex directories. Subagents in `.cursor/agents/` (`model`, `readonly`, `is_background`), invoked as `/name`; a reviewer subagent sets `readonly`.
- Coder packets are usually user-driven: open the ticket's worktree folder in Cursor. Turn auto model selection off for Standard and Frontier tickets (consistency).

## GitHub Copilot

- Skill locations "depend on the surface": `.github/skills`, `.agents/skills`, `.claude/skills` (project), `~/.copilot/skills` or `~/.agents/skills` (user). Plugins: `copilot plugin marketplace add <owner>/<repo>`, `copilot plugin install <plugin>@<marketplace>`.
