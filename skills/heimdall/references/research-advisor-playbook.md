# Research Advisor Playbook — Handling Knowledge Gaps

Principle: **it is better to serve an informed user than an uninformed one.** When a required decision rests on knowledge the user does not hold, do not extract a guess, do not silently decide for them, and do not build on the gap. Shift to advisor stance first.

## When this playbook triggers

- Idea-stage requests: "I want to build an app," "I need a deck for X," "I want to solve problem Y" — with no constraints attached.
- The user answers a concrete clarification question with "I don't know," "whatever you think," or a vague non-answer.
- The Gap Detector (workflow-stages.md, Stage 4) classifies a missing-critical item as a **knowledge gap** (the user can't answer) rather than a **preference gap** (the user hasn't answered yet).

## Advisor stance — the opening move

1. Name the decisions that matter and why, in one or two plain sentences each. Example: "Before we lock the plan you'll need a position on: tech stack — it decides cost, hiring, and what an AI coding agent can build reliably; hosting — it decides ongoing cost and maintenance load."
2. Offer both research pathways below. Recommend one for this situation, and let the user pick.

## Pathway A — Orchestrator as researcher (digest in this session)

You do the research now (use web search, documentation tools such as Context7, or research subagents where the harness has them) and present **labeled, digestible blocks**. Format contract:

- One block per decision, labeled: `DECISION 1: Tech stack`.
- Inside each block: 2–4 options, each with a two-line plain-language description, a one-line pro, a one-line con, and who it suits.
- End each block with **"Recommendation:"** (one option and a one-line reason) and **"Your call:"** followed by a direct question that the block above now makes answerable.
- After all blocks: one line listing your recommendations, which the user may accept together ("go with your recommendations") or override one by one.
- Define every piece of jargon inline. Test: a smart person with zero domain background can make each call after reading the block.
- Cite sources for factual claims that could be stale (prices, versions, limits). If no browsing tool is available, say so and mark such claims as "from training data, verify".

Resolve ambiguity **before** asking for the choice — never ask the user to choose between things they can't yet distinguish.

Recommend Pathway A when: few decisions (≤3), small current-information lookups, the user wants to move fast in one sitting.

**Agent profile:** save the digest to `.heimdall/research/<topic>.md` so later sessions and other models can read it. Independent decisions may be researched in parallel by subagents; merge their findings into one digest before showing the user.

## Pathway B — Delegated research prompts (separate sessions)

To keep the orchestration context lean, generate **small self-contained research prompts** the user (or a research subagent, with the user's consent) runs separately. For each prompt provide:

- **The prompt** — copy-ready, scoped to one question, with just enough embedded context ("You are helping a non-technical founder choose a tech stack for a booking app expecting <1000 users…"). Adapt it to the target model family per the matching `prompting-<family>.md`.
- **Recommended model tier** — Standard for research digestion; Frontier when synthesis across many sources is needed (concrete models: agent-model-map.md).
- **Recommended settings** — web search on/off, the vendor's deep-research mode if the user has one (named in the target family's prompting file), reasoning effort, files to attach.
- **What to bring back** — the exact artifact ("the final 'summary for decision' paragraph"). Agent profile: tell the user to save it as `.heimdall/research/<topic>.md`, or paste it back.
- **Sequence** — the order to run them in, if order matters.

When the results return, ingest them, confirm the decisions, and resume at the Workflow Planner (standard pipeline) or the current gate (orchestrator).

**Pathway B delivery — next steps (mandatory):** for each prompt tell the user exactly: open a NEW chat or session (say which app or harness), set the recommended model and settings, paste the prompt, wait for the answer, copy the named artifact, and bring it back (paste here, or save it at the named path). Number the prompts if order matters.

Recommend Pathway B when: many decisions, deep or current research needed, long source material, or the orchestration context is already heavy.

## Worked example — tech stack

User: "I want to build an app for my gym members to book classes." Asked about the stack: "no idea what that means."

Advisor stance: "Two decisions shape everything: (1) how the app is built — this affects cost, speed, and maintenance; (2) where it runs — web, mobile, or both. You don't need to become technical; you need enough context to take a call on my recommendation."

Then offer: *Pathway A — I research and give you a labeled digest of three realistic stack options with plain-language trade-offs, right here* (recommended here: small decision count) — or *Pathway B — I give you two short research prompts to run in separate sessions with web search on, and you bring back the summaries.*

## Hard rules

- Never proceed past a knowledge gap without the user either (a) making an informed choice, (b) explicitly accepting your recommendation, or (c) explicitly delegating ("you pick"). Delegation caps the grade at C (checklist-and-grading.md) — say so at the moment they delegate, not after.
- A choice made after a Pathway A digest or Pathway B research counts as provided information — full A-grade eligible.
- Keep digests digestible: if a decision block exceeds ~150 words, trim it.
- Advisor stance is not a lecture. Surface only decisions that materially change the plan, the workflow, or the model choice.
