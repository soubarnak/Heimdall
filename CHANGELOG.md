# Changelog

## 1.4.0 — 2026-10-30

Heimdall now asks the user which agent serves each purpose before it dispatches any, instead of choosing them by rule. Before this release the first dispatches (discovery researchers at G0, the scout at G0.5) went to agents the user never saw, and the topology appeared only at G2.

- The agent roster (calibration.md, section 5): in Build mode, including Build-lite, calibration always sends one message with a table of purposes: researcher, scout, coder for Light, Standard, and Frontier tickets, reviewer, merger, and QA agent. Each row has a recommended agent (harness, model, effort), the dispatch method it implies, and the alternatives detection found. The user answers up to three grouped questions (research, coding, review) plus the budget; "Just proceed" takes the recommended rows. Purposes already fixed by the user's instruction files are shown as decided, not asked. The orchestrator stays the session the user invoked.
- Consent for another vendor's harness is given by choosing that agent in the roster; the row says it spends that vendor's quota and runs with that tool's permissions. G2 shows the roster for the record, and a change there needs the user's answer.
- Only the user changes the roster. The executor-failure ladder's tier bump and family switch use only agents in the roster; a step that needs another agent becomes a `needs-human` question. The health check never swaps agents. On resume, a chosen agent that is missing becomes a question.
- STATE.md's Topology line and HANDOFF's execution topology now hold the full roster (researcher, scout, coders per tier, reviewer, merger, QA). On resume, an older STATE.md is migrated as usual, and the purposes it records no agent for (scout, merger, QA) are asked.
- Prompt mode is unchanged: Stage 8 still recommends a model for prompts run elsewhere.

## 1.3.1 — 2026-10-26

Fixes from a second live Light-tier run (Haiku orchestrator, headless Sonnet coder and reviewer, ticket T02 on the local path). The ticket merged, but the orchestrator started a duplicate coder, the reviewer searched the disk for a skill file, and STATE.md kept a stale integration tip. The launch and grant rules now apply to every harness, not only Claude Code.

- Headless launch and completion (harness-adapters.md, section 1, cited by every harness file): runs start in the background with `exec`, so `$!` is the harness process, and the PID goes into STATE.md In flight at once. A run has finished only when its PID has exited (`kill -0` fails); a report file that exists while the PID is alive is not a result. The PID comes from `echo $!`, never a `ps` search. Never a second run for the same ticket and role while the recorded PID is alive. stderr (Codex: stdout and stderr) goes to `<main checkout>/.heimdall/reports/T<nn>-<role>-<r>.log`, always an absolute path, since the command runs inside the worktree. In Claude Code a background run outlives the shell call that started it; elsewhere that is UNVERIFIED, with `nohup` as the fallback. The old Claude Code template piped JSON into the report at launch, which created an empty report while the run was still working; it now writes `<report base>.json` and extracts `.result` after exit, keeping the cost and refused commands for Health.
- Resume: a run that finished while the orchestrator was away is collected first; a live PID is confirmed with `ps -p <pid> -o args=`, because PIDs are reused after a reboot. The hello-world check launches headless runs exactly as the loop will.
- Reviewer grants: the full command prefixes from HANDOFF Commands (`node --test`, `npm run typecheck`), never a bare interpreter or package manager (`node`, `npm`, `python`), which would run any code. Per harness: Claude Code `--allowedTools`; OpenCode's v2 `permissions` list (deny all, then allow the review commands; the v1 `permission:` map is the old form); pi `--tools read,bash` (no per-command grant); agy `--mode plan` (test runs UNVERIFIED); Codex has no per-command allow-list for `codex exec`, so the sandbox is the limit; Muse `--permission-profile` contents UNVERIFIED. Prefer a Claude Code or OpenCode reviewer when the review must be held to named commands.
- Packets: pointers are absolute paths to project files; a rule from the skill is pasted into the packet, never cited by file name (checklist item 5), because a headless executor may not have the skill.
- Merge: L6 step 5 sets STATE.md `Integration: <branch> @ <merge sha>`.
- STATE.md migration compares the ticket table's header row with the template column by column. Each progress refresh also updates STATE.md's `Progress report:` line.

