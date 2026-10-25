`# Checklist & Grading`

`## Optimized Prompt Checklist (22 items)`

`Score the final prompt against these. Mark genuinely irrelevant items N/A; N/A items are excluded from the percentage. Validation threshold: **≥95% of applicable items satisfied.**`

`**Intent & clarity**`

`1. Task stated explicitly and unambiguously`

`2. The "why"/motivation behind key constraints included`

`3. Success criteria / definition of done stated`

`4. Audience and purpose of the output clear`

`**Context**`

`5. All necessary background/domain context included or attached`

`6. Input data clearly separated from instructions (XML tags)`

`7. Jargon and project-specific terms defined or self-evident`

`8. Nothing irrelevant included (no context bloat)`

`**Structure**`

`9. Role assigned where it improves output`

`10. XML tags used for multi-part prompts (instructions/context/input/examples)`

`11. Sequential steps numbered where order matters`

`12. Prompt length proportionate to task complexity (no over-engineering)`

`**Output control**`

`13. Output format explicitly specified (structure, length, style)`

`14. Examples included where format/judgment consistency matters (3–5, diverse)`

`15. Edge cases / failure behavior addressed ("if X is missing, do Y")`

`**Model & execution fit**`

`16. Model-specific guidance from project knowledge applied`

`17. Compensation additions present if using a below-recommendation model`

`18. Thinking/effort guidance included where the task benefits`

`19. Scope fits comfortably in one context window (else decomposed in workflow plan)`

`**Layers & hygiene**`

`20. Requested instruction layers (memory opt-out / style / boundaries) correctly appended`

`21. No contradictory instructions anywhere in the prompt`

`22. User's intent preserved exactly — nothing added, removed, or softened`

`## Prompt Confidence Grading Scale`

`Grades apply to standard-mode prompts AND to every orchestrator gate lock (G1, G2 require A or explicitly accepted risk recorded in STATE.md). Operating-mode interaction: in Prototype mode grades are ADVISORY — always reported, never blocking; MVP/Production enforce the lock rules.`

`The grade expresses confidence that the optimized prompt will produce the intended output on the first attempt. It measures **information completeness × ambiguity impact** — never construction quality (construction flaws are fixed by the Refiner, not graded around).`

`**A — Production-ready.** No ambiguity. All critical context provided by the user, obtained via interview, or acquired via a research pathway and confirmed. Checklist ≥95%. Zero assumptions on anything materially affecting output. Expected: correct on first run; at most cosmetic iteration.`

`**B — Strong, minor iteration expected.** Some ambiguity remains but is unlikely to significantly affect the output — an unstated stylistic preference, a minor format detail, one low-impact assumption. Checklist ≥95% with soft spots. Expected: 1–2 quick iteration rounds.`

`**C — Significant gaps, user-declined or AI-filled.** The user refused critical clarification, said "just fill it in," declined both research pathways on a knowledge gap, or the interview round limit expired with missing-critical items open — and the optimizer filled the gaps with assumptions that materially shape the output. Expected: output may miss intent; review Assumptions Made before trusting results.`

`**D — Foundational gaps.** The core intent itself is ambiguous (what the task even is, or what "done" means) and the user declined to clarify. The prompt is a best guess at the goal, not just the details. Expected: treat the first run as a discovery draft, not a deliverable.`

`**Grading rules**`

`- Unresolved UI/visual direction on a UI-bearing deliverable caps the grade at B, even if all functional items are settled — it guarantees iteration. Resolve visually (references, G2.5 mockups), not with more questions.`

`- Assumptions the user explicitly confirmed count as provided information, not gaps.`

`- Decisions made after a Pathway A digest or Pathway B research count as provided information — full A eligible.`

`- Explicit delegation of a critical decision ("you pick") caps the grade at C; state this at the moment of delegation.`

`- N/A checklist items never lower a grade.`

`- Always name the specific missing items capping the grade, so the user has a clear path to an A.`

`- Never inflate: polish does not raise a grade built on withheld information.`
