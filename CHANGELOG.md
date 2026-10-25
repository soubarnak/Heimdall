# Changelog

## 1.2.0 — 2026-10-26

Audit release: a fresh-context review of the build loop and a live G0–G3 dry run found gaps that stopped a ticket from completing on GitHub or Gitea, and several places where the orchestrator had to invent a command, a path, or a rule. All are closed.

- Build loop: the integration branch is pushed after the bootstrap commit (merge path `pr`); every coder round pushes the ticket branch (round 1 also opens the PR); the review base is the report's `Synced with` SHA and is validated with `git merge-base`; the merger records a guarded head (approved, or the update-merge head) and matches on it; the merge SHA comes from the integration tip after the merge; branches are deleted after the worktree, never with `--delete-branch` or `tea pulls clean`; `STATUS: FAILED` and `VERDICT: STALE` have routes; one status-transition table; slug and round defined; lock release and the cap defined; worktrees are reused on retries and resumes; `.heimdall/packets/` is created at setup; touch-set violations go back as a fix round; widened touch sets are written to the issue body; draft PRs removed.
- Headless dispatch: every adapter states the working directory and how the report is captured; Claude Code coders get an `--allowedTools` grant (`acceptEdits` alone denies shell commands in `-p` mode — verified); Codex coders get `sandbox_workspace_write.writable_roots` for the main checkout's `.git`.
- TDD: the red-at-base check installs dependencies in the scratch tree and skips deleted files.
- Gates: a mandatory gate locks only on a sign-off given after its artifacts were shown; blanket instructions do not pre-authorize it, and there is no "provisional" lock. The bootstrap commit happens only after the G3 confirmation.
- Templates: HANDOFF gains a hotspot-to-paths table and a Coverage table (user story → tickets), the single source for G3 validation and the progress report; tickets gain `Covers:` and `Screen:`; coder and review packets carry the prototype screen; STATE.md tracks the guarded head and retries. New templates: `qa-packet.md` (G6 whole-build review and QA run), `research-packet.md` (researcher and scout), `kickoff.md` (chat to coding-agent handoff), `agents-md.md` (the bootstrap AGENTS.md).
- Grading: accepting a recommendation after seeing the options is an informed decision (A-eligible); "you pick" without options is delegation (C cap); "Just proceed" turns open preference questions into listed assumptions.
- Second review round: remote ticket bodies are built with one `sed` line (no H1, no local status lines, `Part of #` first); merge path `local` with a remote tracker has its own verdict and close commands; the red-at-base check is a script the orchestrator writes and the reviewer runs as one allow-listed command; Claude Code runs get `--add-dir` and a narrow git allow-list (no `git push`); Codex reviewers get the scratch worktree as a writable root; coders install dependencies before the first test; round 2 commit lists use `--first-parent`; a semantic conflict or a reverted merge sends the ticket approved → changes-requested with the merge report as the fix input; the trivial-adjacency re-review is gone; the executor-failure ladder has three attempts; CI red is read from the tip commit's combined status; resume covers undispatched fix rounds and merged-but-open tickets; STATE.md written by an older version is migrated on resume; progress reports are regenerated in full. Third pass: fix rounds from merge failures count toward the round cap; GitHub CI is read from check runs (the combined status ignores Actions) with a 30-minute limit; the revert route pushes the revert and opens a new PR; review-packet commands run in the worktree, matching the reviewer's allow-list; the merger merges with `--no-commit` and may `git checkout --theirs`; the hello-world check exercises the real grants (read `.heimdall/`, commit in a scratch worktree, run a packet script).

## 1.1.1 — 2026-10-26

- Every question Heimdall asks the user now carries exactly one recommended answer, listed first and marked "(Recommended)" with a one-line reason. The rule lives in workflow-stages.md, Stage 6, and covers interviews, the calibration question, gate questions, the G2.5 design pick, the G3 confirmation, change requests, and batched `needs-human` items. Advisor decision blocks end with a per-decision recommendation.
- "Just proceed" takes the recommended answers for every open question and records them as assumptions.

## 1.1.0 — 2026-10-26

- Visual progress report: `.heimdall/PROGRESS.md` (Mermaid diagrams for GitHub and Gitea) and `.heimdall/progress.html` (one offline page). It shows the gate flow, what works so far, the build graph by wave, the chosen design with its mockups and prototype screens, what was done, and the proposed next phase. Refreshed at every gate lock, after each merged wave, when the loop stops for the user, and on "Show progress"; posted as a comment on the spec issue. New templates `assets/progress-report.md` and `assets/progress-report.html`.
- Reports are styled with the IBM Carbon Design System: Mermaid in the white theme with Carbon tag colors for status; the HTML page in the white theme and g100 in dark mode.
- G2.5 now ends with a prototype: after the user picks a mockup, the chosen direction is extended to the core screens (MVP) or the core screens with empty, loading, and error states (Production), and the user confirms it. UI tickets name the prototype screen they implement.
- Calibration detects a headless Chromium or Chrome for design screenshots.
- README: a usage guide.
- INSTALL.md: the verify loop no longer exits with status 1 when the last target is absent.

### Repository (since 1.0.0)

- Repository made public.
- README opens with install instructions for agents: a harness table, one universal install command, native alternatives, and a PowerShell path for Windows.
- INSTALL.md rewritten around the universal method; private-repository steps removed.
- README shows the Build mode flow as an SVG diagram (`docs/assets/build-flow.svg`).

## 1.0.0 — 2026-10-25

First release as an Agent Skill.

- Converted the claude.ai Project knowledge bundle into one installable skill, `skills/heimdall`, with an entry point, 27 references, and 17 asset templates.
- Build mode now runs the whole flow from an idea or an SRS: intake with discovery research, spec, architecture with ADRs, ticket graph, multi-agent build loop, QA, and ship.
- Added a ticket tracker contract with implementations for GitHub (`gh`), Gitea (`tea`), and local files.
- Added the seven-layer merge-conflict prevention protocol: touch sets, hotspot locks, scaffold ticket, worktree per coder, fresh base before review, serial merger with a merge pre-check and full-suite verification.
- Added the test-first protocol (adapted from mattpocock/skills, MIT) with red-first evidence and reviewer audits.
- Added roles for researcher, scout, coder, reviewer, merger, and QA agents, with status tokens and example topologies.
- Added proactive project research, Architecture Decision Records, and user briefings (decide, do, learn).
- Made the skill harness- and model-agnostic: calibration by detection, harness adapters for 13 harnesses, prompting guides for 11 model families, and a tier-to-model map.
- Added `scripts/install.sh`, `scripts/validate.sh`, Claude Code plugin and marketplace manifests, and INSTALL.md for agent-driven installation.