## 1.3.0 — 2026-10-26

Review release: a live Light-tier run (Haiku orchestrator, Sonnet coder, Opus reviewer, one ticket on the local path) and a full review of the skill found 8 fixes, 9 gaps, and 8 improvements. All are addressed.

- Ticket checks as a script: `scripts/ticket-checks.sh` (bash, git, and coreutils only) is copied to `.heimdall/ticket-checks.sh` at G3 and run by the orchestrator before every review. It checks the head, a clean tree, the base sync, the touch set, lockfile drift, the commit order, and red-at-base, and writes `.heimdall/reports/T<nn>-checks-<round>.md` with a `CHECKS: PASS | FAIL: <codes>` first line. Each code has one route (execution-loop.md, section 5, step 6). A diff without a test file is `NO-TESTS` whether or not red-at-base runs (`--need-tests no` only for `TDD: n/a` and env tickets); renamed files count as added and removed. Reviewers read the report and run no scripts, so their allow-lists drop the script grant; the per-packet `T<nn>-red-at-base.sh` is gone.
- Red-at-base: runs on every feature and bug ticket in MVP and Production ("spot-check" is gone) and is skipped in Prototype mode and for `TDD: n/a`, env, acceptance, and characterization-only prefactor tickets. A test that fails because a module the ticket creates does not exist yet counts as red; tests that pass on the base code are reported as `NO-RED` instead of passing silently.
- Round cap (reverses the 1.2.0 "third pass" rule): only `CHANGES_REQUESTED` rounds count toward the cap of 2. Rounds caused by a semantic merge conflict or a reverted merge are merge-repair rounds; they still increment the round number and are tallied in Health. A ticket should not exhaust its review budget because another ticket's merge broke it.
- Resume: calibration runs its detection steps on resume, so the Light-tier rule applies to the model actually running (it previously skipped detection and kept the recorded orchestrator); a numbered 7-step resume protocol; STATE.md migration includes the orchestrator line; liveness checks for running agents (subagent id or headless PID in STATE.md, `kill -0`); a dirty worktree with no live agent is continued by a coder, never removed.
- CI: an empty check-run list (GitHub) or `total_count` 0 (Gitea) means CI has not started, never green; no run within 10 minutes is a `needs-human` item; GitHub check runs are read across every page (`--paginate`).
- Greenfield: G0 runs `git init -b main` in an empty folder; calibration checks that a git identity exists (the user sets it, repository-local); with no remote, G2 offers a new private repository (`gh repo create --private --source=. --remote=origin`, `tea repos create --private`), never pushing at creation. Creating a GitHub repository from a local repository without commits is UNVERIFIED; the tracker file gives the fallback.
- Progress report: posted from G3 on (the spec issue exists from G3) as one comment edited in place by id, never `--edit-last`; the HTML version is written only at G2.5, G7, and on request; the "waiting on you" count equals the listed items; a "Try it" section after the demo checkpoint.
- State snapshot: STATE.md and HANDOFF.md are posted as one comment on the spec issue (two above 65,536 characters), edited in place, so a new machine can rebuild `.heimdall/`. Local tracker users are told to back up `.heimdall/`.
- Acceptance tests: G3 adds one `acceptance` ticket per Success Criterion (label `heimdall:acceptance`), an end-to-end test blocked by the implementing tickets; Success Criteria are numbered `SC-<n>`; the HANDOFF Coverage table maps stories and criteria to tickets and acceptance tickets; G6 runs them first. A failing acceptance test is a conformance bug: it opens a `bug` ticket that blocks the acceptance ticket, never a change request.
- Demo checkpoint: after the first complete user journey, the application is started in the background (or the command handed over) with a 3-step journey to try; feedback enters as a fix ticket or a change request, and the loop continues.
- G6 and G7: G6 has an exit rule (at most 2 QA re-runs, then the user decides) and an HTTP or CLI fallback without a browser; G7 uses a new release packet (`assets/release-packet.md`: preflight, configuration by name, ordered release steps each with its own go-ahead, smoke test, rollback, monitoring, release report), run by the orchestrator itself.
- Change requests: an "Applying an amend" checklist (spec version, ADR, tickets, HANDOFF, STATE, progress).
- Lockfiles: the Install command is a frozen install (`npm ci`, `pnpm install --frozen-lockfile`, …); coders restore unintended lockfile changes with `git restore --source=<base>`; the check flags drift outside the `deps` hotspot.
- Chat kickoff: STATE.md is handed over at "G3 confirmed, publish pending" and the coding agent publishes without asking again; one setup script with quoted heredocs writes every file.
- G2.5 option (b) is a design packet, not a ticket (tickets do not exist before G3).
- Recommended-defaults fast path at G1 and G2: artifacts first, then one question ("accept every recommendation as shown"), with technical defaults under "Advanced".
- Ticket bodies are built with an `awk` line that also drops the template comment.
- Instruction files: user and project instruction files that fix models or routing override Heimdall's defaults; calibration records it.
- Structure: `references/loop-card.md` (the G4–G5 loop on one page); harness-adapters.md split into harness-claude-code.md, harness-codex.md, harness-muse-code.md, and harness-others.md, so the loop loads only the harnesses in use; the smell list and the standing authorization each have one source (agent-roles.md; production-orchestrator.md, section 8), and packets get the smell list pasted in, since headless agents cannot read the skill.
- validate.sh: every asset (any extension) and skill script must be listed in SKILL.md; references, assets, and scripts stay one level deep; dangling `assets/` and `scripts/` paths of any extension are flagged; CHANGELOG.md must have an entry for the current version.

