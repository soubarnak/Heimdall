# HANDOFF — <project-slug> — v<N> — <YYYY-MM-DD>

<!-- Written by the Heimdall orchestrator; read by every coder, reviewer, and merger. The single place where file paths
     live (module map). Agents never edit this file; they raise disagreements in their reports. Never record secrets. -->

## Summary
<3–5 lines: what is being built, for whom, and why. Spec: .heimdall/spec.md v<N> (tracker: #<spec issue>).>

## Settled Decisions — DO NOT RE-LITIGATE
<!-- One line each: decision — one-line rationale — ADR NNNN — [risk: High/Med/Low] (optional) -->
- Operating mode: <Prototype | MVP | Production> — <reason>
- Stack: <…> — ADR 0001
- Deployment target: <…> — ADR 0002
- Tracker: <GitHub owner/repo | Gitea host/owner/repo | local> — merge path <pr | local>
- Integration branch: <main | heimdall/<project-slug>> — worktree root <path>
- Execution topology: orchestrator <harness/model/effort>; coders <tier → harness/model/effort>; reviewer <harness/model/effort, family>; merger <orchestrator | harness/model>; researchers <harness/model>; cap <n> coders
- Standing authorization (G2): <what the loop may do without asking — e.g. create issues and labels, push heimdall/* branches, open PRs, merge approved PRs into <integration branch>, close tickets, revert a breaking merge with a new commit>. Not authorized: <force-push, merge or push to the default branch (if not the integration branch), deploy, tag, publish, delete non-Heimdall branches, change repo settings, spend money>.
- Framework: <none — Heimdall runs TDD, tickets, and review itself | superpowers | compound-engineering | mattpocock-skills (optional entry points, framework-capability-map.md)>

## ARCH  <!-- G2 -->
### Components and data flow
<5–15 lines; no code>

### Module map
| Module | Path globs | Public interface (seam) | Tests at |
|---|---|---|---|
| <booking> | `src/booking/**` | <BookingService: book, cancel, listForUser> | `src/booking/**/*.test.ts` |

### Hotspot plan
<!-- merge-protocol.md, L1: how each shared resource is kept conflict-free -->
- deps: <all foreseeable dependencies added in T01; later additions hold the `deps` hotspot>
- schema: <timestamp-named migrations | numbered by the merger>
- registries: <file-system routing | glob import of features/*/register.ts | `registry:<name>` hotspot>
- changelog: <fragments in changes/<ticket>.md | generated from commits>
- generated files: <not committed | regenerated after merge with <command>>
- formatting: <formatter config in T01; format touched files only>

### Commands
- Install: `<…>`   Dev / run: `<…>`   Build: `<…>`
- One test file: `<…>`   Full suite: `<…>`   Type-check: `<…>`   Lint / format: `<…>`   End-to-end: `<…>`

### Deployment and environments
<environments, hosting, CI>

### Configuration and secrets
<!-- names only, e.g. STRIPE_SECRET_KEY in .env (see .env.example) — never values -->

## Testing Decisions  <!-- G2, signed off with the user -->
- Good test here: behavior through public interfaces; names in Glossary terms; doubles only at system boundaries.
| Seam | Module | Test type | Boundary doubles |
|---|---|---|---|
| <BookingService API> | booking | <integration (real test DB in a podman container)> | <payment client, clock> |

## Standards
<repo standards files to follow (CONTRIBUTING.md, CODING_STANDARDS.md, AGENTS.md); conventions decided at G2>

## Design Contract  <!-- UI-bearing builds; G2.5 -->
<palette, type feel, density, layout; the chosen mockup, e.g. .heimdall/design/option-b.html; the confirmed prototype, .heimdall/design/prototype/index.html, and its screens>

## Ticket Graph  <!-- G3; the tracker holds the tickets themselves -->
| Wave | Tickets (T<nn> → #<issue>) | Notes |
|---|---|---|
| 1 | T01 → #<n> scaffold | blocks everything |
| 2 | T02, T03, T04 | parallel; disjoint touch sets |

## Constraints
<performance, compliance, budget, platform, accessibility, licensing>

## Open Questions
<ONLY what is genuinely undecided. "none" when empty.>
