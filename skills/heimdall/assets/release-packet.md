# RELEASE PACKET — <project-slug> — G7 — HANDOFF v<N>

Release: <version, e.g. 1.0.0>   Integration: <integration-branch> @ <tip sha>   Default branch: <name>
Target: <deployment target — ADR NNNN>   Environments: <staging, production, … from HANDOFF ARCH>
Run by: the orchestrator, in the session where the user signs off G7. Deploy steps are never delegated to a subagent or a headless run.

<!-- Orchestrator (references/production-orchestrator.md, G7): fill every <…> from HANDOFF.md (Deployment and environments,
     Configuration and secrets, Commands), the spec's Success Criteria, and the G6 reports. Save as
     .heimdall/packets/G7-release.md and show it to the user before any step runs. The G7 sign-off approves the plan;
     every row marked GO-AHEAD still needs the user's explicit go-ahead for that specific action when it is about to run.
     Secrets by name only, never values. Containers: rootless podman (`Containerfile`, `podman build`, `podman push`),
     never Docker. Record the outcome in the release report at the end and in STATE.md. -->

## 1. Preflight (read-only; the orchestrator runs these and records each result)

- [ ] Every ticket closed; every G6 blocking finding closed; STATE.md needs-human is empty.
- [ ] Integration tip green: CI on `<tip sha>` (merge-protocol.md, L6, step 6), or the full suite from a clean checkout.
- [ ] Build from clean: `<Install command>`, then `<Build command>`.
- [ ] Acceptance tests green: `<End-to-end command>` — one per Success Criterion (HANDOFF Coverage table).
- [ ] Version `<version>` set in `<manifest file>`; release notes generated from the merged tickets (titles and merge SHAs).
- [ ] Dependency audit: `<audit command>` → no High or Critical findings, or each one an accepted risk in STATE.md.
- [ ] No secrets in the repository or its history (the G6 security lens); every required variable named in `.env.example`.
- [ ] Migrations in this release: <list, or "none">; each destructive one has the backup step in section 3.
- [ ] License and privacy line present (user-facing applications).

## 2. Configuration (names only)

| Variable | Where it is set | Set by | Status |
|---|---|---|---|
| <STRIPE_SECRET_KEY> | <hosting dashboard, secret store, CI secret> | the user | <set / missing> |

A missing variable stops the release before section 3. The user sets it; Heimdall never reads or prints its value.

## 3. Release steps (in order; each needs its own go-ahead)

| # | Step | Command or action | Run by | Go-ahead |
|---|---|---|---|---|
| 1 | Back up production data | `<backup command>` → `<backup location>` | <orchestrator / user> | GO-AHEAD |
| 2 | Merge the release PR into `<default branch>` (brownfield, or when the integration branch is not the default) | `<gh pr merge … / tea pulls merge …>` | orchestrator | GO-AHEAD |
| 3 | Tag the release | `git tag -a v<version> -m "<project> <version>"`, then `git push origin v<version>` | orchestrator | GO-AHEAD |
| 4 | Build and publish the artifact | `<podman build -t <image>:<version> -f Containerfile .` and `podman push …`, a package publish, or "CI does it on the tag"> | <…> | GO-AHEAD |
| 5 | Deploy | `<platform CLI or the CI deploy job>` | <…> | GO-AHEAD |
| 6 | Run migrations | `<migration command>` | <…> | GO-AHEAD |

Drop rows that do not apply; never add an unlisted outward step without asking. A step that fails stops the sequence: report the exact error and go to section 5 or ask.

## 4. Smoke test (after deploy; read-only)

| # | Success Criterion (spec) | Check against `<production URL or command>` | Result |
|---|---|---|---|
| 1 | <criterion> | <the HTTP request, CLI call, or browser journey> | <PASS / FAIL> |

Also: the health endpoint or start command answers; the core journey completes; logs show no new errors for <5> minutes. A failed smoke test stops the release: roll back (section 5) or fix forward with a `bug` ticket — the user chooses; recommend rolling back when real users are affected.

## 5. Rollback plan

- Trigger: <a smoke-test failure | error rate above <x> | the user says so>.
- Steps: <redeploy the previous tag or image `<…>`>; <restore the step-1 backup if a migration ran>; <revert the release merge with a new commit, never a force-push>.
- Rehearsed before release: <yes — how | no — an accepted risk in STATE.md>.

## 6. Monitoring

- Uptime check: <service and URL, or "none — accepted risk">.
- Errors and logs: <where to look>.
- Alerts go to: <who>.

## 7. Handover

The G7 briefing (assets/briefing.md) is the operations handover: how to run, deploy, monitor, back up, update dependencies, and roll back; where every artifact lives; the post-ship backlog (STATE.md Pending). Bugs after ship enter as fix tickets (production-orchestrator.md, section 7).

## Release report (filled after section 4)

RELEASE: <SHIPPED | ROLLED-BACK | STOPPED: step <n>>
Version <version> at <sha>; deployed <YYYY-MM-DD HH:MM UTC> to <target>; smoke <passed>/<total>; rollback rehearsed <yes | no>.
Steps run: <# — result, one per line>
