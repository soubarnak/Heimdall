# KICKOFF — <project-slug> — hand the build loop to a coding agent

<!-- Chat profile only (references/execution-loop.md, section 10; references/production-orchestrator.md, section 5).
     Emitted in full after G3, together with the final copies of every file listed under "Save these files".
     The user pastes the message into a coding-agent harness that has Heimdall installed. -->

## Save these files

In the project folder, exactly at these paths (`.heimdall/` is runtime state, listed in `.git/info/exclude`, never committed). The fastest way is the setup script below, which writes every file; or save each file by hand.

| File | Content |
|---|---|
| `.heimdall/STATE.md` | the STATE.md above (gates G1–G3 locked; Current: "G3 confirmed, publish pending") |
| `.heimdall/spec.md` | spec v<N> |
| `.heimdall/HANDOFF.md` | HANDOFF v<N> |
| `.heimdall/briefings/G1.md`, `.heimdall/briefings/G2.md` | the briefings |
| `.heimdall/research/<topic>.md` | <one row per digest, or "none"> |
| `.heimdall/design/option-<x>.html`, `.heimdall/design/prototype/*.html` | <UI builds: the chosen mockup and the prototype screens, or "n/a"> |
| `.heimdall/tickets/T<nn>-<slug>.md` | <one row per ticket> |
| `docs/adr/NNNN-<slug>.md` | <one row per ADR> — committed by the bootstrap commit |
| `AGENTS.md` (and `CLAUDE.md` containing `@AGENTS.md`) | the bootstrap file — committed by the bootstrap commit |

### Setup script

<!-- Orchestrator: emit one script that writes every file in the table, each through a quoted heredoc with its own
     unique delimiter (the quotes stop the shell from expanding `$` and backticks inside the content). Choose
     delimiters that never occur in the content, for example HEIMDALL_EOF_01, HEIMDALL_EOF_02, … -->

```bash
#!/usr/bin/env bash
# heimdall-setup.sh — run once in the project folder: bash heimdall-setup.sh
set -euo pipefail
[ -d .git ] || git init -b main
mkdir -p .heimdall/briefings .heimdall/research .heimdall/tickets .heimdall/design/prototype docs/adr
grep -qxF '.heimdall/' .git/info/exclude 2>/dev/null || echo '.heimdall/' >> .git/info/exclude

cat > .heimdall/STATE.md <<'HEIMDALL_EOF_01'
<the full STATE.md>
HEIMDALL_EOF_01

cat > .heimdall/spec.md <<'HEIMDALL_EOF_02'
<the full spec.md>
HEIMDALL_EOF_02

<… one block per file in the table …>

echo "Heimdall files written. Start the coding agent in this folder."
```

## Install Heimdall in the coding agent

```bash
d="$HOME/.local/share/heimdall"
if [ -d "$d/.git" ]; then git -C "$d" pull --ff-only; else git clone --depth 1 https://github.com/soubarnak/Heimdall.git "$d"; fi
"$d/scripts/install.sh" --harness <claude | codex | muse | opencode | pi | gemini | …>
```

Start a new session in the project folder afterwards (skills load at session start). Sign in to the tracker first: <`gh auth login` | `tea login add` | nothing for the local tracker>.

## First message to the coding agent

```
Use Heimdall. Resume the build in this project: .heimdall/STATE.md is at "G3 confirmed, publish pending".
Tracker: <GitHub owner/repo | Gitea host/owner/repo | local>. Integration branch: <name>. Merge path: <pr | local>.
I confirmed the ticket graph in chat: do the G3 publish steps now without asking again — tracker setup, the spec issue, the tickets with their edges, the ticket-checks copy, the bootstrap commit, then push the integration branch (merge path pr).
Then run the build loop. Stop and report at: every needs-human item, the health rule, the demo checkpoint, and the end of each wave. Refresh the progress report at each stop.
Standing authorization as recorded in HANDOFF.md, Settled Decisions. Nothing else outward without asking me.
```

## What to bring back here

Paste the updated `.heimdall/STATE.md` and `.heimdall/PROGRESS.md` whenever you want a check-in, a change request, or the G6 and G7 gates run in this chat. Never paste code or diffs; paste reports.
