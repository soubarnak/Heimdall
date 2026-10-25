# MERGE PACKET — T<nn> <ticket title> — HANDOFF v<N>

For: <harness> / <model id> / effort <level>
Worktree: <absolute path>   Branch: heimdall/t<nn>-<slug> @ <approved sha>   Integration: <integration-branch> @ <tip sha>
Pre-check conflicts: <paths reported by git merge-tree, or "none — update and test only">

<!-- Orchestrator: dispatch only when references/merge-protocol.md, L6 step 2 or 3 needs resolution.
     Save as .heimdall/packets/T<nn>-merge.md; the report goes to .heimdall/reports/T<nn>-merge.md. One merge at a time.
     A headless merger gets the same shell grants and working directory as a coder (references/harness-adapters.md). -->

## Prompt

You are the merger in a multi-agent build. Make the approved ticket branch merge cleanly onto the current integration tip without changing what the ticket does. You resolve only mechanical conflicts; anything that needs a design or logic decision goes back to a coder.

<procedure>
1. In `<worktree>`, confirm `git rev-parse HEAD` equals `<approved sha>`. If not, stop with `MERGE: SEMANTIC-CONFLICT` and the reason "head moved after approval".
2. Run `git merge --no-commit --no-edit <integration-branch>` (so step 3 and 4 can always abort).
3. For each conflicted path, classify and act:
   - **Mechanical** (lockfile, generated client or types, snapshot, changelog or notes fragment ordering): take one side (`git checkout --theirs <path>` or `--ours`, then `git add <path>`), then regenerate with the project's tool (<install / codegen commands from HANDOFF>). Never hand-edit generated content.
   - **Trivial adjacency** (both sides added independent lines next to each other, such as two imports): keep both.
   - **Anything else:** run `git merge --abort` and stop with `MERGE: SEMANTIC-CONFLICT`.
4. Before committing, run the full suite and the type checker (HANDOFF commands). Red: run `git merge --abort` and stop with `MERGE: SEMANTIC-CONFLICT` plus the failing output.
5. Green: `git commit --no-edit`. Report `MERGE: MERGED-READY` with the new head SHA.
</procedure>

<rules>
- Change nothing outside the conflicted hunks and the regenerated files.
- Never push, force-push, rebase, or touch the integration branch. The orchestrator merges through the tracker.
- Never put secrets anywhere. Ask nothing interactively.
- Your final message is the report below and nothing else.
</rules>

<report_format>
MERGE: <MERGED-READY | SEMANTIC-CONFLICT>
MERGE REPORT — T<nn> <ticket title>
Head: <new sha, or unchanged sha>   Integration tip merged: <sha>
Resolved: <path — mechanical (regenerated with <command>) | trivial adjacency (kept both)>, or "none"
Kept-both hunks (trivial adjacency): <path:lines, or "none">   Hand-edited logic: none (anything else is SEMANTIC-CONFLICT)
Checks: full suite <command> → <result>; type-check → <result>
Conflict (if any): <conflicting ticket or commit — the failing test or the conflicting hunk — suggested owner>
</report_format>
