# Execution Loop — Build Mode G4–G5

The autonomous part of Build mode: after G3 locks the ticket graph, the orchestrator schedules coders, reviewers, and merges until every ticket is closed. Read with agent-roles.md (who does what), merge-protocol.md (why parallel work does not collide), tdd-protocol.md (how coders build), and the tracker file chosen at G2.

## Contents

1. Invariants
2. Tracker contract
3. Before the loop starts
4. The scheduler
5. Dispatching a coder
6. Review
7. Merge
8. Failure routing and health
9. Concurrency, budget, checkpoints, demo, resume
10. Fallbacks

## 1. Invariants

- **One scheduler.** The orchestrator is the only agent that claims tickets, changes ticket status, and dispatches agents.
- **One ticket = one coder = one worktree = one branch = one PR.**
- **The reviewer is never the coder.** Fresh context always; a different model family when available (required in Production mode when the topology has one).
- **One merge at a time**, by the merger role (merge-protocol.md, L6).
- **Context pointers, not copies.** Packets point to the spec, the ticket, HANDOFF sections, reports, and commits by absolute path, issue number, or SHA. Inline content only when the executor cannot read outside its worktree.
- **The tracker is the shared record; STATE.md mirrors it** (the ticket table) so a resumed session can reconcile. On disagreement the tracker wins.
- **The orchestrator stays lean.** It reads reports, verdicts, tracker state, and pre-check output — never whole diffs.

## 2. Tracker contract

Every tracker implements the same operations. Choose the tracker at G2 from `git remote get-url origin`: `github.com` or a GitHub Enterprise host → tracker-github.md; a host with a matching `tea login` (Gitea, and Forgejo with a check of the dependencies endpoint) → tracker-gitea.md; no remote, or the user prefers files → tracker-local.md. The user confirms the choice at G2.

| Operation | When |
|---|---|
| Preflight | G2: authentication, issues enabled, dependency support |
| Setup | G3: labels, milestones |
| Spec issue | G3: publish the locked spec |
| Progress and snapshot comments | from G3: create once on the spec issue, then edit in place (production-orchestrator.md, sections 5 and 6) |
| Tickets | G3: one issue per ticket, in dependency order |
| Blocking edges | G3: native dependency links, or the `Blocked by` body fallback |
| Frontier query | every scheduler pass |
| Claim and status | every transition below |
| Pull requests | coder done |
| Review verdicts | reviewer done |
| Merge and close | merger done |
| Read | any time an agent needs a ticket, PR, or diff |

**Status labels** (exactly one per open ticket): `heimdall:ready` → `heimdall:in-progress` (claimed) → `heimdall:in-review` (report validated; on merge path `pr`, the PR is open) → `heimdall:approved` or `heimdall:changes-requested` (back to in-progress for a fix round) → closed with the merge SHA. Any state may move to `heimdall:needs-human` (waiting on the user) and back to `heimdall:ready`. Kind labels: `heimdall:spec`, `heimdall:prefactor`, `heimdall:acceptance`.

**Status transitions** — the single source; every transition is made by the orchestrator. Remote trackers use `gh issue edit <n> --remove-label heimdall:<from> --add-label heimdall:<to>` or `tea issues edit <n> --remove-labels heimdall:<from> --add-labels heimdall:<to>`; the local tracker edits the `Status:` line.

| From → to | Trigger |
|---|---|
| ready → in-progress | the scheduler claims the ticket (section 5, step 1) |
| in-progress → in-review | the coder's report validated; on merge path `pr`, the branch pushed and the PR open (section 5, step 7) — both merge paths |
| in-review → approved | `VERDICT: APPROVE` |
| in-review → changes-requested | `VERDICT: CHANGES_REQUESTED` |
| changes-requested → in-progress | the fix-round coder is dispatched (section 6, step 5) |
| approved → closed | merged; the closing comment carries the merge SHA (merge-protocol.md, L6) |
| approved → changes-requested | a semantic conflict at merge, or a red integration tip that was reverted (merge-protocol.md, L6–L7): a merge-repair round (section 2, Names) whose "review to address" is the merge report |
| any open state → needs-human | a question only the user can answer (section 8); the worktree is kept |
| needs-human → ready | the user answered; the ticket re-enters the frontier and reuses its worktree |
| in-progress → ready | parked: a touch-set split, or an executor failure before any commit (the worktree is removed) |

