# Harness — Codex CLI

Per-harness adapter (harness-adapters.md, section 3). Verified 2026-10-26 against Codex CLI 0.163.0 (`codex exec --help`) and the Codex config reference on developers.openai.com. Model switching and implicit invocation re-checked 2026-11-07 against Codex CLI 0.166.0 (`codex exec --help`: `-m, --model`, `--json`, `-o`). Read when the topology uses Codex, at G2 and whenever a packet is dispatched to it.

## Subagents

- `spawn_agent` / `wait_agent` (`features.multi_agent`, on by default); roles in `.codex/agents/*.toml`; defaults `agents.default_subagent_model`, `agents.default_subagent_reasoning_effort`.
- GPT-6 "may delegate less often than desired": say explicitly when to spawn.

## Headless runs

Run every command from the main checkout; `-C` sets the working directory, so no subshell is needed. Launch, wait, and capture follow harness-adapters.md, section 1: background each run, record `$!` in STATE.md (In flight), and treat the run as finished only when that PID has exited.

- **Coder:** `codex exec -m <model> -c model_reasoning_effort="<level>" -s workspace-write -c 'sandbox_workspace_write.writable_roots=["<main checkout>/.git"]' -C <worktree> -o <abs report> "$(cat <abs packet>)" > <abs report base>.log 2>&1 & echo $!`.
  - The `writable_roots` entry lets the coder commit from a linked worktree; without it `git commit` fails inside the sandbox, because a linked worktree commits into the main checkout's `.git`.
  - Add `-c sandbox_workspace_write.network_access=true` only when the ticket installs dependencies (it holds the `deps` hotspot, or the Install command needs the network).
- **Reviewer:** `codex exec -m <model> -c model_reasoning_effort="<level>" -s workspace-write -C <worktree> -o <abs report> "$(cat <abs packet>)" > <abs report base>.log 2>&1 & echo $!` — `workspace-write` so test runners can write their caches in the worktree; no extra writable root, because a reviewer commits nothing. `codex exec` has no per-command allow-list flag (`codex exec --help`, 2026-10-26); execpolicy `.rules` files exist (`--ignore-rules` skips them) but are user or project files that apply to every run, so the reviewer's limit is the sandbox — no network, writes only in the worktree — and the packet's rule against scripts. Prefer a Claude Code or OpenCode reviewer when the topology has one and the review must be held to named commands. The red-at-base result comes from the orchestrator's check report.
- **Merger:** as the coder.
- `-o` writes the final message to the report path (when the file appears during the run is UNVERIFIED; read it only after the PID has exited). `--json` streams JSONL; `--output-schema <file>` constrains the final message; `--ephemeral` keeps no session files.
- Sandbox `-s read-only|workspace-write|danger-full-access`; approvals `-a <policy>` (top-level `codex`).

## Model detection and switching

- **Detection:** the `model` key in `~/.codex/config.toml` is the configured default. Read that one key, never the whole file and never the auth file. A `/model` choice in the session overrides it. Whether the `--json` events name the model is UNVERIFIED, so until it is confirmed the report's `Coder:` line is the self-report, and Heimdall asks the user to confirm the model when the plan needs it (model-plan.md, section 1).
- **Switch:** the user runs `/model` in the session. No host tool that sets the Codex session model is verified, so Heimdall gives the command and waits for "continue Heimdall" (model-plan.md, section 3). Headless runs take `-m <model>` and `-c model_reasoning_effort="<level>"` on every command.
- **Subagents:** pin each spawned subagent's model and effort. The `agents.default_subagent_model` and `agents.default_subagent_reasoning_effort` keys are a fallback only; the spawn call's model parameter is UNVERIFIED.
- **Implicit invocation:** `agents/openai.yaml` in the skill folder sets `policy:` `allow_implicit_invocation: false` (checked 2026-11-07, Codex CLI 0.166.0). Explicit `$heimdall` still works.

## Notes

- AGENTS.md over 32 KiB is silently truncated (`project_doc_max_bytes`).
