# Tracker — Gitea (`tea`)

Implements the tracker contract in execution-loop.md, section 2. Verified 2026-10-25 against `tea` 0.16.0, Gitea 1.27.1, and docs.gitea.com; the comment-edit, snapshot, and repository-creation commands added 2026-10-26 were checked against `tea` 0.16.0 `--help` and the Gitea SDK documentation (Context7: `EditIssueComment` is `PATCH /repos/{owner}/{repo}/issues/comments/{id}`) but not run against an instance (UNVERIFIED in use). Run commands inside the project clone so `tea` discovers the login and repository from the remote (or pass `--repo owner/repo` and `--login <name>`). Never print or store tokens; authentication is the user's `tea login add`.

`tea api <endpoint>` prefixes `/api/v1/` and fills `{owner}` and `{repo}` from the current repository. A body via `-f` / `-F` / `-d` makes the method POST by default. Quote endpoints that contain `?` or `&`.

## Preflight (G2, once)

```bash
tea login list                                   # a login for this host must exist
tea api /repos/{owner}/{repo} | jq '{default_branch, has_issues, has_pull_requests, internal_tracker}'
```

A repository with no commits yet has no branch: the bootstrap commit at G3 creates the first one. `internal_tracker.enable_issue_dependencies` tells you whether native blocking edges work. Instances can disable dependencies; then use the body fallback below. Gitea has no sub-issues: group tickets with a milestone and a `Part of #<spec>` line.

No remote yet (greenfield, calibration.md, section 4): offer a new private repository and create it only on the user's yes:

```bash
tea repos create --name <name> --private        # no --init: the local repository already has history or will get the bootstrap commit
git remote add origin <clone url from the output>
```

## Setup (G3, once per build)

```bash
for l in "heimdall:spec|#5319e7" "heimdall:ready|#0e8a16" "heimdall:in-progress|#fbca04" \
         "heimdall:in-review|#1d76db" "heimdall:changes-requested|#d93f0b" \
         "heimdall:approved|#0e8a16" "heimdall:needs-human|#b60205" "heimdall:prefactor|#c5def5" \
         "heimdall:acceptance|#bfd4f2"; do
  tea labels create --name "${l%%|*}" --color "${l##*|}"
done
tea milestones create --title "<milestone title>" --description "<goal>"
```

`tea labels create` fails on an existing name; list first with `tea labels list -o json` and skip existing labels.

## Spec issue

```bash
tea issues create --title "Spec: <project>" --labels heimdall:spec --description-file .heimdall/spec.md
```

Progress report and state snapshot (production-orchestrator.md, sections 5 and 6), from G3 on: each is one comment, created once and then edited in place. Record each comment id in STATE.md (Tracker comments). The first line of each file is its marker — `<!-- heimdall:progress -->` or `<!-- heimdall:snapshot -->` — so a new machine can find the comments.

```bash
tea api -X POST '/repos/{owner}/{repo}/issues/<spec#>/comments' -F body=@.heimdall/PROGRESS.md | jq .id   # create once: prints the id
tea api -X PATCH '/repos/{owner}/{repo}/issues/comments/<id>' -F body=@.heimdall/PROGRESS.md              # every later refresh
```

The same two commands post `.heimdall/snapshot.md` (or its two parts when it is split).

Rebuild on a machine without `.heimdall/` (production-orchestrator.md, section 5):

```bash
tea issues list --state all --labels heimdall:spec -o json
tea api '/repos/{owner}/{repo}/issues/<spec#>/comments' | jq '.[] | select(.body | startswith("<!-- heimdall:snapshot")) | {id, body}'
```

## Tickets

Create in dependency order (blockers first):

```bash
# the issue body: the draft without its template comment, its H1, and its local status lines; "Part of #<spec>" is then the first line
awk 'NR==1 && /^<!--/ {skip=1} skip { if (/-->/) skip=0; next } !h && /^# / {h=1; next} /^(Status|Claimed by|Merged):/ {next} {print}' \
  .heimdall/tickets/T<nn>-<slug>.md | sed '/./,$!d' > .heimdall/tickets/T<nn>-<slug>.body.md
tea issues create --title "<ticket title>" --labels heimdall:ready[,heimdall:prefactor | ,heimdall:acceptance] \
  --milestone "<milestone title>" --description-file .heimdall/tickets/T<nn>-<slug>.body.md
```

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

Every other transition in execution-loop.md, section 2, uses the same shape: `tea issues edit <n> --remove-labels heimdall:<from> --add-labels heimdall:<to>`. A widened touch set is written back by rebuilding the body file (the `sed` line under Tickets) and `tea issues edit <n> --description-file .heimdall/tickets/T<nn>-<slug>.body.md`.

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

## Merge path `local` with this tracker

No PR exists. Verdicts: `tea comment <n> "$(cat .heimdall/reports/T<nn>-review-<round>.md)"` plus the label change. Merge: the local squash (merge-protocol.md, L6). Close: `tea comment <n> "Merged locally in <merge-sha>; pushed at the next approved checkpoint."`, then `tea issues close <n>`. The SHA is unpushed until that checkpoint.

## Read

```bash
tea issues <n> -o json            # or: tea api '/repos/{owner}/{repo}/issues/<n>'
tea api '/repos/{owner}/{repo}/pulls/<pr#>.diff'
```
