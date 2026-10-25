# Checklist & Grading

Used at Stages 12–15 of the standard pipeline (workflow-stages.md), for every execution packet, and at every orchestrator gate lock.

## Prompt checklist (22 items)

Score the final prompt or packet against these items. Mark genuinely irrelevant items N/A; N/A items are excluded from the percentage. Validation threshold: **≥95% of applicable items satisfied.** With all 22 items applicable, one miss passes (21/22 = 95.5%) and two misses fail (20/22 = 90.9%).

"Target family" below means the model family that will execute the prompt (claude, openai, muse, deepseek, qwen, gemini, …). Its rules live in `prompting-<family>.md`; universal rules live in `prompting-universal.md`.

**Intent & clarity**

1. Task stated explicitly and unambiguously.
2. The "why" behind key constraints is included.
3. Success criteria / definition of done stated, observably.
4. Audience and purpose of the output are clear.

**Context**

5. All necessary background and domain context is included or attached (or, for coding agents, the agent is told where to discover it).
6. Input data is clearly separated from instructions, using the delimiter style the target family's guide recommends (XML tags for Claude; XML tags or Markdown sections for most other families).
7. Jargon and project-specific terms are defined or self-evident.
8. Nothing irrelevant is included (no context bloat).

**Structure**

9. A role is assigned where it improves output.
10. Multi-part prompts use consistent delimiters for instructions / context / input / examples.
11. Sequential steps are numbered where order matters.
12. Prompt length is proportionate to task complexity and to the target family's guidance (some families degrade with over-prompting — see their file).

**Output control**

13. Output format explicitly specified (structure, length, style).
14. Examples included where format or judgment consistency matters (3–5, diverse), unless the target family's guide advises zero-shot first.
15. Edge cases and failure behavior addressed ("if X is missing, do Y").

**Model & execution fit**

16. The target family's guidance (`prompting-<family>.md`) is applied.
17. Compensation additions are present if the executing model is below the recommended tier (workflow-stages.md, Stage 10).
18. Reasoning / effort setting is specified in the target family's own vocabulary where the task benefits (effort, `reasoning_effort`, thinking mode, `/think`, thinking level).
19. Scope fits comfortably in the target model's context window and the harness's compaction behavior; otherwise the work is decomposed.

**Layers & hygiene**

20. Requested instruction layers (memory opt-out / style / boundaries) are correctly appended.
21. No contradictory instructions anywhere in the prompt (several families spend reasoning reconciling contradictions, or follow the wrong one).
22. The user's intent is preserved exactly — nothing added, removed, or softened.

## Confidence grading scale

Grades apply to standard-mode prompts AND to every orchestrator gate lock (G1 and G2 require A, or an explicitly accepted risk recorded in STATE.md). Operating-mode interaction: in Prototype mode grades are ADVISORY — always reported, never blocking; MVP and Production enforce the lock rules.

The grade expresses confidence that the prompt or plan will produce the intended output on the first attempt. It measures **information completeness × ambiguity impact** — never construction quality (construction flaws are fixed by the Refiner, not graded around).

**A — Production-ready.** No ambiguity. All critical context was provided by the user, obtained by interview, or acquired by a research pathway and confirmed. Checklist ≥95%. Zero assumptions on anything that materially affects output. Expected: correct on first run; at most cosmetic iteration.

**B — Strong, minor iteration expected.** Some ambiguity remains but is unlikely to affect the output much — an unstated stylistic preference, a minor format detail, one low-impact assumption. Checklist ≥95% with soft spots. Expected: 1–2 quick iteration rounds.

**C — Significant gaps, user-declined or AI-filled.** The user refused critical clarification, said "just fill it in," declined both research pathways on a knowledge gap, or the interview limit expired with missing-critical items open — and the gaps were filled with assumptions that materially shape the output. Expected: output may miss intent; review Assumptions Made before trusting results.

**D — Foundational gaps.** The core intent itself is ambiguous (what the task even is, or what "done" means) and the user declined to clarify. The prompt is a best guess at the goal, not just the details. Expected: treat the first run as a discovery draft, not a deliverable.

## Grading rules

- Unresolved UI/visual direction on a UI-bearing deliverable caps the grade at B, even if every functional item is settled — it guarantees iteration. Resolve visually (references, G2.5 mockups), not with more questions.
- Assumptions the user explicitly confirmed count as provided information, not gaps.
- Decisions made after a Pathway A digest or Pathway B research count as provided information — full A eligible.
- Explicit delegation of a critical decision ("you pick") caps the grade at C; say so at the moment of delegation.
- Accepting a recommendation counts as an informed decision when the user saw the options first — a decision block (research-advisor-playbook.md, Pathway A) or a question with its options and recommended answer — whether they accept one at a time or all at once ("go with your recommendations"). Full A eligible. "You pick" before the options were shown is delegation (the C cap above).
- "Just proceed" on open preference questions makes them listed assumptions; grade them like any other assumption the user has not confirmed (usually B), never as delegation.
- N/A checklist items never lower a grade.
- Always name the specific missing items that cap the grade, so the user has a clear path to an A.
- Never inflate: polish does not raise a grade built on withheld information.