**Names.** `<slug>` is the ticket title in kebab-case, at most 40 characters, fixed at G3 in the ticket's `Branch:` line and never changed. `<round>` starts at 1 and increments when the ticket is sent back for a fix round: a `CHANGES_REQUESTED` verdict, a semantic conflict at merge, or a reverted merge. Only rounds caused by a `CHANGES_REQUESTED` verdict count toward the round cap (section 6); merge-repair rounds (a semantic conflict, a reverted merge) are caused by another ticket's change, so they are tallied in STATE.md Health instead. A retry after an executor failure keeps the round number, overwrites that round's packet, and increments the retry count in STATE.md.

**Merge path** (chosen at G2): `pr` (default with a remote tracker — one PR per ticket, merged through the tracker) or `local` (squash merges in the local repository; the tracker still tracks status; the integration branch is pushed at user-approved checkpoints). Use `local` when the user requires approval for each push or the remote has no pull requests.

## 3. Before the loop starts

1. G1–G3 locked. HANDOFF.md holds the module map, the seams, the commands, the hotspot plan, the execution topology, and the standing authorization (production-orchestrator.md, G2).
2. The integration branch exists and is checked out in the main checkout: the default branch for greenfield builds; `heimdall/<project-slug>` (from the default branch) for brownfield builds. In a new repository (or an empty remote, where the tracker preflight shows no default branch) the bootstrap commit creates it.
3. `.heimdall/` is listed in `.git/info/exclude`, so runtime files never enter a commit or a worktree (production-orchestrator.md, section 1).
4. The worktree root exists (default `../<repo>.worktrees`), and so do `.heimdall/tickets/`, `.heimdall/packets/`, and `.heimdall/reports/`. `.heimdall/ticket-checks.sh` is a copy of `scripts/ticket-checks.sh` from the folder that holds this skill's SKILL.md (refresh the copy on resume when it is missing or the Heimdall version changed; production-orchestrator.md, section 5).
5. Tracker setup is done, every ticket is published with its edges, and STATE.md's ticket table maps each `T<nn>` to its tracker number.
6. **The integration branch is on the remote** when a remote exists: `git push -u origin <integration-branch>` after the bootstrap commit (merge path `pr`: required, and covered by the standing authorization; merge path `local`: only at a checkpoint the user approves). Without this, no PR can be opened against it and the remote never sees the ADRs and AGENTS.md.
7. Every dispatch method in the topology passed its hello-world check (assets/setup-packet.md; in a repository that had no commits before G3, run it now, after the bootstrap commit).
8. After T01 merges, the full suite is green on the integration tip.

## 4. The scheduler

Run this loop until it exits. Each pass is cheap; run one whenever an agent finishes, and at least after every merge.

```
pass:
  sync      fast-forward the main checkout; read ticket statuses from the tracker; update STATE.md
  guard     integration tip red? -> dispatch nothing new; route the failure (section 8)
  collect   for each finished agent:
              coder DONE      -> ticket checks (section 5); push and open or update the PR; status in-review;
                                 dispatch reviewer
              coder BLOCKED   -> route (section 8)
              coder FAILED    -> executor failure (section 8)
              reviewer        -> post verdict; approved -> merge queue; changes -> fix round;
                                 STALE -> regenerate the review packet at the current head, re-dispatch
              merger          -> close ticket, clean up, update STATE.md
  wave      a wave merged -> progress report, state snapshot; first complete journey -> demo checkpoint (section 9)
  merge     merge queue non-empty and no merge running -> merge the oldest approved ticket (section 7)
  frontier  open tickets with status ready, every blocker closed, touch set disjoint from every
            in-flight touch set, and no hotspot held by an in-flight ticket
  order     longest chain of dependents first (critical path), then prefactor, then High risk, then lowest T<nn>
  dispatch  while in-flight coders < cap and frontier not empty: claim and dispatch the next ticket
  exit      nothing in flight, nothing queued:
              all tickets closed     -> leave the loop; go to G6
              tickets remain blocked -> stop; report each blocked ticket and what it needs
  checkpoint STATE.md
```

