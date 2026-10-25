# Workflow Stages — Standard Pipeline

## Contents

- When this pipeline runs
- Stage 1 Intent Parser · 1.5 Complexity Classifier
- Stages 2–4 Requirements, Context, Gaps
- Stage 5 Knowledge Advisor · Stage 6 Clarification
- Stage 7 Workflow Planner · 7.5 Existing-Codebase Rule
- Stages 8–10 Model Selector, Prompt Architect, Optimizer
- Stage 11 Instruction Layers · Stages 12–14 Critic, Refiner, Validator
- Stage 15 Delivery

## When this pipeline runs

Run after calibration (calibration.md) for every request. The pipeline does two jobs:

1. **Routing** (Stages 1–7, always): classify the request and pick the mode — Build, Direct, or Prompt (SKILL.md).
2. **Prompt construction** (Stages 8–15): builds an optimized prompt. Runs in **Prompt mode** (the user wants a prompt for some model or tool), and inside **Build mode** to write every coder, reviewer, merger, and researcher packet.

Stages 1–4 and 8–13 happen in your reasoning; Stages 5, 6, and 15 are user-facing. On a **Light-tier** orchestrator profile: merge Stages 1–4 into one pass, apply the checklist mechanically, and skip Stages 12–13.

## Stage 1 — Intent Parser

Classify: task type (coding / writing / analysis / research / agentic / creative / data / document creation / other), scope (one-shot, multi-step, recurring workflow), and deliverable (what "done" looks like).

## Stage 1.5 — Complexity Classifier

Assign exactly one class using countable signals — number of distinct components or screens, integrations, UI presence, greenfield vs existing code, estimable ticket count, knowledge gaps that need research. State the class and a one-line justification to the user; the class drives all downstream sizing.

| Class | Signals | Drives |
|---|---|---|
| **C0 Trivial** | one localized change, one component, existing code | Direct mode (or a tight prompt in Prompt mode); Light tier; no interview beyond intent; no gates |
| **C1 Simple** | single deliverable, one session, one ticket at most (a doc, a script, a small feature) | Direct mode or Prompt mode; Standard tier; bounded interview |
| **C2 Multi-step** | 2+ dependent phases OR heavy context, but one deliverable (feature refactor, research + draft) | Build-lite for software (1–3 tickets, combined G1+G2 sign-off, cap 1 — production-orchestrator.md, section 3); decomposed sessions with hand-off artifacts in Prompt mode for non-software work |
| **C3 Orchestrated** | an application or feature set from an idea or SRS, several tickets, ship intent | Build mode, gates G0–G7 (production-orchestrator.md) with the multi-agent build loop (execution-loop.md); per-ticket tier assignment |

Border rules: bugs are C0/C1 regardless of app size (scope = the fix). Ship intent without several tickets = C1/C2, not C3. An SRS for a whole application is C3. When torn between classes, pick the LOWER and say so — under-processing is recoverable; over-processing wastes the user's time and quota (over-engineering is a failure at every level). Reclassify openly if scope grows mid-flow (a C2 that reveals many tickets → propose C3 entry; never drift into it).

## Stage 2 — Requirement Extractor

Extract everything explicitly stated: goals, constraints, format, audience, tone, available inputs, target model, and execution surface (chat app, chat project, API, coding-agent harness such as Claude Code / Codex CLI / Muse Code / OpenCode / pi, or an agentic system).

## Stage 3 — Context Assessor

Determine what context the deliverable needs versus what exists: domain background, reference documents, output examples, definitions, success criteria. In an agent profile, check the workspace first (README, AGENTS.md, CLAUDE.md, existing `.heimdall/`) before asking the user.

## Stage 4 — Gap Detector

Score the information against the checklist (checklist-and-grading.md). Mark items: satisfied / inferable / missing-critical / missing-optional.

**Classify every missing-critical gap by type:**

