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
9. Concurrency, budget, checkpoints, resume
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
| Tickets | G3: one issue per ticket, in dependency order |
| Blocking edges | G3: native dependency links, or the `Blocked by` body fallback |
| Frontier query | every scheduler pass |
| Claim and status | every transition below |
| Pull requests | coder done |
| Review verdicts | reviewer done |
| Merge and close | merger done |
| Read | any time an agent needs a ticket, PR, or diff |

**Status labels** (exactly one per open ticket): `heimdall:ready` → `heimdall:in-progress` (claimed) → `heimdall:in-review` (PR open) → `heimdall:approved` or `heimdall:changes-requested` (back to in-progress for a fix round) → closed with the merge SHA. Any state may move to `heimdall:needs-human` (waiting on the user) and back to `heimdall:ready`. Kind labels: `heimdall:spec`, `heimdall:prefactor`.

**Merge path** (chosen at G2): `pr` (default with a remote tracker — one PR per ticket, merged through the tracker) or `local` (squash merges in the local repository; the tracker still tracks status; the integration branch is pushed at user-approved checkpoints). Use `local` when the user requires approval for each push or the remote has no pull requests.

## 3. Before the loop starts

1. G1–G3 locked. HANDOFF.md holds the module map, the seams, the commands, the hotspot plan, the execution topology, and the standing authorization (production-orchestrator.md, G2).
2. The integration branch exists and is checked out in the main checkout: the default branch for greenfield builds; `heimdall/<project-slug>` (from the default branch) for brownfield builds.
3. `.heimdall/` is listed in `.git/info/exclude`, so runtime files never enter a commit or a worktree (production-orchestrator.md, section 1).
4. The worktree root exists (default `../<repo>.worktrees`).
5. Tracker setup is done, every ticket is published with its edges, and STATE.md's ticket table maps each `T<nn>` to its tracker number.
6. Every dispatch method in the topology passed its hello-world check (assets/setup-packet.md).
7. After T01 merges, the full suite is green on the integration tip.

## 4. The scheduler

Run this loop until it exits. Each pass is cheap; run one whenever an agent finishes, and at least after every merge.

```
pass:
  sync      fast-forward the main checkout; read ticket statuses from the tracker; update STATE.md
  guard     integration tip red? -> dispatch nothing new; route the failure (section 8)
  collect   for each finished agent:
              coder DONE      -> validate (section 5), open PR, status in-review, dispatch reviewer
              coder BLOCKED   -> route (section 8)
              reviewer        -> post verdict; approved -> merge queue; changes -> fix round
              merger          -> close ticket, clean up, update STATE.md
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

## 5. Dispatching a coder

1. **Claim** the ticket (tracker: claim and status). Record the agent, the round, and the start time in STATE.md.
2. **Worktree:** `git worktree add -b heimdall/t<nn>-<slug> <worktree-root>/t<nn>-<slug> <integration-branch>`.
3. **Packet:** fill assets/coder-packet.md and save it as `.heimdall/packets/T<nn>-coder-<round>.md`: absolute paths to HANDOFF.md, the spec, and the ticket (or its issue number); the touch set with paths resolved from the module map; the seams; the commands; the family-specific lines from `prompting-<family>.md`. Score it against checklist-and-grading.md.
4. **Dispatch** by the method in the topology (harness-adapters.md): a background subagent working in the worktree, a headless CLI run with the worktree as its working directory, the same session, or the user's own tool. Coders need no tracker access and no push rights; they need network access only for dependency installs.
5. **Collect** the coder's final message — the return report (assets/return-report.md) — into `.heimdall/reports/T<nn>-coder-<round>.md` (the subagent's result, or the headless CLI's output file).
6. **Validate** before review:
   - Status is DONE, and the branch head SHA in the report matches `git rev-parse heimdall/t<nn>-<slug>`.
   - Scope: `git diff --name-only <integration-branch>...heimdall/t<nn>-<slug>` lists only paths inside the touch set and their tests. Anything else goes back to the coder as `BLOCKED: touch-set`.
   - The report has the red-first evidence table (tdd-protocol.md, section 6).
7. **Open the PR** (merge path `pr`): `git push -u origin heimdall/t<nn>-<slug>`, then the tracker's PR operation with a body from assets/pr-body.md (`Closes #<n>` when the integration branch is the default branch, `Refs #<n>` otherwise). Status → in-review.

## 6. Review