**Locks and the cap.** A ticket holds its touch set and hotspots from the claim until it is closed or parked back to ready; a ticket in review or in the merge queue still holds them. The cap counts coders that are running (dispatched, report not yet collected); tickets in review or queued for merge do not count. Reviewers never count.

## 5. Dispatching a coder

1. **Claim** the ticket (tracker: claim and status). Record the agent, the round, and the start time in STATE.md.
2. **Worktree:** `git worktree add -b heimdall/t<nn>-<slug> <worktree-root>/t<nn>-<slug> <integration-branch>`. If the branch or the worktree already exists (a fix round, a retry, a resumed session, a ticket back from needs-human), reuse it as it is; if the branch exists but its directory is gone, `git worktree add <worktree-root>/t<nn>-<slug> heimdall/t<nn>-<slug>` (no `-b`). If it exists but has no commits beyond its base (`git log <integration-branch>..heimdall/t<nn>-<slug>` is empty) after a failed attempt, remove both (`git worktree remove --force <path>`, `git branch -D heimdall/t<nn>-<slug>`) and recreate. A fresh worktree has no installed dependencies: the coder packet's first step is HANDOFF's Install command.
3. **Packet:** fill assets/coder-packet.md and save it as `.heimdall/packets/T<nn>-coder-<round>.md`: absolute paths to HANDOFF.md, the spec, and the ticket (or its issue number); the touch set with paths resolved from the module map; the seams; the commands; the family-specific lines from `prompting-<family>.md`. Score it against checklist-and-grading.md.
4. **Dispatch** by the method in the topology (harness-adapters.md): a background subagent working in the worktree, a headless CLI run with the worktree as its working directory, the same session, or the user's own tool. Record in STATE.md In flight how to find the agent again: the subagent id, or the PID of a background headless run. Coders need no tracker access and no push rights; they need network access only for dependency installs.
5. **Collect** the coder's final message — the return report (assets/return-report.md) — into `.heimdall/reports/T<nn>-coder-<round>.md` (the subagent's result, the headless CLI's captured output per harness-adapters.md, or, in same-session mode, written by the orchestrator itself). A missing or malformed report is an executor failure (section 8).
6. **Ticket checks** before review. The report's status is DONE and it has the red-first evidence table (tdd-protocol.md, section 6); then run the mechanical checks from the main checkout — the orchestrator never judges these by reading logs:
   ```bash
   bash .heimdall/ticket-checks.sh --ticket T<nn> --worktree <worktree> --branch heimdall/t<nn>-<slug> \
     --integration <integration-branch> --base <synced-with> --head <head from the report> \
     --touch '<path glob>' … --tests '<test path glob>' … --lockfile '<lockfile path>' … \
     --install '<Install command>' --test-cmd '<one-test-file command>' \
     --red <required | skip> [--red-reason '<why>'] [--order skip] [--need-tests no] \
     --out .heimdall/reports/T<nn>-checks-<round>.md
   ```
   The touch globs are the ticket's modules plus its hotspots, resolved to paths with HANDOFF's module map and hotspot table. `--lockfile` lists the `deps` hotspot's lockfile paths on every run: a ticket that holds `deps` has them in its touch globs already, so only other tickets get `LOCKFILE-DRIFT`. `--install` and `--test-cmd` are needed only with `--red required`. `--red required` for `feature` and `bug` tickets in MVP and Production; `--red skip` with a reason for Prototype mode, `TDD: n/a` tickets, `env` tickets, `acceptance` tickets (the test is the deliverable and passes at the head), and prefactor tickets that only add characterization tests. `--order skip` for `TDD: n/a` tickets, `acceptance` tickets, and when Prototype mode relaxed test-first. `--need-tests no` only for `TDD: n/a` and `env` tickets; every other ticket, acceptance tickets included, gets `NO-TESTS` when its diff changes no test file. The first line of the output file is `CHECKS: PASS` or `CHECKS: FAIL: <codes>`; route it:
   - `HEAD-MISMATCH`, `DIRTY-TREE`, `BASE-NOT-SYNCED` → re-dispatch with the note "commit everything, sync with the integration tip, and report again".
   - `OUT-OF-SCOPE` → re-dispatch with the note "revert the changes outside the touch set, or report `BLOCKED: touch-set` with the reason". The orchestrator never edits the branch.
   - `LOCKFILE-DRIFT` (a lockfile changed while the ticket does not hold `deps`) → re-dispatch with the note "restore the lockfile with the command in the checks report; your Install command must not rewrite it".
   - `COMMIT-ORDER`, `NO-RED`, `NO-TESTS` → continue to step 7; the reviewer weighs them in the TDD audit.
   - `SETUP-ERROR` → fix the cause (the network, the Install command) and run the checks once more; still failing → continue to step 7 with the checks report as it stands (red-at-base `SETUP-ERROR`) and add it to Health (Check setup errors).
   - **Re-dispatch** (a failed check): same round, same worktree; the packet's "Orchestrator note" carries the instruction; the retry count in STATE.md increments; the previous packet, report, and checks report are overwritten.
