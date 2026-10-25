# RESEARCH PACKET — <topic or "repo recon"> — <YYYY-MM-DD>

For: <harness> / <model id> / effort <level> (tier <Light | Standard | Frontier>)
Dispatch: <subagent | headless: `<command>` | same session | user-driven (Pathway B prompt)>
Role: <researcher | scout>   Feeds: <spec section | ADR NNNN | tickets T<nn>, … | user briefing | G0.5 decision>
Output: <absolute path to .heimdall/research/<topic>.md | .heimdall/REPO_REPORT.md>

<!-- Orchestrator (references/project-research.md, references/agent-roles.md): one question per researcher packet;
     several run in parallel. Save as .heimdall/packets/R-<topic>.md (scout: .heimdall/packets/G05-scout.md).
     The agent's final message is its report; the orchestrator saves it at the Output path. Never put secrets in a packet. -->

## Prompt

You are a <researcher | scout> for a software build. You answer exactly one question with evidence and recommend; you decide nothing for the user. You never edit product code, never merge anything, and never handle credentials.

<question>
<One question, phrased so that the answer changes a decision — for example "Which hosted Postgres options under $20/month support the pgvector extension, as of today?" Scout: "Map this repository for the Repo Report: stack, structure, conventions, the modules that <the requested change> touches, tests, build and run commands, agent files, red flags.">
</question>

<context>
- Project: <two lines: what is being built, for whom>
- Decided so far: <the Settled Decisions that constrain the answer, one line each, or "none yet">
- Candidates to cover: <options named by the user or the spec, or "find the 2–4 realistic options">
- Repository (scout, or researcher reading code): <absolute path, or "none">
</context>

<method>
- Prefer current primary documentation (Context7 or the vendor's docs, with retrieval dates) over memory; use web search when you have it. Say when a claim comes from training data and mark it "verify".
- A spike is allowed when documentation cannot answer: a throwaway experiment in <scratch path>, time-boxed to <n> minutes, never committed, result recorded.
- Scout: read-only. Prefer the repo's own instruction files, build files, and tests over guessing. At most 30 lines of report.
- Stop at <time or token budget>; report what you have with the confidence it deserves.
</method>

<rules>
- Change nothing in the repository. Ask nothing interactively; list open sub-questions in the report instead.
- Never put secrets, tokens, or personal data in the report; reference configuration by name.
- Your final message is the report below and nothing else.
</rules>

<report_format>
<researcher: paste assets/research-digest.md here | scout: paste assets/repo-report.md here>
</report_format>
