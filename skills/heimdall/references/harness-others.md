# Harnesses — OpenCode, pi, Gemini CLI, Antigravity CLI, Qwen Code, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, GitHub Copilot

Per-harness adapters (harness-adapters.md, section 3). Verified 2026-10-25 against vendor docs (Context7 and official pages) and the locally installed CLIs OpenCode 2.1.4, pi 1.4.0, and Antigravity CLI 1.4.6; launch rules, OpenCode permissions, and the pi and agy grant flags re-checked 2026-10-26. Rows marked UNVERIFIED come from a third-party summary only. Read the section for each harness in the topology, at G2 and whenever a packet is dispatched to it.

Every headless command runs from the main checkout and enters the worktree in a subshell. Launch, wait, and capture follow harness-adapters.md, section 1: background with `exec` — `(cd <worktree> && exec <command> > <abs report> 2> <abs report base>.log) & echo $!` — record `$!` in STATE.md (In flight), and treat the run as finished only when that PID has exited; a report file that exists while the PID is alive is not a result. Reviewers run no scripts: the red-at-base result comes from the orchestrator's check report (`.heimdall/reports/T<nn>-checks-<round>.md`). Where a harness below has no per-command grants, the reviewer's shell is limited only by the packet; prefer a Claude Code or OpenCode reviewer when the topology has one.

## OpenCode

- Agents (v2 docs, opencode.ai/v2/docs/agents and /permissions, checked 2026-10-26 for OpenCode 2.1.4): `.opencode/agents/<name>.md` with `mode:` (`primary`, the default for a custom agent; `subagent`, only through the `subagent` tool; `all`, either), `model: provider/model`, and `permissions:` — an ordered list of `{action, resource, effect}` rules (`effect`: `allow`, `ask`, `deny`; wildcards in `action` and `resource`; the last matching rule wins, and agent rules are appended after the global ones). The v1 `permission:` map (`edit: allow`, `bash: ask`) is the old form. Subagents run in child sessions via the `subagent` tool; commands with `subtask: true` also spawn one.
- Reviewer agent (`mode: all`, so it serves both as a subagent and for `opencode run --agent`): deny everything first, then allow exactly the review commands. Use only `allow` and `deny` — what `ask` does in `opencode run` without `--auto` is UNVERIFIED.
  ```yaml
  permissions:
    - { action: "*", resource: "*", effect: deny }
    - { action: read, resource: "*", effect: allow }
    - { action: grep, resource: "*", effect: allow }
    - { action: glob, resource: "*", effect: allow }
    - { action: shell, resource: "git diff *", effect: allow }
    - { action: shell, resource: "git log *", effect: allow }
    - { action: shell, resource: "git show *", effect: allow }
    - { action: shell, resource: "git rev-parse *", effect: allow }
    - { action: shell, resource: "git status *", effect: allow }
    - { action: shell, resource: "<test command>", effect: allow }
    - { action: shell, resource: "<test command> *", effect: allow }
    - { action: shell, resource: "<type-check command>", effect: allow }
    - { action: shell, resource: "<type-check command> *", effect: allow }
  ```
  The `<…>` commands are the full prefixes from HANDOFF's Commands (`node --test`, `npm run typecheck`), never `node` or `npm`. Each gets a bare rule and a `*` rule, because whether `"x *"` also matches `x` with no arguments is UNVERIFIED. Reading `.heimdall/` in the main checkout from a worktree is outside the workspace: add an `external_directory` allow rule for the main checkout's path (behavior UNVERIFIED). A coder agent allows `edit` and `shell` and denies `{ action: shell, resource: "git push *" }`.
- Headless: `(cd <worktree> && exec opencode run -m <provider/model> --agent <agent> -f <abs packet> "Execute the attached packet." > <abs report> 2> <abs report base>.log) & echo $!`; stdout holds the response in text mode (capture UNVERIFIED on this machine); `--format json` emits events instead. `--auto` approves everything not explicitly denied — consent required.
- Muse via OpenCode loses reasoning across turns (`@ai-sdk/openai-compatible`); prefer Muse Code for Muse executors.

## pi

- No built-in subagents ("Pi ships with powerful defaults but skips features like sub-agents and plan mode"). Use same-session execution, headless pi runs, or the community `pi-subagents` package (`pi install npm:pi-subagents`) if the user installs it.
- Headless: `(cd <worktree> && exec pi -p "$(cat <abs packet>)" --model <provider/id> --thinking <off|minimal|low|medium|high|xhigh|max> > <abs report> 2> <abs report base>.log) & echo $!`; stdout holds the final message in text mode (capture UNVERIFIED on this machine); `--mode json` emits events instead; `--approve` trusts project-local files for one run.
- Grants: `--tools <allowlist>` enables tools by name (`read`, `bash`, `edit`, `write`; `pi --help`, 2026-10-26), so a reviewer gets `--tools read,bash` and no edit tool. There is no per-command grant inside `bash`.
- Install from Git: `pi install git:github.com/<owner>/<repo>` (private-repo auth UNVERIFIED — clone with `gh` and use `--skill <path>` or copy into `~/.agents/skills/` instead).

## Gemini CLI

- Subagents: `.gemini/agents/*.md` (`name`, `description`), invoked as `@name`; on by default.
- Install from Git: `gemini skills install https://github.com/<owner>/<repo>.git --path skills/heimdall --consent` (`--scope user|workspace`). Private-repo auth UNVERIFIED.
- Add `"context": {"fileName": ["AGENTS.md", "GEMINI.md"]}` so project AGENTS.md files load.
- Gemini CLI was replaced by Antigravity CLI for unpaid and Google One users on 2026-06-18.

## Antigravity CLI (`agy`)

- Headless: `(cd <worktree> && exec agy -p "$(cat <abs packet>)" --model <id> --effort <low|medium|high|xhigh|max> --mode <accept-edits|plan|auto> > <abs report> 2> <abs report base>.log) & echo $!`; text mode on stdout (capture UNVERIFIED on this machine); `--output-format json` emits structured output instead. `--dangerously-skip-permissions` only on explicit request.
- Grants: `--mode plan` for reviewers keeps them from editing (`agy --help`, 2026-10-26); whether plan mode may run the test suite, and any per-command grant, are UNVERIFIED.
- Plugins: `agy plugin install <target>`, `agy plugin validate`. Skill directories UNVERIFIED — install into `~/.agents/skills/` and check with the CLI.

## Qwen Code

- Skills: `~/.qwen/skills/<name>/SKILL.md` (personal), `.qwen/skills/<name>/SKILL.md` (project). Reads `QWEN.md` and `AGENTS.md`.
- Extensions: `qwen extensions install <owner>/<repo>` (seen in third-party READMEs).
- Serve self-hosted Qwen with the right parsers and sampling (prompting-qwen.md) before dispatching.

## Mistral Vibe

- Headless: `(cd <worktree> && exec vibe --prompt "$(cat <abs packet>)" --agent <agent> > <abs report> 2> <abs report base>.log) & echo $!` (capture UNVERIFIED on this machine). `vibe --prompt` auto-approves when `--agent` is omitted and disables `ask_user_question`. Always pass `--agent plan` (review packets) or `--agent accept-edits` (build packets).
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
