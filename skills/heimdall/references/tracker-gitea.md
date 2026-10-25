# Tracker — Gitea (`tea`)

Implements the tracker contract in execution-loop.md, section 2. Verified 2026-10-25 against `tea` 0.16.0, Gitea 1.27.1, and docs.gitea.com. Run commands inside the project clone so `tea` discovers the login and repository from the remote (or pass `--repo owner/repo` and `--login <name>`). Never print or store tokens; authentication is the user's `tea login add`.

`tea api <endpoint>` prefixes `/api/v1/` and fills `{owner}` and `{repo}` from the current repository. A body via `-f` / `-F` / `-d` makes the method POST by default. Quote endpoints that contain `?` or `&`.

## Preflight (G2, once)

```bash
tea login list                                   # a login for this host must exist
tea api /repos/{owner}/{repo} | jq '{default_branch, has_issues, has_pull_requests, internal_tracker}'
```

`internal_tracker.enable_issue_dependencies` tells you whether native blocking edges work. Instances can disable dependencies; then use the body fallback below. Gitea has no sub-issues: group tickets with a milestone and a `Part of #<spec>` line.

## Setup (G3, once per build)

```bash
for l in "heimdall:spec|#5319e7" "heimdall:ready|#0e8a16" "heimdall:in-progress|#fbca04" \
         "heimdall:in-review|#1d76db" "heimdall:changes-requested|#d93f0b" \
         "heimdall:approved|#0e8a16" "heimdall:needs-human|#b60205" "heimdall:prefactor|#c5def5"; do
  tea labels create --name "${l%%|*}" --color "${l##*|}"
done
tea milestones create --title "<milestone title>" --description "<goal>"
```

`tea labels create` fails on an existing name; list first with `tea labels list -o json` and skip existing labels.

## Spec issue

```bash
tea issues create --title "Spec: <project>" --labels heimdall:spec --description-file .heimdall/spec.md
```

Progress report (production-orchestrator.md, section 6), one comment per refresh:

```bash
tea comment <spec#> "$(cat .heimdall/PROGRESS.md)"
```

## Tickets

Create in dependency order (blockers first):

```bash
tea issues create --title "<ticket title>" --labels heimdall:ready \
  --milestone "<milestone title>" --description-file .heimdall/tickets/T<nn>-<slug>.md
```

The first line of every ticket body is `Part of #<spec>`.

## Blocking edges

```bash
# ticket <n> depends on (is blocked by) issue <b>
tea api -X POST '/repos/{owner}/{repo}/issues/<n>/dependencies' -F index=<b> -f owner=<owner> -f repo=<repo>
tea api '/repos/{owner}/{repo}/issues/<n>/dependencies'     # lists blockers; check each one's "state"
```

Fallback when dependencies are disabled: the ticket body's `## Blocked by` section (`- #12`). Record which representation is in use in STATE.md.

## Frontier query

```bash
tea issues list --state open --labels heimdall:ready -o json --limit 200
```

Then drop tickets with an open blocker (dependency API or body section) or a touch set that overlaps an in-flight ticket (merge-protocol.md).

## Claim and status

```bash
tea issues edit <n> --remove-labels heimdall:ready --add-labels heimdall:in-progress
tea comment <n> "Claimed by <role>-<agent-id> on branch heimdall/t<nn>-<slug>."
```

Every other transition in execution-loop.md, section 2, uses the same shape: `tea issues edit <n> --remove-labels heimdall:<from> --add-labels heimdall:<to>`. A widened touch set is written back with `tea issues edit <n> --description-file .heimdall/tickets/T<nn>-<slug>.md`.

## Pull requests

Round 1, after `git push -u origin heimdall/t<nn>-<slug>`:

```bash
tea pulls create --base <integration-branch> --head heimdall/t<nn>-<slug> \
  --title "<ticket title> (#<n>)" --description-file .heimdall/reports/T<nn>-pr.md
tea api '/repos/{owner}/{repo}/pulls/<pr#>' | jq '{mergeable, head: .head.sha, state}'
```

Round 2 and later: `git push origin heimdall/t<nn>-<slug>` only; the open PR follows the branch. The integration branch itself must already be on `origin` (execution-loop.md, section 3).

## Review verdicts

Approval by the pull request's own author may be rejected, and agents usually share the user's account. Record verdicts as a comment plus a label:

```bash
tea comment <pr#> "$(cat .heimdall/reports/T<nn>-review-<round>.md)"
tea issues edit <n> --remove-labels heimdall:in-review --add-labels heimdall:approved   # or heimdall:changes-requested
```

Use `tea pulls approve <pr#>` / `tea pulls reject <pr#>` only when the reviewer has its own Gitea account.

## Merge and close

```bash
test "$(tea api '/repos/{owner}/{repo}/pulls/<pr#>' | jq -r .head.sha)" = "<guarded-head-sha>" || exit 1   # SHA guard
tea pulls merge <pr#> --style squash --title "<ticket title> (#<n>)" --message "Ticket #<n>"
git fetch origin && git merge --ff-only origin/<integration-branch>     # in the main checkout
MERGE_SHA=$(git rev-parse HEAD)                                         # serial merges: the tip is the squash commit
tea comment <n> "Merged in <merge-sha> via !<pr#>."
tea issues close <n>
```

- Merge styles: `merge`, `rebase`, `squash`, `rebase-merge` (Heimdall default: `squash`, one commit per ticket).
- Closing keywords (`close`, `closes`, `fix`, `fixes`, `resolve`, …) in a PR description close issues on merge only when the merger has permission. The merger always closes the ticket explicitly anyway.
- `tea pulls merge` has no head-SHA guard: the `test` line reads `head.sha` immediately before merging and aborts if it differs from the guarded head (merge-protocol.md, L6).
- Do not use `tea pulls clean`: it deletes the local branch while the ticket's worktree holds it. Delete after the worktree is removed, with `git push origin --delete heimdall/t<nn>-<slug>` (merge-protocol.md, L6, step 7).

## Read

```bash
tea issues <n> -o json            # or: tea api '/repos/{owner}/{repo}/issues/<n>'
tea api '/repos/{owner}/{repo}/pulls/<pr#>.diff'
```