## 1.2.0 — 2026-10-26

Audit release: a fresh-context review of the build loop and a live G0–G3 dry run found gaps that stopped a ticket from completing on GitHub or Gitea, and several places where the orchestrator had to invent a command, a path, or a rule. All are closed.

- Build loop: the integration branch is pushed after the bootstrap commit (merge path `pr`); every coder round pushes the ticket branch (round 1 also opens the PR); the review base is the report's `Synced with` SHA and is validated with `git merge-base`; the merger records a guarded head (approved, or the update-merge head) and matches on it; the merge SHA comes from the integration tip after the merge; branches are deleted after the worktree, never with `--delete-branch` or `tea pulls clean`; `STATUS: FAILED` and `VERDICT: STALE` have routes; one status-transition table; slug and round defined; lock release and the cap defined; worktrees are reused on retries and resumes; `.heimdall/packets/` is created at setup; touch-set violations go back as a fix round; widened touch sets are written to the issue body; draft PRs removed.
- Headless dispatch: every adapter states the working directory and how the report is captured; Claude Code coders get an `--allowedTools` grant (`acceptEdits` alone denies shell commands in `-p` mode — verified); Codex coders get `sandbox_workspace_write.writable_roots` for the main checkout's `.git`.
- TDD: the red-at-base check installs dependencies in the scratch tree and skips deleted files.
- Gates: a mandatory gate locks only on a sign-off given after its artifacts were shown; blanket instructions do not pre-authorize it, and there is no "provisional" lock. The bootstrap commit happens only after the G3 confirmation.
- Templates: HANDOFF gains a hotspot-to-paths table and a Coverage table (user story → tickets), the single source for G3 validation and the progress report; tickets gain `Covers:` and `Screen:`; coder and review packets carry the prototype screen; STATE.md tracks the guarded head and retries. New templates: `qa-packet.md` (G6 whole-build review and QA run), `research-packet.md` (researcher and scout), `kickoff.md` (chat to coding-agent handoff), `agents-md.md` (the bootstrap AGENTS.md).
- Light-tier orchestration: a Light model may now run the build loop of a planned build (cap 1, compensation on every packet, a Standard or better reviewer, a health check after any retry) and Build-lite on an explicit "orchestrate anyway" (grade capped at C); the planning gates and G6–G7 still need Standard or above.
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