1. Fill assets/review-packet.md and save it as `.heimdall/packets/T<nn>-review-<round>.md`: the ticket, the spec, the HANDOFF sections (seams, standards, module map), the base and head SHAs, the diff command `git diff <base-sha>...<head-sha>`, the commit list, and the coder's report.
2. Dispatch the reviewer in a fresh context (agent-roles.md picks the family). It reads and runs tests; it never edits code or pushes.
3. Collect the review report (assets/review-report.md) into `.heimdall/reports/T<nn>-review-<round>.md`, post it with the tracker's verdict operation, and set the status.
4. **Verdict rule:** APPROVE only when no blocking finding remains on any axis. Axes are reported separately and never merged or reranked: Spec, Standards (repo standards plus the smell baseline), TDD audit, Security, Scope.
5. **Fix round:** status in-progress; dispatch the coder again in the same worktree with a round-N packet that points at the review report. The coder fixes every blocking finding (non-blocking smells too when cheap), may refactor under green tests, re-syncs, and reports. The next review covers `git diff <last-reviewed-sha>..<new-head>` plus the open findings.
6. **Round cap:** two fix rounds per ticket (Production may set three). Beyond the cap, route it as an executor failure (section 8).

## 7. Merge

Follow merge-protocol.md, L6, one ticket at a time, in approval order. The orchestrator performs clean merges itself with the tracker's merge operation; that needs no code reading. When the pre-check reports conflicts, or the update step needs mechanical resolution, dispatch a merger agent with assets/merge-packet.md. After the merge: close the ticket with the merge SHA, clean up the worktree and branch, fast-forward the main checkout, update STATE.md, and run a scheduler pass — a merge usually widens the frontier.

## 8. Failure routing and health

| Signal | Route |
|---|---|
| `BLOCKED: touch-set` | If the extra module or hotspot is free, widen the touch set (ticket body and STATE.md) and resume the same worktree. Otherwise split the work into a new ticket with the right blocking edge, and park this one. |
| `BLOCKED: seam` | Approve it when it sits inside an approved module boundary (record it in HANDOFF.md); otherwise `needs-human`. |
| `BLOCKED: spec` | Answer from HANDOFF.md or the spec if the answer is settled; otherwise `needs-human`. A requirement change goes to the change-request flow (production-orchestrator.md, section 7). |
| `BLOCKED: environment` | Dedicated environment-fix ticket, scheduled first; `needs-human` if it needs the user's machine, accounts, or secrets. |
| `BLOCKED: dependency` | A blocking edge was missing. Add it, set the ticket to ready; the frontier rule holds it back. |
| Secret, credential, destructive or outward action | `needs-human`. Never worked around. |
| Executor failure (bad output, claimed-but-false completion, timeout, runaway) | Retry with a regenerated packet, then a tier bump, then a different family. Retries do not count as review rounds. |
| Review round cap exceeded | As executor failure; if the ticket is too large for one context, split it (replan that slice). |
| Semantic merge conflict | changes-requested for the later ticket with the failing output (merge-protocol.md, L7). |
| Integration tip red | Stop dispatching; fix-forward ticket first, or revert the merge (a new commit). |
| Architecture problem (module map or seam wrong) | Stop dispatching to the affected modules; revision loop to G2 or G3 with the user. |

**needs-human batching:** collect questions across tickets and ask them together when the user is present (at most 4 per message, multiple choice, each with one recommended answer and its reason). In an unattended run, keep working on the rest of the frontier; when nothing else can move, stop and report.

**Health rule:** if 2 of the last 4 merged tickets needed retries, a tier bump, or the full fix-round cap, pause dispatching and hold a health check: ticket size, seam quality, tier and family fit, packet quality. Record the cause tally in STATE.md.

## 9. Concurrency, budget, checkpoints, resume

- **Cap** on in-flight coders: default 3. Lower it for a tight budget, low vendor rate limits, or a narrow frontier; raise it (up to 5) only with a generous budget and a wide frontier. Reviewers do not count toward the cap. Merges are always serial.
- **Fresh context per ticket.** Each coder and reviewer starts clean. A fix round may continue the same coder session when the harness supports it (for example by messaging a finished subagent); otherwise a new session reads the pointers.
- **Checkpoint** STATE.md after every status change. With a tight budget, start a fresh orchestrator session every few merges and resume.
- **Progress report:** refresh it when a wave of tickets has merged and whenever the loop stops for the user (production-orchestrator.md, section 6).
- **Resume:** read STATE.md, then reconcile with the tracker (tracker wins). For each `in-progress` ticket with no live agent: if its worktree has commits, dispatch a coder to continue in that worktree; if not, remove the worktree and set the ticket back to ready. For each `in-review` ticket without a verdict, dispatch a reviewer. For each `approved` ticket, queue the merge.

## 10. Fallbacks

- **No subagents and no headless CLI** (for example pi without extensions): run sequentially in the same session with a cap of 1. Adopt the coder role in the worktree, finish the report, then adopt the reviewer role and review only from the pointers, as if someone else wrote the code. Same-model self-review is weaker: prefer a headless reviewer from another family, or a fresh session, when either is available.
- **Chat profile** (no file or shell tools): Build mode runs G0–G3 in chat (spec, architecture, ticket drafts as copy-ready files), then hands the loop to a coding-agent harness with Heimdall installed through a kickoff message: "Install Heimdall, put these files in `.heimdall/`, and run the build loop." Review reports come back by paste.
- **No remote tracker:** tracker-local.md with merge path `local`.