7. **Push and open the PR** (merge path `pr`): round 1: `git push -u origin heimdall/t<nn>-<slug>`, then the tracker's PR operation with a body from assets/pr-body.md (`Closes #<n>` when the integration branch is the default branch, `Refs #<n>` otherwise). Round 2 and later: `git push origin heimdall/t<nn>-<slug>` only; the PR follows the branch. Record the pushed head in STATE.md (`Head` column). Status → in-review on both merge paths.

## 6. Review

1. Fill assets/review-packet.md and save it as `.heimdall/packets/T<nn>-review-<round>.md`: the ticket, the spec, the HANDOFF sections (seams, standards, module map), the base SHA (the report's `Synced with`) and the head SHA, the diff command `git diff <base-sha>...<head-sha>`, the commit list `git log --reverse --no-merges --format='%h %s' <base-sha>..<head-sha>`, the coder's report, and the checks report. Because the base is the integration tip the coder last merged, the diff holds only this ticket's changes.
2. Dispatch the reviewer in a fresh context (agent-roles.md picks the family). It reads and runs tests; it never edits code or pushes.
3. Collect the review report (assets/review-report.md) into `.heimdall/reports/T<nn>-review-<round>.md`, post it with the tracker's verdict operation, and set the status.
4. **Verdict rule:** APPROVE only when no blocking finding remains on any axis. Axes are reported separately and never merged or reranked: Spec, Standards (repo standards plus the smell baseline), TDD audit, Security, Scope.
5. **Fix round:** status in-progress; dispatch the coder again in the same worktree with a round-N packet that points at the review report. The coder fixes every blocking finding (non-blocking smells too when cheap), may refactor under green tests, re-syncs, and reports. Collect, validate, and push exactly as in section 5 (steps 5–7); then review again. The next packet carries the new base and head (the full ticket diff, `git diff <new synced-with>...<new-head>`), the fix commits `git log --reverse --first-parent --no-merges --format='%h %s' <last-reviewed-sha>..<new-head>` (first-parent, so other tickets' squash commits pulled in by the re-sync do not appear), and the open findings; the reviewer checks the open findings first and the rest of the diff for regressions.
6. **Round cap:** two `CHANGES_REQUESTED` rounds per ticket (Production may set three); count the `VERDICT: CHANGES_REQUESTED` reports in `.heimdall/reports/T<nn>-review-*.md`. Merge-repair rounds do not count (section 2, Names). Beyond the cap, route it as an executor failure (section 8).

## 7. Merge

Follow merge-protocol.md, L6, one ticket at a time, in approval order. The orchestrator performs clean merges itself with the tracker's merge operation; that needs no code reading. When the pre-check reports conflicts, or the update step needs mechanical resolution, dispatch a merger agent with assets/merge-packet.md (its report is saved as `.heimdall/reports/T<nn>-merge.md`). After the merge, in the L6 order: fast-forward the main checkout and record the merge SHA, verify the tip, close the ticket with the SHA, clean up the worktree and branch, update STATE.md, and run a scheduler pass — a merge usually widens the frontier.

## 8. Failure routing and health

| Signal | Route |
|---|---|
| `BLOCKED: touch-set` | If the extra module or hotspot is free, widen the touch set — the ticket draft file, the issue body (`gh issue edit <n> --body-file …` / `tea issues edit <n> --description-file …`), and STATE.md — and resume the same worktree with the next packet. Otherwise split the work into a new ticket with the right blocking edge, and park this one (status ready; worktree kept if it has commits). |
| `BLOCKED: seam` | Approve it when it sits inside an approved module boundary (record it in HANDOFF.md); otherwise `needs-human`. |
| `BLOCKED: spec` | Answer from HANDOFF.md or the spec if the answer is settled; otherwise `needs-human`. A requirement change goes to the change-request flow (production-orchestrator.md, section 7). **Acceptance failure** (an `acceptance` ticket's report says `acceptance failure: SC-<n>` with the failing output): the build does not meet a Success Criterion it should already meet — a conformance bug, not a requirement change. Open a `bug` ticket against the implementing module with the failing output as its reproduction, add the edge "acceptance ticket blocked by the bug ticket", and set the acceptance ticket back to ready (worktree and branch kept). When the test itself misreads the criterion, re-dispatch the acceptance coder with the correction instead; when unsure which, `needs-human`. |
| `BLOCKED: environment` | Dedicated environment-fix ticket, scheduled first; `needs-human` if it needs the user's machine, accounts, or secrets. |
| `BLOCKED: dependency` | A blocking edge was missing. Add it, set the ticket to ready; the frontier rule holds it back. |
| `BLOCKED: secret`, `BLOCKED: destructive` (a credential, a destructive or outward action) | `needs-human`. Never worked around. |
| `STATUS: FAILED`, or no usable report | Executor failure (next row). |
| `VERDICT: STALE` | The head moved after the review packet was written: regenerate the packet at the current head and re-dispatch the reviewer. Not a review round. |
| Executor failure (bad output, claimed-but-false completion, timeout, runaway) | A ladder of at most three attempts after the first: retry once with a regenerated packet, then once with a tier bump, then once with a different family (when the topology has one); after that, `needs-human` with the three reports. Retries do not count as review rounds. |
| Review round cap exceeded | As executor failure; if the ticket is too large for one context, split it (replan that slice). |
| Semantic merge conflict | The later ticket goes approved → changes-requested: a merge-repair round (round + 1, not counted toward the cap, tallied in Health) in its worktree whose "review to address" is `.heimdall/reports/T<nn>-merge.md` (the failing output and the conflicting ticket), per merge-protocol.md, L7. |
| Integration tip red after a merge | Stop dispatching. Either **fix-forward**: finish L6 step 7 for the merged ticket (it closes with its SHA) and schedule a `bug` ticket first; or **revert**: `git revert <sha>` on the integration branch, pushed under the standing authorization, the ticket goes approved → changes-requested with a merge-repair round whose "review to address" is the failing output, its branch and worktree still exist (step 7 did not run), the next validated head gets a new PR (the old one is merged), and the Coverage table shows its stories as not built (merge-protocol.md, L6, step 6). |
| Architecture problem (module map or seam wrong) | Stop dispatching to the affected modules; revision loop to G2 or G3 with the user. |

**needs-human batching:** collect questions across tickets and ask them together when the user is present (at most 4 per message, multiple choice, each with one recommended answer and its reason). In an unattended run, keep working on the rest of the frontier; when nothing else can move, stop and report.

**Health rule:** if 2 of the last 4 merged tickets needed retries, a tier bump, or the full fix-round cap, pause dispatching and hold a health check: ticket size, seam quality, tier and family fit, packet quality. Record the cause tally in STATE.md. Merge-repair rounds and check setup errors are tallied too; two merge repairs in one wave point at a missing edge or hotspot (merge-protocol.md, L7).

## 9. Concurrency, budget, checkpoints, demo, resume

- **Cap** on in-flight coders: default 3. Lower it for a tight budget, low vendor rate limits, or a narrow frontier; raise it (up to 5) only with a generous budget and a wide frontier. Reviewers do not count toward the cap. Merges are always serial.
- **Fresh context per ticket.** Each coder and reviewer starts clean. A fix round may continue the same coder session when the harness supports it (for example by messaging a finished subagent); otherwise a new session reads the pointers.
- **Checkpoint** STATE.md after every status change. With a tight budget, start a fresh orchestrator session every few merges and resume.
- **Progress report and snapshot:** refresh the report when a wave of tickets has merged and whenever the loop stops for the user; update the state snapshot comment after each merged wave (production-orchestrator.md, sections 5 and 6).
- **Demo checkpoint:** after the wave that completes the first user journey (HANDOFF's Coverage table: every ticket in the Tickets column of its stories merged; acceptance tickets are not needed), start the application from the integration tip with HANDOFF's Dev command — in the background, or hand the command to the user; never block the scheduler on a long-running process — and stop for the user once: the URL or command, and a 3-step journey to try. The progress report gains its "Try it" section. Feedback enters as a fix ticket (a bug) or a change request (anything new); the loop continues with the rest of the frontier meanwhile.
- **Resume:** read STATE.md, then reconcile with the tracker (tracker wins). For each `in-progress` ticket, check its agent first:
  - **Live:** a subagent of this session, or a headless run whose recorded PID still answers `kill -0 <pid>` → keep waiting. Subagents never survive their session, so after a new session only a headless PID can be live.
  - **Dirty worktree** (`git -C <worktree> status --porcelain` not empty) and no live agent → dispatch a coder to continue in that worktree (same round, retry count +1) with the orchestrator note "uncommitted changes from an interrupted run: review them, keep what is right, commit, continue". Never remove a dirty worktree.
  - **Commits beyond the base** and a clean tree → dispatch a coder to continue in that worktree (same round, retry count +1).
  - **Nothing** (a clean tree without commits) → remove the worktree and branch and set the ticket back to ready.
- **Resume, other statuses:** for each `changes-requested` ticket with no fix round dispatched, dispatch it. For each `in-review` ticket without a verdict, dispatch a reviewer at the current head. For each `approved` ticket, queue the merge after the SHA guard (merge-protocol.md, L6). For a ticket whose PR is already merged (remote: `gh pr view --json state` / `tea api … pulls/<pr#>`) but which is still open, run L6 steps 5–7; on merge path `local`, the same when `git log --format=%s <integration-branch>` already contains `(T<nn>)` for an open ticket.

## 10. Fallbacks

- **No subagents and no headless CLI** (for example pi without extensions): run sequentially in the same session with a cap of 1. Checkpoint STATE.md, adopt the coder role in the worktree, and follow the packet exactly; the orchestrator itself writes the return report to `.heimdall/reports/T<nn>-coder-<round>.md` (the packet's "final message" rule means "the report ends the coder step"), checkpoints STATE.md again, then adopts the reviewer role and reviews only from the packet's pointers, as if someone else wrote the code. Same-model self-review is weaker: prefer a headless reviewer from another family, or a fresh session, when either is available.
- **Chat profile** (no file or shell tools): Build mode runs G0–G3 in chat (spec, architecture, ticket drafts as copy-ready files), then hands the loop to a coding-agent harness with Heimdall installed through the kickoff message (assets/kickoff.md): which files to save where, the install line, and the first instruction. Review reports and progress reports come back by paste.
- **No remote tracker:** tracker-local.md with merge path `local`.
- **Light-tier orchestrator** (production-orchestrator.md, section 3): cap 1; compensation on every packet; reviewer Standard or above; a health check after any retry, tier bump, or full fix round; stop at anything that needs a revision loop or a change request.
