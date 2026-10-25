# SPEC — <project-slug> — v<N> — <YYYY-MM-DD>

<!-- Written by the Heimdall orchestrator at G0–G1 (references/intake.md). Published as the heimdall:spec issue at G3.
     No file paths, no code, no secrets. Domain terms come from the Glossary. -->

Source: <idea | SRS "<title>" v<version> | PRD | existing issue #<n>>
Operating mode: <Prototype | MVP | Production>

## Problem Statement
<The problem from the user's perspective: who has it, what it costs them today.>

## Solution
<The solution from the user's perspective, in 3–6 lines.>

## Users and Roles
- <role>: <what they can do; what they must not be able to do>

## User Stories
<!-- Long list is fine; each becomes one or more tickets at G3. Acceptance criteria are observable actions. -->
- **US-01:** As a <actor>, I want <capability>, so that <benefit>. [SRS: <ids> | none]
  - <open X, do Y, see Z>
  - <…>

## Success Criteria
<!-- How the user will judge the whole build. Observable and testable. -->
1. <…>

## Non-functional Requirements
<!-- Measurable: numbers, budgets, standards. -->
- Performance: <…>
- Security and privacy: <…>
- Accessibility: <…>
- Compliance and licensing: <…>

## Implementation Decisions
<!-- Only decisions already made by the SRS or the user. Architecture is decided at G2. -->
- <…>

## Testing Decisions
<!-- What a good test is for this project, and the proposed seams (confirmed at G2 in HANDOFF.md). -->
- Good test: behavior through public interfaces; names in Glossary terms.
- Proposed seams: <public interface where behavior is observed — e.g. "booking service API", "HTTP API /bookings", "Booking page">
- Boundary doubles: <external services, time, randomness>

## Out of Scope
- <…>

## Glossary
- **<term>:** <one meaning, used consistently everywhere>

## Traceability  <!-- SRS path only -->
| SRS ID | User stories | Note |
|---|---|---|
| <FR-1> | US-01, US-02 | |

## Assumptions
<!-- Everything assumed instead of asked; the user can override any line. -->
- <…>

## Further Notes
<…>
