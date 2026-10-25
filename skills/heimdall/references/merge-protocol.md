# Merge Protocol — Parallel Coders Without Merge Conflicts

Read at G2 (architecture for parallelism), G3 (touch sets), and in every merge step of the build loop (execution-loop.md). Git commands verified against git 2.55.

## What this protocol promises

Textual merge conflicts happen when two branches edit the same lines, or when a branch is built on a stale base. Heimdall prevents them **by construction**: tickets that could collide never run at the same time, shared files are set up before parallel work starts, and only one agent ever writes the integration branch. With these rules a conflict is rare, and when one occurs it is mechanical (a lockfile, a generated file) and the merger resolves it by regeneration.

No protocol can promise zero conflicts. **Semantic conflicts** (two tickets each correct alone, wrong together) produce no textual conflict at all. The merger catches them by running the full suite on the merged result before every merge. Say this plainly to the user at G2; never claim "no conflicts guaranteed".

## The seven layers

### L1 — Architecture for parallelism (G2)

Decide these in ARCH (HANDOFF.md) so parallel tickets do not need the same files:

- **Module map:** every module has a name, a path glob, and a public interface (its seam). Tickets name modules; the module map gives the paths. This is the only place paths live, so tickets stay path-free.
- **Registration by discovery:** routes, commands, plugins, DI bindings, navigation entries, and exports register themselves (file-system routing, glob imports, one file per feature) instead of all features editing one central list.
- **Fragments instead of shared logs:** changelog entries, release notes, and decision notes are one file per ticket, or generated from commits at release time.
- **Migrations:** timestamp-named, or numbered by the merger at merge time. Never hand-pick "the next number" in parallel branches.
- **Generated files** (lockfiles, API clients, schema types, snapshots): never hand-merged; regenerate after merge. Prefer not committing generated code that tooling can rebuild.
- **Formatting:** formatter and linter config land in the scaffold ticket. Coders format only files they touch; repo-wide reformatting is its own ticket that runs alone.

### L2 — Scaffold first (G3)

T01 is the **scaffold/prefactor ticket** (walking skeleton): repository init or prefactor, toolchain, test runner and the commands in HANDOFF, CI, formatter and linter, the module skeleton from the module map, discovery-based registries, foreseeable dependencies, `.env.example` names, and migration setup. Every other ticket is blocked by T01. Brownfield builds replace it with prefactor tickets ("make the change easy, then make the easy change") that create the seams and registries the later tickets need.

### L3 — Touch sets and hotspot locks (G3, enforced by the scheduler)

Every ticket declares a **touch set**: the modules it may change (by module-map name) and the **hotspots** it needs. Hotspots are shared resources that only one in-flight ticket may hold:

| Hotspot | Covers |
|---|---|
| `deps` | dependency manifests and lockfiles |
| `schema` | database schema and migrations |
| `config` | shared configuration, `.env.example`, CI files |
| `registry:<name>` | any central list that could not be made discovery-based |
| `styles` | global styles, theme tokens |
| `public-api:<module>` | a module's public interface that other tickets consume |

Scheduling rule: **two tickets whose touch sets share a module or a hotspot never run concurrently.** If one logically precedes the other, add a blocking edge; otherwise the scheduler serializes them (whichever is claimed first holds the lock). Predict hidden overlap before dispatch with `git merge-tree` (below) when two in-flight branches have already diverged.

### L4 — Isolation

- One **git worktree and branch per coder**, created by the orchestrator from the integration tip:
  ```bash
  git worktree add -b heimdall/t<nn>-<slug> <worktree-root>/t<nn>-<slug> <integration-branch>
  ```
  `<worktree-root>` sits outside the repository (default `../<repo>.worktrees`) so test runners and type checkers in the main checkout never scan other coders' copies. A harness's native worktree isolation is acceptable only if it bases the worktree on the integration tip.
