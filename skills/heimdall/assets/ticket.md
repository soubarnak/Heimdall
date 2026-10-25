<!-- Heimdall ticket template (references/execution-loop.md, G3).
     Remote trackers: the title becomes the issue title; this body becomes the issue body; status lives in labels,
     so drop the status block. Local tracker: keep the status block at the top (references/tracker-local.md).
     No file paths (they live in HANDOFF.md's module map) and no code, except a decision-rich prototype snippet. -->

# T<nn>: <ticket title>

Status: ready
Kind: <feature | prefactor | bug | env>
Milestone: <milestone title>
Blocked by: <T03, T05 | none>
Branch: heimdall/t<nn>-<slug>
Claimed by:
Merged:

Part of #<spec issue>   <!-- remote trackers; on GitHub, --parent also links it -->

## What to build
<The end-to-end behavior this ticket makes work, from the user's perspective — a vertical slice through every layer it needs, not a layer-by-layer task list.>

## Acceptance criteria
- [ ] <observable action and result> — seam: <seam name>
- [ ] <…>

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
