# Agent-Model Map

Read at G2 (agent choice) and for every packet's model line. The optimizer recommends a CAPABILITY TIER; this file translates it to concrete models per agent. When vendors ship new models, edit this file only — no logic changes.

## Tiers

- **Light** — well-scoped, mechanical packets (config, boilerplate, small fixes)
- **Standard** — most implementation milestones
- **Frontier** — architecture, ambiguous or multi-file milestones, hard debugging
  
  ## Per-agent translation

Seed names reflect what the user reports as current (e.g. Cursor: Composer and the Grok-based first-party model, plus auto mode); verify and update this table as lineups change — the user maintains this file.

## Pinning rules

- Gated orchestration requires **pinned models per packet** — consistency is the contract. State the pin in every packet's model line.
- **Cursor auto mode:** advise OFF for standard/frontier packets (mid-milestone switching breaks consistency). Permitted on light-tier packets only, where model variance barely matters.
- If an agent cannot pin, note it in the packet and tighten the return-report acceptance checks for that milestone.
  
  ## Degradation

Agent not in the table → tier advice alone still applies ("use your medium-class model"). Never guess concrete model names for agents not listed here.