- **Preference gap** — the user knows the answer but hasn't stated it (tone, deadline, format). Route to Stage 6.
- **Knowledge gap** — the user cannot answer because they lack the knowledge to decide ("which tech stack?" from someone who doesn't know what a stack implies). Route to Stage 5 FIRST.

Signals of a knowledge gap: "I don't know," "you decide," vague answers to concrete questions, an idea-stage request ("I want to build an app") with no constraints attached.

**UI/visual gaps are a special class:** never resolve them with more interview questions — words underspecify visuals. Use reference-based elicitation ("name 2–3 apps whose look you like", or offer 3–4 named style directions), and for orchestrated builds route to the G2.5 visual-direction gate. Unresolved UI direction on a UI-bearing build caps the grade at B.

## Stage 5 — Knowledge Advisor (conditional, user-facing)

Triggered by knowledge gaps. Full procedure: research-advisor-playbook.md. In Build mode, proactive research (project-research.md) runs first and often closes the gap before the user is asked. Summary: adopt advisor stance, tell the user which decisions need understanding they don't yet have, and offer the two research pathways. Do not build around a knowledge gap the user hasn't closed or explicitly delegated ("you pick") — and if delegated, the grade caps at C.

## Stage 6 — Clarification Agent (conditional, user-facing)

**Questioning is DERIVED, never improvised.** Questions map 1:1 from unmet critical items in the active decision set (Prompt mode: the checklist's critical items; Build mode: the current gate's decision set — G1 problem/users/stories/success/out-of-scope/mode, G2 architecture/seams/tracker/topology/authorization, G3 ticket granularity and edges) minus everything already in Settled Decisions or answered. Empty remainder = zero questions. Because questions come from templates, interview quality does not depend on the model; smaller models cut synthesis and critique, never the question derivation.

Task-type templates: bug → reproduction set; UI → references or mockups, never verbal descriptions; refactor → intent + risk tolerance + scope boundary; content → audience and tone; greenfield → scope and success.

**Ask-once invariant:** no question is asked twice per build. Settled Decisions and prior answers are the interview's memory; re-asking is a defect.

Bounds (preference gaps only):

- Max 4 questions per round; max 2 rounds; hard stop after.
- Only missing-critical items. Never ask about inferable or missing-optional items.
- Prefer multiple-choice or yes/no. Use the harness's structured question tool when it has one (harness-adapters.md, section 2 lists them); otherwise number the options in plain text.
- **Exactly one recommended answer per question**, everywhere Heimdall asks the user anything (interviews, calibration, gates, design picks, change requests, `needs-human` items): list it first, mark it "(Recommended)", and give a one-line reason grounded in the evidence. For a yes/no question, say which answer you recommend. For a pure preference, recommend the conventional default and say that it is one. If you cannot recommend an answer because the user lacks the knowledge to choose, the item is a knowledge gap: Stage 5 and the advisor playbook first.
- Skip entirely, and say so, if the input already satisfies the checklist.
- "Just proceed" or partial answers → proceed immediately on the recommended answers for everything unanswered; list them as assumptions in Delivery (Build mode: in the gate's lock message and Settled Decisions).

Goal: a deliverable scoring ≥95% on the checklist — not a biography of the task.

## Stage 7 — Workflow Planner

FIRST, the mode decision, driven by the Stage 1.5 class and the profile (SKILL.md, "Route"):

- C3 (or C2 software) and an orchestrator tier of Standard or above → **Build mode** (production-orchestrator.md). Stages 8–14 run inside the build to write every packet; delivery follows the gate structure.
- C0/C1 inside a coding-agent harness, user wants the work done → **Direct mode**: apply Stage 7.5, state observable acceptance criteria, build test-first (tdd-protocol.md), verify, report.
- The user wants a prompt, a model recommendation, or a workflow plan → **Prompt mode**: continue below.

State which mode was chosen and why. In Prompt mode, decide and justify:

1. **Persistent workspace vs one-off chat:** recommend a persistent workspace (a chat-app Project, a repo with AGENTS.md / CLAUDE.md, a custom GPT / Gem) when the work recurs, needs knowledge files, or spans sessions. Plain chat for one-offs.
2. **Single session vs decomposition:** split when phases are independent (research → draft → review), context would bloat, or fresh context per phase reduces noise. Stay in one session when phases depend on shared conversational state.
3. **Sequencing:** if decomposed, output the session sequence — each session's purpose, its prompt, recommended model and tier, settings (web search, deep-research mode, reasoning effort, attachments), and the hand-off artifact carried to the next session.

## Stage 7.5 — Existing-Codebase Rule

For changes to an existing codebase: the CODEBASE is the source of truth for conventions. In an agent profile, you can see it — locate the relevant code, follow its patterns, naming, styling, and architecture. In a chat profile, delegate discovery to the user's coding agent inside the prompt. Never specify stack or style details you have not seen; never interview the user about things the repo answers. Interview only for INTENT (what the change should do, observably). Deliver: the change (Direct mode) or a tight prompt (Prompt mode), plus observable acceptance criteria and the framework's entry point if one is installed. If a `.heimdall/STATE.md` exists for this project, use the change-request flow or a fix ticket (production-orchestrator.md, section 7) instead.

**Bug fixes** use a different interview: elicit reproduction, not intent — (1) what happens vs what should happen, (2) steps to reproduce, (3) when it started or what changed, (4) frequency. Without reproduction steps the grade caps at C. Acceptance is automatic: the reproduction no longer reproduces AND nearby behavior is unregressed. Use the framework's debug entry point (framework-capability-map.md), not its brainstorm entry. Bugs on an orchestrated build: pre-ship = a review or QA finding; post-ship = a fix ticket through the build loop (production-orchestrator.md, section 7), never a change request. Either way, a reproducing test comes first (tdd-protocol.md, section 7).

**Escalation:** if a decision the ORCHESTRATOR must make (not just the implementation) depends on repo facts — architecture fit, refactor scope, brownfield orchestration — run G0.5 Codebase Recon (production-orchestrator.md) and plan from the Repo Report.

## Stage 8 — Model Selector

Budget rule: recommend the LOWEST capable tier — Light, Standard, or Frontier — and never default upward "to be safe." Translate the tier to a concrete model with agent-model-map.md for the harness and family that will run it. One-line reason. If the user deviates, don't argue — apply Stage 10's compensation layer.

## Stage 9 — Prompt Architect

In Build mode, start from the role's asset template (coder-packet, review-packet, merge-packet, research digest request) and fill it. Build per prompting-universal.md plus the target family's file: a clear, direct task statement with motivation; a role where useful; delimiters separating instructions, context, input, and examples in the family's preferred style; explicit output format and length; 3–5 diverse examples where consistency matters (unless the family advises zero-shot first); numbered steps where order matters; self-checkable success criteria.

## Stage 10 — Model Optimizer + Compensation Layer

Apply the target family's adjustments from `prompting-<family>.md`: reasoning or effort setting in its vocabulary, verbosity, autonomy and stopping instructions, tool-use phrasing, sampling parameters where the vendor specifies them.

If the chosen model is below the recommended tier, harden the prompt:

- Ambiguity → explicit step-by-step instructions.
- More examples (lean 5), tighter output templates.
- Implicit reasoning → explicit numbered sub-steps.
- Narrower scope per prompt (push complexity into more, smaller sessions or packets).
- Self-verification ("before you finish, check that …" with a concrete check such as running the tests).
- Label these additions as compensation so the user can strip them after upgrading.

## Stage 11 — Instruction Layer Injector

Optional appended layers; always offer the memory layer in Delivery when the target is a chat app with memory:

- **Memory opt-out:** append — "Do not record, store, or write any memory entries from this conversation. Treat this conversation as ephemeral: nothing discussed here should be saved to memory, referenced in future conversations, or used to update any profile or preference files." Tell the user that the app's temporary or incognito chat, or its memory setting, is the guaranteed mechanism; the instruction is honored but is not a technical switch.
- **Style layer:** persistent tone and format instructions.
- **Boundary layer:** "do not" constraints (no web search, no file creation, ask before assuming).

## Stage 12 — Prompt Critic

Adversarial review: would a capable colleague with no context execute this correctly? Anything ambiguous, contradictory, over-engineered, or missing? Check every checklist item. Over-engineering is a failure — simple tasks must not get bloated templates.

## Stage 13 — Prompt Refiner

Fix every Critic finding. Loop Critic → Refiner at most twice.

## Stage 14 — Prompt Validator

Score against the checklist. Threshold: **≥95% of applicable items.** Below threshold: user-information gap → back to Stage 5/6 (respecting limits); construction gap → back to the Refiner. Then assign the grade per checklist-and-grading.md. The grade measures information completeness × ambiguity impact — never construction quality.

## Stage 15 — Delivery (Prompt mode)

Output exactly:

1. **Optimized Prompt** — full prompt in a code block, copy-ready; selected layers included, unselected layers shown separately.
2. **Model Recommendation** — tier, concrete model, settings, one-line reason; if the user deviated, the compensations added and why.
3. **Workflow Plan** — persistent workspace vs chat; single vs decomposed; if decomposed: session sequence with purpose, model, settings, and hand-off artifact per session.
4. **Session Profile** — the locked harness / model / effort / budget profile this output was produced under.
5. **Grade & Checklist Score** — letter grade with one-line justification; X/Y applicable items (%); unsatisfied items named; for grades below A, exactly what would raise the grade.
6. **Assumptions Made** — everything assumed instead of asked.
7. **Suggested Follow-up Prompts** — 2–4 ready-to-paste prompts the user will likely need next.
8. **Your next steps** — the numbered block required by SKILL.md: each artifact by name and where to save it, each tool action (which app, which model, which settings), what to paste where, what to bring back, and the return path. Beginner-proof.
