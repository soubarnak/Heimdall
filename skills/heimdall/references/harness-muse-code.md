# Harness — Muse Code

Per-harness adapter (harness-adapters.md, section 3). Verified 2026-10-25 against Muse Code 1.4.13 (`muse --help`, `muse exec --help`) and dev.meta.ai. Read when the topology uses Muse Code, at G2 and whenever a packet is dispatched to it.

## Subagents

- Native: the lead session spawns children (`/subagents`, `/tasks`). `--subagent-worktree-isolation` isolates only children that ask; Heimdall's own worktrees are used instead.

## Headless runs

Run every command from the main checkout. Record the PID of each background run in STATE.md (In flight).

- **Coder, reviewer, merger:** `(cd <worktree> && muse exec --prompt-file <abs packet> --model <id> --reasoning-effort <level> --trust-workspace --user-input-auto-resolve > <abs report>)`.
  - stdout holds the final message in text mode (capture UNVERIFIED on this machine); `--json` emits events instead; `--output-schema <file>` works with the Meta provider only.
  - `--max-model-steps <n>` caps runaway loops. Exit 0 = completed, 1 = failed or step cap, 2 = usage error.
  - Keep the default approval mode and sandbox unless the user chooses otherwise. The reviewer packet forbids edits; a per-command allow-list for `muse exec` is UNVERIFIED, so prefer a Claude Code or Codex reviewer when the topology has one.

## Install and models

- Install from a local path: `muse skills validate <path>`, then `muse skills install <path> --scope user`. `muse skills list --source all` shows what loaded.
- The default model differs between the docs (`muse-spark-1.2`) and the local catalog (`muse-wonder-1.0`): pin the model explicitly.
