# Loop Card — the Build Loop (G4–G5) on One Page

A checklist for running the build loop. Load it with STATE.md and HANDOFF.md at the start of every loop session. It cites the full rules: read execution-loop.md, merge-protocol.md, and the tracker file once per session, and go back to the cited section whenever a step is unclear. Where this card and a cited section differ, the cited section wins.

## Every scheduler pass (execution-loop.md, section 4)

1. **Sync:** fast-forward the main checkout; read ticket statuses from the tracker (the tracker wins); update STATE.md.
2. **Guard:** integration tip red → dispatch nothing new; route the failure (execution-loop.md, section 8).
3. **Collect** every finished agent (the table below).
4. **Merge** the oldest approved ticket when no merge is running (merge-protocol.md, L6).
5. **Frontier:** status ready, every blocker closed, touch set and hotspots free of every in-flight ticket. Order: critical path, prefactor, High risk, lowest T<nn>.
6. **Dispatch** while running coders < cap.
7. **Exit** when nothing is in flight or queued: all closed → G6; otherwise stop and report each blocked ticket.
8. **Checkpoint** STATE.md.

## One ticket, start to finish

| Step | Do | Rule |
|---|---|---|
| Claim | ready → in-progress; STATE.md: agent, round, start time | execution-loop.md, section 5, step 1 |
| Worktree | `git worktree add -b heimdall/t<nn>-<slug> <worktree-root>/t<nn>-<slug> <integration-branch>`; reuse one that exists | section 5, step 2 |
| Packet | assets/coder-packet.md → `.heimdall/packets/T<nn>-coder-<round>.md`; grade it | section 5, step 3 |
| Dispatch | the topology's method; a headless run starts in the background with `exec`, its PID goes into STATE.md In flight; never a second run while that PID is alive | section 5, step 4; harness-adapters.md, section 1 |
| Collect | only after the PID has exited (`kill -0` fails): the final message → `.heimdall/reports/T<nn>-coder-<round>.md` | section 5, step 5 |
| Check | `bash .heimdall/ticket-checks.sh …` with the exact flags in section 5, step 6 (`--help` lists them) → `.heimdall/reports/T<nn>-checks-<round>.md`; route its codes (below) | section 5, step 6 |
| Push and PR | merge path `pr`: push the branch; round 1 opens the PR; record Head; status in-review | section 5, step 7 |
| Review | assets/review-packet.md → a fresh-context reviewer; post the verdict; set the status | section 6 |
| Merge | L6 steps 1–8, one ticket at a time; STATE.md `Integration:` moves to the merge SHA | merge-protocol.md, L6 |
| Close | the ticket closed with the merge SHA; worktree and branch removed; STATE.md | merge-protocol.md, L6, step 7 |
| Wave merged | refresh the progress report; update the state snapshot; demo checkpoint after the first complete journey | execution-loop.md, section 9 |

## Ticket-check codes

| Code | Route |
|---|---|
| `HEAD-MISMATCH`, `DIRTY-TREE`, `BASE-NOT-SYNCED`, `OUT-OF-SCOPE`, `LOCKFILE-DRIFT` | re-dispatch the coder, same round, with the matching orchestrator note; no review yet |
| `COMMIT-ORDER`, `NO-RED`, `NO-TESTS` | review proceeds; the reviewer weighs them in the TDD audit |
| `SETUP-ERROR` | fix the cause and re-run once; still failing → review proceeds with the report as it stands, Health (Check setup errors) +1 |

## Report tokens (execution-loop.md, section 8)

| Token | Route |
|---|---|
| `STATUS: DONE` | ticket checks |
| `STATUS: BLOCKED: <kind>` | the section 8 row for that kind |
| `STATUS: FAILED`, no report | executor-failure ladder: retry, tier bump, other family (roster agents only; outside the roster, ask), then needs-human |
| `VERDICT: APPROVE` | merge queue |
| `VERDICT: CHANGES_REQUESTED` | fix round (round + 1; counts toward the cap of 2) |
| `VERDICT: STALE` | regenerate the review packet at the current head; not a round |
| `MERGE: MERGED-READY` | push (merge path `pr`), record the guarded head, merge |
| `MERGE: SEMANTIC-CONFLICT` | approved → changes-requested; a merge-repair round (not counted toward the cap) |

## Stop for the user only on

`needs-human` items (batched, at most 4 per message, one recommended answer each) · the health rule · a revision loop to G2 or G3 · an outward action outside the standing authorization · the demo checkpoint.

## Resume (production-orchestrator.md, section 5; execution-loop.md, section 9)

Calibrate again (detection only), migrate STATE.md to the current shape, reconcile with the tracker, then for each open ticket: a live agent → wait; a dirty worktree → a coder continues it; commits beyond the base → a coder continues; nothing → back to ready.
