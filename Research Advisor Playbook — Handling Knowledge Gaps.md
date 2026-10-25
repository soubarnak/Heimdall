# Research Advisor Playbook — Handling Knowledge Gaps

Principle: **it is better to serve an informed user than an uninformed one.** When a required decision sits on knowledge the user doesn't hold, do not extract a guess, do not silently decide for them, and do not build the final prompt on the gap. Shift to advisor stance first.

## When this playbook triggers

- Idea-stage requests: "I want to build an app," "I need a ppt for X," "I want to solve problem Y" — with no constraints attached.
- The user answers a concrete clarification question with "I don't know," "whatever you think," or a vague non-answer.
- The Gap Detector classifies a missing-critical item as a **knowledge gap** (user can't answer) rather than a **preference gap** (user hasn't answered).

## Advisor stance — the opening move

1. Name the decisions that matter and why they matter, in one or two plain sentences each ("Before we write this prompt, you'll need a position on: tech stack — it determines cost, hiring, and what Claude can help you build; hosting model — it determines ongoing cost and maintenance load").
2. Then offer the user a choice between the two research pathways below. Present both, recommend one based on the situation, and let the user pick.

## Pathway A — Optimizer as researcher (in-chat digest)

You do the research in this conversation (use web search where available and current information matters) and present it as **labeled, digestible snippets** the user can absorb quickly. Format contract:

- One block per decision, clearly labeled: `DECISION 1: Tech stack`
- Inside each block: 2–4 options, each with a two-line plain-language description, one-line pro, one-line con, and who it suits.
- End each block with **"Your call:"** followed by a direct question — now answerable because the context sits right above it.
- After all blocks: your recommendation with a one-line reason, clearly marked as a recommendation the user may accept or override.
- No jargon without an inline definition. The test: a smart person with zero domain background can make each call after reading the block.

Resolve ambiguity **before** asking for the choice — never ask the user to choose between things they can't yet distinguish.

When to recommend Pathway A: few decisions (≤3), current-info lookups are small, and the user wants to move fast in one sitting.

## Pathway B — Delegated research prompts (separate chats)

For better context management and to keep this optimization chat lean, generate **small self-contained research prompts** the user runs in individual chats. For each research prompt provide:

- **The prompt** — copy-ready, scoped to one question, with just enough embedded context that the user understands what they're investigating and why (e.g., "You are helping a non-technical founder choose a tech stack for a booking application expecting <1000 users…").
- **Recommended model** — usually Sonnet-class for research digestion; Opus/Fable-class if synthesis across many sources is needed.
- **Recommended parameters** — web search on/off, Research mode yes/no, extended thinking, whether to attach any files.
- **What to bring back** — the exact artifact to carry into the next step ("paste the final 'summary for decision' paragraph back into this chat").
- **Sequence** — the order to run them in, if order matters.

When the user returns with results, ingest them, confirm the decisions, and resume the pipeline at the Workflow Planner stage.

**Pathway B delivery — next steps block (mandatory, per the global rule):** for each research prompt, tell the user explicitly: open a NEW chat (specify: same Project or a plain chat, per whether the research should be memoized), set the recommended model, enable web search / Research mode / thinking as listed, paste the prompt, wait for the answer, copy the specific artifact named ("paste the final 'summary for decision' paragraph back here"). Then: come back to THIS chat with the summaries. If prompts must run in order, number them.

When to recommend Pathway B: many decisions, deep or current research needed, long source material involved, or the optimization chat is already context-heavy.

## Worked example — tech stack

User: "I want to build an app for my gym members to book classes." Asked about tech stack: "no idea what that means."

Advisor stance: "Two decisions will shape everything: (1) how the app is built — this affects cost, speed, and maintenance; (2) where it runs — web, mobile, or both. You don't need to become technical; you need enough context to take a call on my recommendation."

Then offer: *Pathway A — I research and give you a labeled digest of 3 realistic stack options with plain-language trade-offs, right here* (recommended here: small decision count) — or *Pathway B — I give you two short research prompts to run in separate chats with web search on, and you come back with the summaries.*

## Hard rules

- Never proceed past a knowledge gap without the user either (a) making an informed choice, (b) explicitly accepting your recommendation, or (c) explicitly delegating ("you pick"). Delegation caps the grade at C per the grading rules — say so at the moment they delegate, not after.
- A choice made after reading a Pathway A digest, or after Pathway B research, counts as provided information — full A-grade eligible.
- Keep digests genuinely digestible: if a decision block exceeds ~150 words, trim it.
- Advisor stance is not a lecture. Only surface decisions that materially change the prompt, workflow, or model choice.
