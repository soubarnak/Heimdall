# Project Research, Architecture Decisions, and User Briefings

Heimdall's founding principle: **it is better to serve an informed user than an uninformed one.** research-advisor-playbook.md handles the reactive case — the user cannot answer a question. This file adds the proactive case: Heimdall researches the project on its own, decides architecture with recorded evidence, and tells the user, at each gate, what was decided, what they must do, and what they should learn.

## 1. Automated research program

Research runs without being asked, at three points. In the agent profile it is done by **researcher** agents (agent-roles.md) in parallel, one question each, using the tools the harness has: documentation lookup (Context7 or the vendor's docs), web search, the repository itself, and throwaway spikes. In the chat profile, the orchestrator does what its tools allow and turns the rest into Pathway B prompts.

| When | Questions | Output |
|---|---|---|
| **G0 — discovery** (after the input is classified) | Who already solves this, and how (prior art, competitors, open-source projects to reuse)? What makes it hard (domain rules, regulation, data sensitivity)? What does it cost to run (hosting, third-party APIs, app-store fees)? What would block it (platform policies, rate limits, licensing)? | `.heimdall/research/discovery.md` — feeds the spec's Assumptions, Non-functional Requirements, and Out of Scope |
| **G2 — architecture** | For each architecture decision: the 2–4 realistic options; current versions, limits, pricing, licenses, and maintenance status (from docs, not memory); fit with the team, the deployment target, and AI coding agents' reliability with that stack; for brownfield builds, fit with the Repo Report | `.heimdall/research/<decision>.md`, one per decision, then an ADR (section 2) |
| **G3 and in the loop — ticket research** | The exact APIs a group of tickets needs (library docs for the pinned versions), tricky integrations, test-double strategy at boundaries | `.heimdall/research/<topic>.md`, pointed to from tickets and coder packets so coders implement instead of exploring |

**Spikes** answer questions documentation cannot ("can this library stream 50 MB uploads?"). A spike is a throwaway prototype in a scratch directory or worktree, time-boxed, never merged; its finding goes in the digest, and a decision-rich snippet may be quoted in a ticket.

**Digest format** (assets/research-digest.md): the question, the answer in three lines, options with evidence, sources with retrieval dates, confidence (high / medium / low), and what would change the answer. Claims that can go stale (versions, prices, limits, policies) carry a source and a date, or are marked "from training data — verify". Never put secrets or personal data in a digest.

**Budget:** research serves decisions. Research only questions whose answer changes the spec, the architecture, a ticket, or the user's actions. Tight budget: discovery at most 3 questions; G2 only the decisions the user has not already settled.

## 2. Architecture decisions (G2)

The G2 decision set: stack and key libraries, deployment target and environments, data storage, authentication, external integrations, the **module map** (names, path globs, public interfaces), the **seams** (Testing Decisions), the **hotspot plan** (merge-protocol.md, L1), the tracker and merge path, the execution topology, and CI.

For each decision that is not already settled by the SRS, the user, or the existing codebase:

1. **Research it** (section 1) and write the digest.
2. **Recommend** one option with a one-line reason, a runner-up, and the trade-off of choosing differently. Prefer boring, well-documented technology that AI coding agents handle reliably, unless a requirement rules it out.
3. **Present it** in the decision brief (section 3) as a labelled decision block (the Pathway A format: options, plain-language pros and cons, who each suits, "Your call:"). The user decides, accepts the recommendation, or delegates ("you pick" — the grade caps at C, said at the moment of delegation).
4. **Record it** as an ADR (assets/adr.md): context, decision, options considered, consequences, sources. ADRs are numbered `NNNN-<slug>.md`. Before the build loop starts, the orchestrator writes them to `docs/adr/` together with the rest of the bootstrap commit (production-orchestrator.md, G3) — no coder is running yet, so nothing can conflict. A later decision change is a new ADR that supersedes the old one, never an edit.
5. **Settle it:** one line per decision in HANDOFF.md's Settled Decisions, pointing to its ADR.

Architecture is designed for parallel agents as much as for users: deep modules with small public interfaces, discovery-based registration, and seams on the critical paths make tickets independent and testable (merge-protocol.md, tdd-protocol.md).

## 3. Briefings — what the user must decide, do, and learn

At G1, G2, and G7 (and whenever the loop stops for the user), the orchestrator writes a **briefing** (assets/briefing.md) for someone who may be doing this for the first time:

- **Decided:** what was locked, in plain language, with links to the spec and ADRs.
- **Your call:** the open decision blocks, each answerable from the block itself.
- **What you need to do:** actions only the user can take — create accounts (hosting, app stores, payment provider), buy or point a domain, obtain API keys and set them **by name** in the environment (Heimdall never sees the values), accept costs, legal steps (privacy policy, terms, licenses), install tools. Each item: why it is needed, when it blocks the build (which ticket or gate), rough cost, and the exact steps or the official link. Interactive multi-step setups (cloud accounts, CI secrets) can be scripted as a guided wizard the user runs.
- **What you should learn:** the few concepts the user needs to own the result — to judge the build, operate it, and talk to whoever maintains it later (for example: "how deployments and rollbacks work on <host>", "what a database migration is and why it needs a backup"). Each item: why it matters for this project, a 2–3 line explanation, one or two high-quality sources, and a time estimate. Keep it to what this project needs; this is not a course.
- **Risks and costs:** recurring costs, vendor limits, security and compliance exposure, accepted grade risks.
- **Your next steps:** the numbered block required by SKILL.md.

G7's briefing is the operations handover: how to run, deploy, monitor, back up, update dependencies, and roll back, plus the post-ship backlog.

## 4. Hard rules

- Research never blocks on the user without a reason: if a question can be answered by documentation or a spike, answer it.
- Every recommendation names its evidence. Stale-prone facts carry a source and a date.
- Never decide a knowledge-gap question silently. Recommend, explain, and let the user take the call (research-advisor-playbook.md, Hard rules).
- Secrets: briefings name credentials and where to set them; they never contain or request their values.
