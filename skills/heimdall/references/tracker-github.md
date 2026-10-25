# Tracker — GitHub (`gh`)

Implements the tracker contract in execution-loop.md, section 2. Verified 2026-10-25 against `gh` 2.103.1 and the GitHub REST API. Run every command inside the project clone so `gh` infers the repository. Never print or store tokens; authentication is the user's `gh auth login`.

## Preflight (G2, once)

```bash
gh auth status                       # must show a logged-in account with repo scope
gh repo view --json nameWithOwner,defaultBranchRef,hasIssuesEnabled
```

If issues are disabled, ask the user to enable them or choose the local tracker.

## Setup (G3, once per build)

```bash
for l in "heimdall:spec|5319E7" "heimdall:ready|0E8A16" "heimdall:in-progress|FBCA04" \
         "heimdall:in-review|1D76DB" "heimdall:changes-requested|D93F0B" \
         "heimdall:approved|0E8A16" "heimdall:needs-human|B60205" "heimdall:prefactor|C5DEF5"; do
  gh label create "${l%%|*}" --color "${l##*|}" --force
done
gh api repos/{owner}/{repo}/milestones -f title="<milestone title>" -f description="<goal>"
```

`--force` updates a label that already exists. If the repo already uses Matt Pocock's triage labels (`docs/agents/triage-labels.md`), also apply its `ready-for-agent` string next to `heimdall:ready`.

## Spec issue

```bash
gh issue create --title "Spec: <project>" --label heimdall:spec --body-file .heimdall/spec.md
```

Progress report (production-orchestrator.md, section 6), one comment per refresh:

```bash
gh issue comment <spec#> --body-file .heimdall/PROGRESS.md
```

## Tickets

Create tickets in dependency order (blockers first) so edges can reference real numbers:

```bash
gh issue create --title "<ticket title>" --label heimdall:ready [--label heimdall:prefactor] \
  --milestone "<milestone title>" --parent <spec#> --body-file .heimdall/tickets/T<nn>-<slug>.md
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

## Pull requests

```bash
gh pr create --base <integration-branch> --head heimdall/t<nn>-<slug> \
  --title "<ticket title> (#<n>)" --body-file .heimdall/reports/T<nn>-pr.md [--draft]
gh pr ready <pr#>                                        # draft -> ready when the coder finishes
gh pr view <pr#> --json mergeable,mergeStateStatus,headRefOid,statusCheckRollup
```

## Review verdicts

GitHub rejects approval of a pull request by its own author, and agents usually share the user's account. Record verdicts as a review comment plus a label:

```bash
gh pr review <pr#> --comment --body-file .heimdall/reports/T<nn>-review-<round>.md
gh issue edit <n> --remove-label heimdall:in-review --add-label heimdall:approved           # or heimdall:changes-requested
```

Use `gh pr review --approve` / `--request-changes` only when the reviewer runs under a different account.

## Merge and close

```bash
gh pr merge <pr#> --squash --delete-branch --match-head-commit <sha-the-reviewer-approved>
gh issue close <n> --comment "Merged in <merge-sha> via #<pr#>."
```

- `--match-head-commit` refuses the merge if anyone pushed after the review.
- Closing keywords (`Closes #n`) close issues only when the PR merges into the **default branch**. The merger therefore always closes the ticket explicitly; keywords are a bonus.
- Use `gh pr merge --auto` only when the repo has required checks configured; otherwise the merger runs the suite itself (merge-protocol.md).

## Read

```bash
gh issue view <n> --json number,title,body,labels,comments,state
gh pr diff <pr#>            # reviewer input
```
