# Tracker — GitHub (`gh`)

Implements the tracker contract in execution-loop.md, section 2. Verified 2026-10-26 against `gh` 2.103.1 and the GitHub REST API. Run every command inside the project clone so `gh` infers the repository. Never print or store tokens; authentication is the user's `gh auth login`.

## Preflight (G2, once)

```bash
gh auth status                       # must show a logged-in account with repo scope
gh repo view --json nameWithOwner,defaultBranchRef,hasIssuesEnabled
```

If issues are disabled, ask the user to enable them or choose the local tracker. A repository with no commits yet shows an empty `defaultBranchRef`: the bootstrap commit at G3 creates the first branch.

No remote yet (greenfield, calibration.md, section 4): offer a new private repository and create it only on the user's yes:

```bash
gh repo create <name> --private --source=. --remote=origin   # no --push: the bootstrap commit is pushed at G3
```

Creating from a local repository that has no commits yet: UNVERIFIED (flags checked against `gh repo create --help` 2.103.1; not run). If it fails, create the repository without `--source` (`gh repo create <name> --private`) and add the remote with `git remote add origin <url>`.

## Setup (G3, once per build)

```bash
for l in "heimdall:spec|5319E7" "heimdall:ready|0E8A16" "heimdall:in-progress|FBCA04" \
         "heimdall:in-review|1D76DB" "heimdall:changes-requested|D93F0B" \
         "heimdall:approved|0E8A16" "heimdall:needs-human|B60205" "heimdall:prefactor|C5DEF5" \
         "heimdall:acceptance|BFD4F2"; do
  gh label create "${l%%|*}" --color "${l##*|}" --force
done
gh api repos/{owner}/{repo}/milestones -f title="<milestone title>" -f description="<goal>"
```

`--force` updates a label that already exists. If the repo already uses Matt Pocock's triage labels (`docs/agents/triage-labels.md`), also apply its `ready-for-agent` string next to `heimdall:ready`.

## Spec issue

```bash
gh issue create --title "Spec: <project>" --label heimdall:spec --body-file .heimdall/spec.md
```

Progress report and state snapshot (production-orchestrator.md, sections 5 and 6), from G3 on: each is one comment, created once and then edited in place. Record each comment id in STATE.md (Tracker comments). The first line of each file is its marker — `<!-- heimdall:progress -->` or `<!-- heimdall:snapshot -->` — so a new machine can find the comments.

```bash
gh api repos/{owner}/{repo}/issues/<spec#>/comments -F body=@.heimdall/PROGRESS.md --jq .id    # create once: prints the id
gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id> -F body=@.heimdall/PROGRESS.md        # every later refresh
```

The same two commands post `.heimdall/snapshot.md` (or its two parts when it is split). Never use `gh issue comment --edit-last`: it edits whichever comment was last, which may be a claim or a verdict.

Rebuild on a machine without `.heimdall/` (production-orchestrator.md, section 5):

```bash
gh issue list --state all --label heimdall:spec --json number,title
gh api repos/{owner}/{repo}/issues/<spec#>/comments --paginate --jq '.[] | select(.body | startswith("<!-- heimdall:snapshot")) | {id, body}'
```

## Tickets

Create tickets in dependency order (blockers first) so edges can reference real numbers:

```bash
# the issue body: the draft without its template comment, its H1, and its local status lines; "Part of #<spec>" is then the first line
awk 'NR==1 && /^<!--/ {skip=1} skip { if (/-->/) skip=0; next } !h && /^# / {h=1; next} /^(Status|Claimed by|Merged):/ {next} {print}' \
  .heimdall/tickets/T<nn>-<slug>.md | sed '/./,$!d' > .heimdall/tickets/T<nn>-<slug>.body.md
gh issue create --title "<ticket title>" --label heimdall:ready [--label heimdall:prefactor | --label heimdall:acceptance] \
  --milestone "<milestone title>" --parent <spec#> --body-file .heimdall/tickets/T<nn>-<slug>.body.md
```

`--parent` makes it a sub-issue of the spec. If sub-issues are unavailable, put `Part of #<spec>` on the first line of the body.

## Blocking edges

GitHub's native issue dependencies take the blocker's **database id**, not its number:

