# Tracker — Local files (no remote)

Implements the tracker contract in execution-loop.md, section 2, for projects without GitHub or Gitea, or when the user declines a remote tracker. Tickets are files under `.heimdall/`, so this works offline and in every harness. The merge path is always `local`: squash merges in the local repository replace pull requests.

`.heimdall/` is excluded from git (`.git/info/exclude`), and the orchestrator is the only agent that edits ticket status, so status edits never race and never conflict.

## Layout

```
.heimdall/spec.md                          the spec (G1 lock)
.heimdall/tickets/T<nn>-<slug>.md          one file per ticket, numbered in dependency order (blockers first)
.heimdall/reports/T<nn>-coder-<round>.md   coder return reports
.heimdall/reports/T<nn>-review-<round>.md  review verdicts
```

Each ticket file (assets/ticket.md) starts with a status block:

```
Status: ready | in-progress | in-review | changes-requested | approved | closed | needs-human
Kind: feature | prefactor | bug | env
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
| Setup | create `.heimdall/tickets/` and `.heimdall/reports/`; add `.heimdall/` to `.git/info/exclude` |
| Spec issue | `.heimdall/spec.md` |
| Progress report | `.heimdall/PROGRESS.md` and `.heimdall/progress.html`; nothing is posted |
| Tickets | write `T<nn>-<slug>.md` from assets/ticket.md with `Status: ready` |
| Blocking edges | the `Blocked by:` line |
| Frontier query | `Status: ready`, every `Blocked by` ticket `closed`, touch set free (merge-protocol.md, L3) |
| Claim and status | edit `Status:` and `Claimed by:` |
| Pull requests | the branch plus the coder's report; review input is `git diff <integration>...heimdall/t<nn>-<slug>` |
| Review verdicts | the review report file plus a `Status:` change |
| Merge and close | merge-protocol.md, L6, local path: `git merge --squash`, commit `"<ticket title> (T<nn>)"`, then `Status: closed` and `Merged: <sha>` |
| Read | read the file |

Pushing the integration branch to a remote, if one exists, happens only at checkpoints the user approves.
