# Tracker — Local files (no remote)

Implements the tracker contract in execution-loop.md, section 2, for projects without GitHub or Gitea, or when the user declines a remote tracker. Tickets are files under `.heimdall/`, so this works offline and in every harness. The merge path is always `local`: squash merges in the local repository replace pull requests.

`.heimdall/` is excluded from git (`.git/info/exclude`), and the orchestrator is the only agent that edits ticket status, so status edits never race and never conflict.

## Layout

```
.heimdall/spec.md                          the spec (G1 lock)
.heimdall/tickets/T<nn>-<slug>.md          one file per ticket, numbered in dependency order (blockers first)
.heimdall/reports/T<nn>-coder-<round>.md   coder return reports
.heimdall/reports/T<nn>-review-<round>.md  review verdicts
.heimdall/reports/T<nn>-checks-<round>.md  ticket checks (execution-loop.md, section 5)
```

Each ticket file (assets/ticket.md) starts with a status block:

```
Status: ready | in-progress | in-review | changes-requested | approved | closed | needs-human
Kind: feature | prefactor | bug | env | acceptance
Milestone: <milestone title>
Blocked by: T03, T05            (or "none")
Branch: heimdall/t<nn>-<slug>
Claimed by: <role>-<agent id>   (empty until claimed)
Merged: <merge sha>             (empty until closed)
```

## Operations

| Operation | Local implementation |
|---|---|
| Preflight | `git rev-parse --show-toplevel` succeeds; the working tree is clean |
| Setup | create `.heimdall/tickets/`, `.heimdall/packets/`, and `.heimdall/reports/`; add `.heimdall/` to `.git/info/exclude` |
| Spec issue | `.heimdall/spec.md` |
| Progress report | `.heimdall/PROGRESS.md` at every refresh, `.heimdall/progress.html` when production-orchestrator.md, section 6 says so; nothing is posted |
| State snapshot | none: `.heimdall/` is the only copy. At G3 tell the user so and recommend backing it up with the project (for example `tar czf heimdall-state-<date>.tgz .heimdall` kept outside the repository) |
| Tickets | write `T<nn>-<slug>.md` from assets/ticket.md with `Status: ready` |
| Blocking edges | the `Blocked by:` line |
| Frontier query | `Status: ready`, every `Blocked by` ticket `closed`, touch set free (merge-protocol.md, L3) |
| Claim and status | edit `Status:` and `Claimed by:` |
| Pull requests | none; the branch plus the coder's report stand in. Review input is `git diff <synced-with>...heimdall/t<nn>-<slug>` (the report's `Synced with` SHA). Status still moves to `in-review` |
| Review verdicts | the review report file plus a `Status:` change |
| Merge and close | merge-protocol.md, L6, local path: `git merge --squash`, commit `"<ticket title> (T<nn>)"`, `Merged: $(git rev-parse HEAD)`, then `Status: closed` |
| Read | read the file |

Pushing the integration branch to a remote, if one exists, happens only at checkpoints the user approves: ask at the end of every wave and at G7, with a one-line summary of what the push contains.
