# Intake — From a Vague Idea or an SRS to a Locked Spec (G0–G1)

Build mode starts here. The input is anything between one sentence ("an app for booking padel courts") and a complete Software Requirements Specification. Both paths end in the same artifact: `.heimdall/spec.md` (assets/spec.md), locked at G1.

## 1. Classify the input

| Signals | Path |
|---|---|
| Requirement IDs, numbered "shall" statements, sections such as Scope, Functional Requirements, Non-functional Requirements, Use Cases, Constraints (IEEE 830 / ISO/IEC/IEEE 29148 shapes) | **SRS path** (section 2) |
| A paragraph or less, a pitch, a list of features without acceptance criteria | **Idea path** (section 3) |
| An existing repository is the subject ("add X to this app") | Either path, plus **G0.5 recon** first (production-orchestrator.md) |
| A partial spec: user stories or a PRD without architecture | SRS path; the gap check finds what is missing |

State the path and the complexity class (workflow-stages.md, Stage 1.5) in one line each. Then start **discovery research** (project-research.md, section 1) in the background: prior art, domain rules, running costs, blockers. Its findings feed the spec's Assumptions, Non-functional Requirements, and Out of Scope, and often answer questions you would otherwise ask the user.

## 2. SRS path — ingest, normalize, gap-check

The user has already done the thinking. Respect it: ask only about gaps and contradictions.

1. **Ingest.** Read the whole document (and attachments). Keep the SRS's own requirement IDs.
2. **Normalize** into the spec template: problem, solution, users and roles, user stories (`US-<nn>`), non-functional requirements with numbers, out of scope, glossary. Every user story lists the SRS IDs it covers, and the Traceability table maps every SRS ID to stories. An SRS ID with no story is a gap; a story with no SRS ID is scope creep and needs the user's yes.
3. **Gap check** against this list and the checklist (checklist-and-grading.md):
   - each functional requirement has an observable acceptance criterion;
   - non-functional requirements are measurable ("fast" → "p95 under 300 ms at 50 concurrent users");
   - users, roles, and permissions are defined;
   - data: what is stored, retention, privacy and compliance constraints;
   - external integrations each have a named provider and a contract (API, auth method — never the secret);
   - the deployment target and environments are named;
   - terms are used consistently (one word, one meaning — the Glossary);
   - no two requirements contradict each other;
   - out of scope is explicit.
4. **Questions** only for missing-critical gaps and contradictions — at most 4 per message, at most 2 rounds, multiple choice with one recommended answer each (workflow-stages.md, Stage 6). Knowledge gaps go to research-advisor-playbook.md first. Everything else becomes a listed assumption the user can override at G1.
5. **Draft** the spec, grade it, and present it for G1.

## 3. Idea path — bounded interview plus advisor

1. **Restate** the idea in two sentences: who it is for and what changes for them.
2. **Classify the gaps** (workflow-stages.md, Stage 4): preference gaps are asked; knowledge gaps go to the advisor first (research-advisor-playbook.md); UI gaps are resolved by showing, not asking (G2.5).
3. **Interview** — derived, never improvised: the questions are the unmet critical items of the G1 decision set (problem, users, core user journeys, success criteria, scope cut, operating mode, deployment intent) minus what is already known. At most 4 per message, at most 2 rounds. Offer defaults with every question.
4. **Propose, do not extract.** For a vague idea, propose a first slice ("the smallest version a real user would use") with 5–15 user stories and an explicit out-of-scope list, and let the user cut or add. Over-scoping a vague idea is the most common failure.
5. **Draft** the spec, grade it, and present it for G1.

## 4. The spec

Use assets/spec.md. Its shape follows Matt Pocock's `to-spec` template (Problem Statement, Solution, User Stories, Implementation Decisions, Testing Decisions, Out of Scope, Further Notes) with Heimdall additions: Users and Roles, Success Criteria, Non-functional Requirements, Glossary, Traceability (SRS path), and Assumptions.

- **User stories:** `US-<nn>: As a <actor>, I want <capability>, so that <benefit>.` Each has 1–4 acceptance criteria phrased as observable actions ("open the app, book a court for tomorrow 18:00, see it under My Bookings"). Long lists are fine; they become tickets at G3.
- **Implementation Decisions:** only decisions already made (by the SRS or the user). Architecture is decided at G2.
- **Testing Decisions:** proposed seams — the public interfaces where behavior will be observed — and what counts as a good test here. Seams are confirmed at G2 together with the module map (tdd-protocol.md, section 2).
- **No file paths or code** in the spec. Exception: a prototype snippet that encodes a decision more precisely than prose (a state machine, a schema), trimmed to the decision.

## 5. G1 lock

- Present the G1 briefing (assets/briefing.md): the spec (agent profile: path and summary; chat profile: the full file), the grade, the assumptions, the operating mode recommendation (Prototype / MVP / Production), what discovery research found, and what the user will need to do or learn before G7.
- Lock requires grade A, or the user explicitly accepting a lower grade (recorded in STATE.md as an accepted risk).
- On lock: write HANDOFF v1 (assets/handoff.md) with the Settled Decisions so far, create STATE.md (assets/state.md), and — once the tracker is chosen at G2 — publish the spec as the `heimdall:spec` issue at G3.
- Later scope changes go through the change-request flow (production-orchestrator.md, section 7), never silently.
