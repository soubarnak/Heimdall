# STATE — <project-slug> — v<N> — <YYYY-MM-DD> — Heimdall v<skill version>

<!-- The resume point. Rewritten by the orchestrator after every gate lock and every ticket status change.
     The tracker wins on any disagreement about ticket status (references/execution-loop.md, section 9). -->

Mode: <Build | Build-lite>   Operating mode: <Prototype | MVP | Production>   Class: <C2 | C3>   Profile: <agent | chat>
Orchestrator: <harness> / <model> / effort <level>   Budget: <tight | standard | generous>
Tracker: <GitHub owner/repo | Gitea host/owner/repo | local>   Edges: <native | body>   Merge path: <pr | local>
Integration: <branch> @ <sha>   Worktree root: <path>   Cap: <n> coders
Topology: coders <tier → harness/model>; reviewer <harness/model>; researchers <harness/model>
Gates locked: <G1 YYYY-MM-DD, G2 …>   Accepted risks: <grade exceptions or "none">
Current: <gate, or "build loop">

## Tickets
| T | # | Title | Status | Tier | Touch set | Blocked by | Agent / round | PR | Merged |
|---|---|---|---|---|---|---|---|---|---|
| T01 | <n> | <scaffold> | <ready> | <Standard> | <all; deps, config> | — | — | — | — |

In flight: <T03 coder r1 (subagent id), T04 review r1, …, or "none">
Merge queue: <T02, or "empty">
Held hotspots: <deps: T05, or "none">

## Handoff Digest (generated from HANDOFF v<N> — regenerate on every HANDOFF bump; never hand-edit)
Settled: <every Settled Decision, ONE line each>
Seams: <seam — module, one line each>
Design: <one-line direction; the full contract lives in HANDOFF.md>

## Health
Retries <n> | Tier bumps <n> | Fix rounds <n> | Conflicts <mechanical n, semantic n> | Red integration tips <n> | Failure causes <tally>
Rule: if 2 of the last 4 merged tickets were unhealthy, pause dispatching for a health check.

## needs-human
<question or action per ticket, or "none">

## Fixes  <!-- post-ship fix tickets -->
<none>

## Pending
<parked change requests, G6 cleanup list, post-ship backlog>

## Next
<exact next action, e.g. "build loop: T05 review r1 running; merge T03 next">