- A coder edits only files inside its touch set, plus tests for those modules. Needing anything else is a **stop-and-report** (`BLOCKED: touch-set`), never a quiet edit.
- The orchestrator never edits product code while coders run. It works in the main checkout on `.heimdall/` files only (git-excluded, so they never conflict).
- Only the merger writes the integration branch. Coders, reviewers, and the orchestrator never commit to it directly.

### L5 — Fresh base before review

Before reporting done, the coder merges the integration tip into its branch, runs the full suite, and fixes anything red:

```bash
git -C <worktree> merge --no-edit <integration-branch>
```

Before the PR exists the coder may rebase instead; after the PR exists, merge only (rebasing rewrites the commits the reviewer audited).

### L6 — Serial merger

Exactly one merge runs at a time. For each approved ticket, in approval order:

1. **SHA guard.** The PR head (or branch tip) must equal the SHA the reviewer approved. Any later push sends it back to review.
2. **Pre-check** against the current integration tip, without touching any worktree:
   ```bash
   git fetch origin                                   # remote trackers only
   git merge-tree --write-tree --name-only --no-messages <integration-branch> heimdall/t<nn>-<slug>
   # exit 0 = clean; exit 1 = conflicts (the conflicted paths are listed after the tree id)
   ```
3. **Update and test.** If the integration tip moved since the coder's sync, merge it into the ticket branch in the ticket's worktree and run the full suite there. Clean and green → continue (no re-review: the incoming changes were already reviewed). Red → semantic conflict, see the table below.
4. **Merge** with the tracker's operation (squash, one commit per ticket, guarded by the new head SHA) or, on the local merge path:
   ```bash
   git switch <integration-branch> && git merge --squash heimdall/t<nn>-<slug> && git commit -m "<ticket title> (T<nn>)"
   ```
5. **Verify the integration tip** (CI or the full suite). Red after a merge stops all new dispatches until it is green again (fix-forward ticket, or `git revert -m 1 <sha>` / `git revert <sha>` — a new commit, never a reset).
6. **Close and clean up:** close the ticket with the merge SHA (tracker file), fast-forward the main checkout (`git pull --ff-only` or `git merge --ff-only`), then
   ```bash
   git worktree remove <worktree-root>/t<nn>-<slug>
   git branch -d heimdall/t<nn>-<slug>        # -D after a squash merge: git cannot see squashed history as merged
   git worktree prune
   ```
7. Recompute the frontier (execution-loop.md).

### L7 — When a conflict happens anyway

| Conflict | Example | Who resolves | How |
|---|---|---|---|
| Mechanical | lockfile, generated client, snapshot, fragment ordering | merger | regenerate with the project's tool (`npm install`, `uv lock`, codegen), never hand-edit; run the full suite; note it in the PR |
| Trivial adjacency | two imports added on neighbouring lines | merger | keep both; run the full suite; the merge commit goes to a one-commit re-review (`git show --cc <merge-sha>`) |
| Semantic | both sides change the same logic; suite red after a clean merge | the coder | abort (`git merge --abort`), set the ticket to changes-requested with the conflicting ticket and the failing output; the coder re-syncs and fixes in its worktree |
| Design | the two tickets disagree about a public interface | orchestrator | stop both; revision loop to G3 (or G2 if the module map was wrong) |

Every conflict is a signal that L1–L3 missed something. Record it in STATE.md Health and fix the cause (add a hotspot, a discovery registry, or a missing blocking edge) before dispatching the next wave.

## Hard rules

- Never force-push the integration branch or the default branch. Never `reset --hard` a shared branch. Undo with revert commits.
- Never merge a ticket that is not approved at its current head SHA.
- Never resolve a non-mechanical conflict silently; it goes back to a coder or up to the orchestrator.
- Never let two coders share a worktree or a branch.
- Merging into the default branch, and every push, happens only under the standing authorization recorded at G2 (production-orchestrator.md, G2). A user rule that demands approval per push overrides it: then use the local merge path and push at user-approved checkpoints.
