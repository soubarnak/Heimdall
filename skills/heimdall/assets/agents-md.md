# AGENTS.md — <project name>

<!-- Written by the Heimdall orchestrator in the G3 bootstrap commit (references/production-orchestrator.md, G3),
     from HANDOFF.md. Read by every coding agent that opens this repository. Keep it under 200 lines; it is the
     map, not the manual. Brownfield: merge these sections into the existing AGENTS.md instead of replacing it.
     Claude Code reads CLAUDE.md: write a CLAUDE.md containing only the line `@AGENTS.md`. Never record secrets. -->

<Two lines: what this application is and for whom. Spec: `.heimdall/spec.md` (runtime file, not committed; the spec issue is #<n>).>

## Commands

| Task | Command |
|---|---|
| Install (frozen: never rewrites the lockfile) | `<…>` |
| Run (dev) | `<…>` |
| Build | `<…>` |
| One test file | `<…>` |
| Full suite | `<…>` |
| Type-check | `<…>` |
| Lint / format | `<…>` |
| End-to-end (acceptance tests: one per Success Criterion) | `<…>` |
| Services (podman) | `<podman compose up -d, or "none">` |

## Module map

| Module | Paths | Public interface | Tests |
|---|---|---|---|
| <booking> | `src/booking/**` | <BookingService: book, cancel, listForUser> | `src/booking/**/*.test.ts` |

Modules talk through their public interfaces only. Shared hotspots (dependencies, schema and migrations, configuration, registries, global styles, public APIs) are changed by one ticket at a time; registration is by discovery (<how: file-system routing, glob import, …>), never by editing a central list.

## Conventions

- <language, formatter, linter; naming; error handling; logging — one line each>
- Migrations: <timestamp-named; never edit a merged migration; back up before destructive ones>
- Configuration by environment variable, documented in `.env.example`; secrets never in the repository.
- Containers: rootless podman (`Containerfile`, `podman compose`), never Docker.

## How to work here

- **Test-first at the seams.** Every behavior change starts with a failing test at a public interface listed above: one behavior per test, through the public API, doubles only at system boundaries (external services, time, randomness). Commit the failing test (`test(T<nn>): …`) before the code that makes it pass (`feat(T<nn>): …`).
- **One ticket, one branch, one worktree.** Branches are `heimdall/t<nn>-<slug>`; change only the ticket's touch set; stop and report when you need more. Only the ticket that holds the dependencies hotspot changes a lockfile; anyone else restores it (`git restore --source=<base> -- <lockfile>`).
- **Decisions are recorded, not re-litigated:** `docs/adr/` holds the architecture decisions; a change is a new ADR that supersedes the old one.
- **Never** push to `<integration-branch>` directly, force-push, delete branches, run destructive commands, deploy, or spend money. The orchestrator merges.

## Where things are

- Architecture decisions: `docs/adr/`
- Build state (local, not committed): `.heimdall/` — STATE.md, HANDOFF.md, tickets, packets, reports, progress report
- <deployment notes, runbook, or "see docs/">
