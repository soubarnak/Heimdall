<!-- Heimdall ticket template (references/production-orchestrator.md, G3).
     Remote trackers: the title becomes the issue title; the issue body is built from this file by the tracker file's
     body builder (it drops this comment, the H1, and the Status, Claimed by, and Merged lines, so `Part of #<spec>` is
     the first line); the spec issue exists before any ticket is published. Local tracker: keep everything
     (references/tracker-local.md). No file paths (they live in HANDOFF.md's module map) and no code, except a
     decision-rich prototype snippet. -->

# T<nn>: <ticket title>

Part of #<spec issue>   <!-- remote trackers: first body line; on GitHub, --parent also links it -->

Status: ready
Kind: <feature | prefactor | bug | env | acceptance>
Covers: <US-01, US-03 | SC-2 (acceptance tickets) | none (scaffold, env, prefactor)>
Screen: <prototype screen file, e.g. .heimdall/design/prototype/today.html — UI tickets only | n/a>
Milestone: <milestone title>
Blocked by: <T03, T05 | none>
Branch: heimdall/t<nn>-<slug>   <!-- <slug>: the title in kebab-case, at most 40 characters; never changed -->
Claimed by:
Merged:

## What to build
<The end-to-end behavior this ticket makes work, from the user's perspective — a vertical slice through every layer it needs, not a layer-by-layer task list.>

## Acceptance criteria
- [ ] <observable action and result> — seam: <seam name>
- [ ] <…>
- [ ] <UI tickets: the screen matches its prototype screen in layout, flow, copy, and states; screenshot in the report>

## Seams under test
- <seam name from HANDOFF.md Testing Decisions>
<!-- Or: "TDD: n/a — <reason>" plus the verification that replaces it (scaffold, config, docs tickets). -->

## Touch set
- Modules: <module names from HANDOFF.md's module map>
- Hotspots: <deps | schema | config | registry:<name> | styles | public-api:<module> | none>

## Size and risk
Tier: <Light | Standard | Frontier>   Risk: <High | Med | Low>   Fits one fresh context: yes

## Blocked by
- <#12 — title, or "None (can start immediately)". Omit when native blocking links are set.>

## Notes
<Spec references (US-<nn>), research notes in .heimdall/research/, or a trimmed prototype snippet.>
