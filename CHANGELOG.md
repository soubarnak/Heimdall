# Changelog

## 1.1.1 — 2026-10-26

- Every question Heimdall asks the user now carries exactly one recommended answer, listed first and marked "(Recommended)" with a one-line reason. The rule lives in workflow-stages.md, Stage 6, and covers interviews, the calibration question, gate questions, the G2.5 design pick, the G3 confirmation, change requests, and batched `needs-human` items. Advisor decision blocks end with a per-decision recommendation.
- "Just proceed" takes the recommended answers for every open question and records them as assumptions.

## 1.1.0 — 2026-10-26

- Visual progress report: `.heimdall/PROGRESS.md` (Mermaid diagrams for GitHub and Gitea) and `.heimdall/progress.html` (one offline page). It shows the gate flow, what works so far, the build graph by wave, the chosen design with its mockups and prototype screens, what was done, and the proposed next phase. Refreshed at every gate lock, after each merged wave, when the loop stops for the user, and on "Show progress"; posted as a comment on the spec issue. New templates `assets/progress-report.md` and `assets/progress-report.html`.
- Reports are styled with the IBM Carbon Design System: Mermaid in the white theme with Carbon tag colors for status; the HTML page in the white theme and g100 in dark mode.
- G2.5 now ends with a prototype: after the user picks a mockup, the chosen direction is extended to the core screens (MVP) or the core screens with empty, loading, and error states (Production), and the user confirms it. UI tickets name the prototype screen they implement.
- Calibration detects a headless Chromium or Chrome for design screenshots.
- README: a usage guide.
- INSTALL.md: the verify loop no longer exits with status 1 when the last target is absent.

### Repository (since 1.0.0)

- Repository made public.
- README opens with install instructions for agents: a harness table, one universal install command, native alternatives, and a PowerShell path for Windows.
- INSTALL.md rewritten around the universal method; private-repository steps removed.
- README shows the Build mode flow as an SVG diagram (`docs/assets/build-flow.svg`).

## 1.0.0 — 2026-10-25

First release as an Agent Skill.

- Converted the claude.ai Project knowledge bundle into one installable skill, `skills/heimdall`, with an entry point, 27 references, and 17 asset templates.
- Build mode now runs the whole flow from an idea or an SRS: intake with discovery research, spec, architecture with ADRs, ticket graph, multi-agent build loop, QA, and ship.
- Added a ticket tracker contract with implementations for GitHub (`gh`), Gitea (`tea`), and local files.
- Added the seven-layer merge-conflict prevention protocol: touch sets, hotspot locks, scaffold ticket, worktree per coder, fresh base before review, serial merger with a merge pre-check and full-suite verification.
- Added the test-first protocol (adapted from mattpocock/skills, MIT) with red-first evidence and reviewer audits.
- Added roles for researcher, scout, coder, reviewer, merger, and QA agents, with status tokens and example topologies.
- Added proactive project research, Architecture Decision Records, and user briefings (decide, do, learn).
- Made the skill harness- and model-agnostic: calibration by detection, harness adapters for 13 harnesses, prompting guides for 11 model families, and a tier-to-model map.
- Added `scripts/install.sh`, `scripts/validate.sh`, Claude Code plugin and marketplace manifests, and INSTALL.md for agent-driven installation.
