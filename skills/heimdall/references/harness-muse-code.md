# Harness — Muse Code

Per-harness adapter (harness-adapters.md, section 3). Verified 2026-10-25 against Muse Code 1.4.13 (`muse --help`, `muse exec --help`) and dev.meta.ai; approval and permission flags re-checked 2026-10-26 (`muse exec --help`). Read when the topology uses Muse Code, at G2 and whenever a packet is dispatched to it.

## Subagents

- Native: the lead session spawns children (`/subagents`, `/tasks`). `--subagent-worktree-isolation` isolates only children that ask; Heimdall's own worktrees are used instead.

## Headless runs

Run every command from the main checkout. Launch, wait, and capture follow harness-adapters.md, section 1: background with `exec`, record `$!` in STATE.md (In flight), and treat the run as finished only when that PID has exited.

- **Coder, reviewer, merger:** `(cd <worktree> && exec muse exec --prompt-file <abs packet> --model <id> --reasoning-effort <level> --trust-workspace --user-input-auto-resolve > <abs report> 2> <abs report base>.log) & echo $!`.
  - stdout holds the final message in text mode (capture UNVERIFIED on this machine); `--json` emits events instead; `--output-schema <file>` works with the Meta provider only.
  - `--max-model-steps <n>` caps runaway loops. Exit 0 = completed, 1 = failed or step cap, 2 = usage error.
  - Keep the default approval mode and sandbox unless the user chooses otherwise (`muse exec --help`, 2026-10-26: approval and the sandbox are on by default; `--approval-mode untrusted|on-request|never`). The reviewer packet forbids edits and scripts. `--permission-profile <ID>` selects a named permission profile, but its contents and any per-command allow-list are UNVERIFIED, so prefer a Claude Code or OpenCode reviewer when the topology has one.

## Install and models

- Install from a local path: `muse skills validate <path>`, then `muse skills install <path> --scope user`. `muse skills list --source all` shows what loaded.
- The default model differs between the docs (`muse-spark-1.2`) and the local catalog (`muse-wonder-1.0`): pin the model explicitly.
