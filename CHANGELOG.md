# Changelog

## Unreleased

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