```bash
BID=$(gh api repos/{owner}/{repo}/issues/<blocker#> --jq .id)
gh api --method POST repos/{owner}/{repo}/issues/<ticket#>/dependencies/blocked_by -F issue_id="$BID"
```

Fallback when dependencies are unavailable: keep the `## Blocked by` section in the ticket body (`- #12`, `- #14`). Record which representation is in use in STATE.md.

## Frontier query

```bash
gh issue list --state open --label heimdall:ready --json number,title,labels,milestone --limit 200
gh api repos/{owner}/{repo}/issues/<n> --jq .issue_dependencies_summary.blocked_by   # 0 = unblocked
```

A ticket is on the frontier when it is open, labelled `heimdall:ready`, has zero open blockers, and its touch set does not overlap an in-flight ticket (merge-protocol.md).

## Claim and status

All agents usually run under the user's single account, so assignees cannot tell agents apart. Use labels plus a claim comment:

```bash
gh issue edit <n> --remove-label heimdall:ready --add-label heimdall:in-progress
gh issue comment <n> --body "Claimed by <role>-<agent-id> on branch heimdall/t<nn>-<slug>."
```

Every other transition in execution-loop.md, section 2, uses the same shape: `gh issue edit <n> --remove-label heimdall:<from> --add-label heimdall:<to>`. A widened touch set is written back by rebuilding the body file (the `sed` line under Tickets) and `gh issue edit <n> --body-file .heimdall/tickets/T<nn>-<slug>.body.md`.

## Pull requests

Round 1, after `git push -u origin heimdall/t<nn>-<slug>`:

```bash
gh pr create --base <integration-branch> --head heimdall/t<nn>-<slug> \
  --title "<ticket title> (#<n>)" --body-file .heimdall/reports/T<nn>-pr.md
gh pr view <pr#> --json mergeable,mergeStateStatus,headRefOid,statusCheckRollup
```

Round 2 and later: `git push origin heimdall/t<nn>-<slug>` only; the open PR follows the branch. The integration branch itself must already be on `origin` (execution-loop.md, section 3).

## Review verdicts

GitHub rejects approval of a pull request by its own author, and agents usually share the user's account. Record verdicts as a review comment plus a label:

```bash
gh pr review <pr#> --comment --body-file .heimdall/reports/T<nn>-review-<round>.md
gh issue edit <n> --remove-label heimdall:in-review --add-label heimdall:approved           # or heimdall:changes-requested
```

Use `gh pr review --approve` / `--request-changes` only when the reviewer runs under a different account.

## Merge and close

```bash
gh pr merge <pr#> --squash --match-head-commit <guarded-head-sha>
git fetch origin && git merge --ff-only origin/<integration-branch>     # in the main checkout
MERGE_SHA=$(git rev-parse HEAD)                                         # serial merges: the tip is the squash commit
gh pr view <pr#> --json mergeCommit --jq .mergeCommit.oid               # cross-check: must equal $MERGE_SHA
gh issue close <n> --comment "Merged in <merge-sha> via #<pr#>."
```

- `--match-head-commit` refuses the merge if anyone pushed after the guarded head was recorded (merge-protocol.md, L6).
- No `--delete-branch`: it also deletes the local branch, which fails while the ticket's worktree holds it. Delete after the worktree is removed, with `git push origin --delete heimdall/t<nn>-<slug>` (merge-protocol.md, L6, step 7).
- Closing keywords (`Closes #n`) close issues only when the PR merges into the **default branch**. The merger therefore always closes the ticket explicitly; keywords are a bonus.
- Use `gh pr merge --auto` only when the repo has required checks configured; otherwise the merger runs the suite itself (merge-protocol.md).

## Merge path `local` with this tracker

No PR exists. Verdicts: `gh issue comment <n> --body-file .heimdall/reports/T<nn>-review-<round>.md` plus the label change. Merge: the local squash (merge-protocol.md, L6). Close: `gh issue close <n> --comment "Merged locally in <merge-sha>; pushed at the next approved checkpoint."` The SHA is unpushed until that checkpoint.

## Read

```bash
gh issue view <n> --json number,title,body,labels,comments,state
gh pr diff <pr#>            # reviewer input
```
