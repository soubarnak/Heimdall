# Heimdall Adaptation Report

How a Claude-only prompt bundle became a harness- and model-agnostic Agent Skill that takes an idea or an SRS to a shipped application. Written 2026-10-25 for version 1.0.0; updated 2026-10-26 for 1.1.0 (visual progress report, G2.5 prototype) 1.2.0 (loop audit, section 17), and 1.3.0 (review and live Light-tier run, section 18).

## Contents

1. Summary
2. What the original repository was
3. Requirements and how each is met
4. File mapping: original to skill
5. Architecture of the skill
6. The Build mode workflow
7. Merge-conflict prevention
8. Test-driven development
9. Research, architecture decisions, and briefings
10. Harness coverage
11. Model coverage and prompting research
12. Installation design
13. Research method and sources
14. Limits, unverified items, and risks
15. Assumptions made
16. Maintenance
17. Audit and fixes (2026-10-26)
18. Review and live Light-tier run (2026-10-26, version 1.3.0)
## 1. Summary

The original repository held eight knowledge files for a claude.ai Project. Together they made Claude act as a prompt optimizer and as a "production orchestrator" that planned software through gates and then handed copy-paste packets to a separate coding agent, with the user ferrying reports back by hand. It assumed Claude models, the claude.ai interface, and Claude plan tiers throughout.

The adaptation keeps that design's best ideas — calibration, complexity routing, decision gates, advisor stance for knowledge gaps, derived interviews, the 22-item checklist, artifact discipline, and the "Your next steps" rule — and changes what it is:

- **One installable Agent Skill** (`skills/heimdall/`) instead of loose knowledge files: a 113-line `SKILL.md` entry point, 32 references loaded on demand, 24 asset templates, and one script (`scripts/ticket-checks.sh`) copied into each project.
- **It runs the build itself.** In an agent harness, Heimdall publishes a ticket graph to GitHub issues, Gitea issues, or local files, dispatches test-first coder agents into isolated git worktrees, sends every change to a fresh-context reviewer, and lands changes through one serial merger. The user signs off at a few gates instead of relaying every packet.
- **It informs the user.** A Researcher role researches proactively at intake, architecture, and per ticket; every significant architecture choice becomes an ADR; briefings at G1, G2, and G7 say what was decided, what the user must decide, do, and learn, and what the risks and costs are.
- **It is harness- and model-agnostic.** Detection replaces the old model/plan-tier question; 13 harnesses have adapters; 11 model families have prompting guides verified against vendor documentation on 2026-10-25; a tier map turns "Light / Standard / Frontier" into concrete model ids and selection flags per harness.
- **It installs from the repository URL.** The README and INSTALL.md are written for an agent: a harness table, one universal install command, native alternatives, verification, update, and uninstall, backed by `scripts/install.sh` for every harness.

## 2. What the original repository was

Commit `d52ef48` ("Import original claude.ai Project knowledge files") contains:

| File | Lines | Role |
|---|---|---|
| Instructions.md | 52 | Project instructions: Stage 0 calibration (ask model, effort, plan tier), Standard vs Orchestrator mode, knowledge-file index, global rules |
| Workflow Stages — Standard Pipeline.md | 135 | The 15-stage prompt pipeline, Stage 1.5 complexity classifier (C0–C3), Stage 7 routing |
| Production Orchestrator — Idea to Shipment.md | 168 | Operating modes (Prototype / MVP / Production), gate levels, gates G0–G7, session budgeting for claude.ai plan limits, artifact templates (HANDOFF.md, STATE.md, packets, return reports), failure taxonomy |
| Research Advisor Playbook — Handling Knowledge Gaps.md | 59 | Advisor stance; research Pathways A (in-session) and B (delegated) |
| Checklist & Grading.md | 91 | 22-item checklist, ≥95% threshold, A–D grades |
| Framework Capability Map.md | 77 | superpowers, compound-engineering, and others as the execution layer inside the coding agent |
| Agent-Model Map.md | 23 | Light / Standard / Frontier tiers and pinning rules |
| Claude prompting guide.md | 412 | Anthropic prompting guidance, the "sole technical authority" for prompts |

How it worked: the user chatted with Claude in a claude.ai Project. For software, Claude walked gates G0–G7, emitted HANDOFF.md for the coding agent and STATE.md for the user, and wrote one execution packet per milestone. The user pasted each packet into a coding agent (usually Claude Code with superpowers), waited, and pasted the agent's return report back for review. Long builds spanned many chats, carried by STATE.md.

Defects found while reading it:

- The index named files that did not exist under those names (`workflow-stages.md` and others were stored with title-case names; `Best_prompting_Practices.md` was stored as `Claude prompting guide.md`), and it cited a `heimdall-handoff` skill that was not in the repository. The missing-file guard would fire on a literal reading.
- Everything assumed Claude: Haiku/Sonnet/Opus tiers, claude.ai plan limits, Claude-only prompting authority.
- Parallel milestones were allowed ("issued as parallel packets") with no mechanism to prevent the agents from editing the same files.
- Testing appeared only as acceptance criteria and G6 review lenses; there was no test-first discipline and no way to audit it.
- No ticket tracker: progress lived in STATE.md on the user's machine.

## 3. Requirements and how each is met

| Requirement (from the user's requests) | Where it is met |
|---|---|
| Understand the repository's purpose | Section 2 of this report |
| Adapt it into a skill that runs an idea-to-shipment workflow | `skills/heimdall/SKILL.md`; Build mode (production-orchestrator.md) |
| Harness- and model-agnostic; work with Codex/GPT, Meta Muse, and Claude models | calibration.md, harness-adapters.md, agent-model-map.md, prompting-*.md |
| Research models and prompting practices concretely with Context7 | 11 family files plus prompting-universal.md, each dated with sources (section 13) |
| Best prompting practices for Meta, Claude, ChatGPT, DeepSeek, and other agents | prompting-muse.md, prompting-claude.md, prompting-openai.md, prompting-deepseek.md, prompting-qwen.md, prompting-gemini.md, prompting-mistral.md, prompting-grok.md, prompting-kimi-glm-minimax.md |
| Account for Muse Code, Claude Code, OpenCode, and pi harnesses | harness-adapters.md sections 2–3, verified against the installed CLIs |
| Take a vague idea or a well-crafted SRS | intake.md: idea path (discovery research, derived interview) and SRS path (ingest, normalize with traceability, gap check) |
| Handle the entire flow with prompting and subagents | execution-loop.md, agent-roles.md, asset packets written per target model |
| No merge conflicts | merge-protocol.md, seven layers (section 7); the honest limit is stated |
| GitHub and Gitea issues as the progress tracker | tracker-github.md, tracker-gitea.md, tracker-local.md behind one contract (execution-loop.md, section 2) |
| Coder and reviewer agents | agent-roles.md; coder-packet, review-packet, return-report, review-report assets |
| Test-driven development modeled on Matt Pocock's skills | tdd-protocol.md (adapted from mattpocock/skills, MIT) |
| Automated research, architecture decisions, telling the user what to do or learn | project-research.md, Researcher role, assets research-digest.md, adr.md, briefing.md |
| GitHub repository "Heimdall" that an agent can install from (created private, made public on 2026-10-25 at the user's request) | this repository, README.md, INSTALL.md, scripts/install.sh, .claude-plugin/ |

## 4. File mapping: original to skill

| Original | Now | Change |
|---|---|---|
| Instructions.md | skills/heimdall/SKILL.md | Rewritten as skill entry point with spec-compliant frontmatter; three modes (Build, Direct, Prompt); index of every reference and asset; global rules generalized beyond claude.ai |
| Workflow Stages — Standard Pipeline.md | references/workflow-stages.md | Kept the 15-stage pipeline and C0–C3 classifier; "Orchestrator mode" became Build mode (C3) and Build-lite (C2); routing and bug handling updated to tickets and reproducing tests |
| Production Orchestrator — Idea to Shipment.md | references/production-orchestrator.md | Rewritten for an orchestrator that executes: `.heimdall/` runtime layout, gates G0–G7 with tracker publication and a bootstrap commit, budgeting and resume for any harness, standing authorization, podman default |
| Research Advisor Playbook | references/research-advisor-playbook.md | Kept; now complemented by proactive research (project-research.md) |
| Checklist & Grading.md | references/checklist-and-grading.md | Kept unchanged |
| Framework Capability Map.md | references/framework-capability-map.md | Demoted to optional: frameworks supply procedures inside Heimdall's roles and must never run their own orchestration |
| Agent-Model Map.md | references/agent-model-map.md | Rewritten: role defaults, family × tier model table for 11 families, per-harness selection flags |
| Claude prompting guide.md | references/prompting-claude.md | Re-verified and condensed; joined by prompting-universal.md and nine more family files |
| (none) | references/calibration.md | New: detection-first Step 0 |
| (none) | references/intake.md | New: idea path vs SRS path, spec shape, G1 lock |
| (none) | references/project-research.md | New: research program, ADRs, briefings |
| (none) | references/execution-loop.md | New: tracker contract, scheduler, dispatch, review, merge, failure routing, fallbacks |
| (none) | references/agent-roles.md | New: seven agent roles, status tokens, topologies |
| (none) | references/merge-protocol.md | New: seven-layer conflict prevention |
| (none) | references/tdd-protocol.md | New: test-first protocol and audit |
| (none) | references/tracker-github.md, tracker-gitea.md, tracker-local.md | New: tracker implementations |
| (none) | references/harness-adapters.md | New: dispatch methods and per-harness facts |
| (none) | references/prompting-universal.md and eight family files | New: cross-vendor and per-family prompting |
| Templates inside the orchestrator file | assets/ (23 files) | Extracted into fill-in templates: spec, handoff, state, decisions, briefing, research digest, ADR, repo report, setup packet, session plan, ticket, coder packet, return report, review packet, review report, merge packet, PR body |

## 5. Architecture of the skill

- **Progressive disclosure.** `SKILL.md` (frontmatter plus 104 lines) is all a harness loads at activation. It tells the agent which reference to read at which stage or gate; references and assets load only when needed. All references sit one level deep, as the Agent Skills specification recommends.
- **Two profiles.** The agent profile (shell and file tools) executes the build. The chat profile (claude.ai, ChatGPT, Meta AI without tools) runs the planning gates and emits packets for a coding agent, which preserves the original copy-paste workflow where nothing better exists.
- **Runtime state stays out of the repository.** Heimdall writes `.heimdall/` (STATE.md, HANDOFF.md, packets, reports, research digests) and adds it to `.git/info/exclude`. Durable records are the tracker (issues, PRs, labels), `docs/adr/`, and the project's `AGENTS.md`, committed once in a bootstrap commit before any coder runs, so every worktree sees them.
- **Single sources of truth.** Naming conventions — ticket ids `T<nn>`, branches `heimdall/t<nn>-<slug>`, worktrees under `../<repo>.worktrees/`, packet and report paths, `heimdall:*` labels, and the status tokens (`STATUS:`, `VERDICT:`, `MERGE:`, `RESEARCH:`) — are defined once and cited elsewhere.

## 6. The Build mode workflow

| Gate | What happens | Sign-off |
|---|---|---|
| G0 Intake | Classify the input (idea, PRD, SRS); discovery research; bounded interview (at most 4 questions per message, 2 rounds, one recommended answer per question) or SRS gap check | — |
| G0.5 Recon | Brownfield only: a Scout maps the existing codebase into a repo report | — |
| G1 Spec | Spec locked from assets/spec.md with user stories, success criteria, NFRs, testing decisions, traceability to SRS ids; operating mode chosen; briefing | Mandatory |
| G2 Architecture | Researched options, ADRs, module map planned for parallel work, hotspot plan, test seams, tracker choice, integration branch, agent topology (which harness and model per role), standing authorization for routine outward actions; briefing | Mandatory |
| G2.5 Visual direction | UI builds: 2–3 mockups, the user's pick, a prototype of the core screens, design contract | Recommended |
| G3 Ticket graph | Vertical-slice tickets with acceptance criteria, seams, touch sets, hotspot locks, size and risk, blocking edges; published to the tracker; bootstrap commit | Recommended |
| G4–G5 Build loop | Scheduler: sync, collect reports, merge approved work, compute the frontier (ready, unblocked, disjoint touch sets and hotspots), order by critical path, dispatch up to the concurrency cap (default 3), checkpoint | Informational |
| G6 QA | Whole-build review, QA agent, fixes as new tickets | Mandatory in Production |
| G7 Ship | Release against the locked deployment target; operations handover briefing | Mandatory |

Per ticket: the orchestrator creates the worktree and branch from the integration tip and writes the coder packet for the executing model; the coder works test-first and returns a report with a status token; the orchestrator validates the report, pushes, and opens a PR (`Closes #n`); a reviewer in a fresh context — never the coder, a different model family when available — audits on five independent axes (Spec, Standards, TDD audit, Security, Scope) and returns a verdict, with at most two review fix rounds before escalation (rounds that repair another ticket's merge do not count); the merger lands it. Before review, the orchestrator runs the mechanical ticket checks (`ticket-checks.sh`): head, clean tree, base sync, scope, lockfile drift, commit order, red-at-base. Failures route by cause (touch-set, seam, spec, environment, dependency, secret, destructive) to the right party; nothing asks the user from inside a subagent.

From G1 on, a visual progress report (`.heimdall/PROGRESS.md` with Mermaid diagrams; `.heimdall/progress.html` at G2.5, G7, and on request) shows the gate flow, what works so far, the build graph, the chosen design with its prototype, what was done, the proposed next phase, and after the demo checkpoint how to try the application. It is styled with the IBM Carbon Design System, refreshed at gate locks, merged waves, and loop stops, and from G3 on posted as one comment on the spec issue that is edited in place.

The merge path is a pull request by default when a remote tracker exists, or a local squash merge when the user requires approval for every push. Own-PR approval is impossible under one account on GitHub and Gitea, so verdicts are recorded as a comment plus a label.

## 7. Merge-conflict prevention

merge-protocol.md defines seven layers:

1. **Architecture for parallelism (G2):** module boundaries that match tickets; discovery registries or file-per-entry patterns instead of shared lists; per-ticket migration files; generated files regenerated, never hand-merged; one formatter configuration.
2. **Scaffold ticket T01:** lands shared structure, tooling, and the test commands before parallel work starts.
3. **Touch sets and hotspot locks:** every ticket declares the files and directories it may change, and claims named hotspots (`deps`, `schema`, `config`, `registry:<name>`, `styles`, `public-api:<module>`). The scheduler never runs two tickets with overlapping touch sets or the same hotspot.
4. **Worktree isolation:** one git worktree and branch per ticket, outside the repository.
5. **Fresh base before review:** the coder syncs with the integration tip and reruns the suite.
6. **Serial merger:** one merge at a time, guarded by the expected head SHA, preceded by a `git merge-tree --write-tree` dry run, followed by the full suite on the merged result before it lands.
7. **Conflict table:** mechanical conflicts are fixed by the merger, trivial adjacency is resolved with a check, semantic and design conflicts go back to a coder or to the user.

What this does and does not promise: conflicts become rare and mechanical. They are not impossible — two tickets can still interact through behavior rather than text. Semantic conflicts are caught by the full suite on every merged result before it lands. The skill instructs agents never to claim "zero conflicts guaranteed".

## 8. Test-driven development

tdd-protocol.md adapts Matt Pocock's `tdd` skill (mattpocock/skills, MIT; see THIRD_PARTY_NOTICES.md):

- Tests verify behavior through public interfaces; one logical assertion; domain vocabulary; expected values from an independent source.
- Seams are proposed in the spec and **locked at G2** with the user; tickets name the seams they test; a coder that needs a new seam stops with `BLOCKED: seam`.
- Rejected anti-patterns: implementation-coupled tests, tautological tests, horizontal slicing.
- Mocks only at system boundaries, with dependency injection and SDK-style interfaces.
- The loop: one test, red for the right reason, minimal green, commit, next behavior; refactoring happens in review rounds with the suite green before and after.
- **Red-first evidence** that reviewers audit: a `test(T<nn>)` commit before the `feat(T<nn>)` commit (or one commit with the red output quoted), and a criterion → test → red message → green table in the report.
- **Red-at-base check:** the orchestrator's ticket checks run the ticket's new tests against the base code in a scratch worktree and expect failures; the reviewer judges the output. Every feature and bug ticket in MVP and Production; skipped in Prototype mode and for tickets without behavior to drive.
- **Acceptance tests:** one end-to-end test per Success Criterion, each its own ticket after the implementing tickets; G6 runs them first.
- Special cases: scaffold and docs tickets (`TDD: n/a` with a named verification), characterization tests before changing untested legacy code, expand–contract for wide refactors, UI tests at component seams, and a relaxed Prototype option.

## 9. Research, architecture decisions, and briefings

This answers the question "does it cover automated research, architectural decisions, and telling the user what needs to be done or learned?"

- **Research program (project-research.md).** G0 discovery research (domain, comparable products, regulations, constraints); G2 architecture research (stack and hosting options against the spec's NFRs); per-ticket research when an executor faces an unfamiliar library or API. Researchers prefer current primary documentation through Context7 where available, then official sites, then the repository; they run small spikes when reading cannot settle a question. Output is a research digest with sources and dates, beginning with `RESEARCH: DONE`. Budget caps keep research proportional.
- **Architecture decisions.** Each significant G2 choice follows: research, recommend (with evidence), present options and trade-offs, user decides, record an ADR (`docs/adr/NNNN-<slug>.md`), and record it in Settled Decisions. ADRs land in the bootstrap commit so every coder reads them.
- **Briefings (assets/briefing.md)** at G1, G2, and G7: Decided; Your call; What you need to do (accounts, keys, domains, payments — secrets referenced by name only); What you should learn to own the result; Risks and costs; Your next steps. G7's briefing is the operations handover (running, monitoring, updating, backing up).
- **Advisor stance** remains from the original playbook: when a decision rests on knowledge the user lacks, Heimdall explains before asking.

## 10. Harness coverage

harness-adapters.md and the per-harness files it routes to (harness-claude-code.md, harness-codex.md, harness-muse-code.md, harness-others.md) were verified on 2026-10-25 and 2026-10-26 against vendor documentation and the locally installed CLIs (Claude Code 2.1.310, Codex CLI 0.163.0, Muse Code 1.4.13, OpenCode 2.1.4, pi 1.4.0, Antigravity CLI 1.4.6).

| Harness | Skill folder (user) | Dispatch | Question tool |
|---|---|---|---|
| Claude Code | `~/.claude/skills/` or plugin | subagents (`.claude/agents/*.md`, Agent tool); headless `claude -p` | `AskUserQuestion` |
| Codex CLI | `~/.agents/skills/` | subagents (`spawn_agent`); headless `codex exec` | none documented |
| Muse Code | `~/.agents/skills/` | native subagents; headless `muse exec` | `request_user_input` |
| OpenCode | `~/.agents/skills/`, `~/.config/opencode/skills/` | subagents (`.opencode/agents/`); headless `opencode run` | `question` |
| pi | `~/.agents/skills/` | same session (subagents via an optional package); headless `pi -p` | `ask_question` |
| Gemini CLI | `~/.agents/skills/`, `~/.gemini/skills/` | subagents (`.gemini/agents/`) | UNVERIFIED |
| Antigravity CLI | UNVERIFIED; install into `~/.agents/skills/` | headless `agy -p` | UNVERIFIED |
| Qwen Code | `~/.qwen/skills/` | same session or user-driven (subagents and headless flags UNVERIFIED) | UNVERIFIED |
| Mistral Vibe | `~/.agents/skills/`, `~/.vibe/skills/` | headless `vibe --prompt` with an explicit `--agent` | `ask_user_question` |
| Grok Build | `~/.agents/skills/`, `~/.grok/skills/` | Agent Client Protocol | UNVERIFIED |
| Kimi Code CLI | `~/.agents/skills/` | same session or user-driven (subagents and headless flags UNVERIFIED) | UNVERIFIED |
| Cursor | `~/.agents/skills/`, `~/.cursor/skills/` | subagents (`.cursor/agents/`) or user-driven | UNVERIFIED |
| GitHub Copilot | `~/.agents/skills/`, `~/.copilot/skills/` | user-driven | UNVERIFIED |

Consequences built into the design:

- One copy in `~/.agents/skills/heimdall` serves every harness except Claude Code and Qwen Code; the installer adds those two folders.
- Claude Code reads `AGENTS.md` only when no `CLAUDE.md` exists, so Heimdall writes a `CLAUDE.md` containing `@AGENTS.md` in projects it builds (this repository does the same).
- Subagents and headless runs cannot ask the user questions in any harness, so gates always run in the orchestrating session and packets tell executors to stop and report.
- Permission-bypass flags are never passed unless the user asks for that run. Headless dispatch to another vendor's CLI requires the user's consent because it spends that vendor's quota.
- Calibration detects the harness from its tools (and `CLAUDECODE=1` in Claude Code) instead of asking.

## 11. Model coverage and prompting research

Heimdall plans in tiers — Light, Standard, Frontier — and agent-model-map.md translates tiers into concrete models. Role defaults: Orchestrator Frontier (Standard acceptable); Researcher Standard; Scout Light; Coder per ticket; Reviewer Standard (Frontier for High-risk tickets in Production); Merger Standard; QA Standard. A Light-tier model does not orchestrate Build mode.

| Family | Frontier | Standard | Light |
|---|---|---|---|
| Anthropic Claude | `claude-opus-5-5`; `claude-fable-5-1` for the hardest work | `claude-sonnet-5-5` | `claude-haiku-5-5` |
| OpenAI GPT | `gpt-6-astra` | `gpt-6.1-sol` | `gpt-6-luna` |
| Meta Muse | `muse-wonder-1.0` | `muse-spark-1.3` | `muse-spark-1.3` at low effort |
| DeepSeek | `deepseek-v4-pro` | `deepseek-flash` | `deepseek-flash` at low effort |
| Qwen | Qwen3.8 Max | Qwen3.8 Plus, Qwen3-Coder, Qwen3.8-27B | Qwen3.8-Flash-Next |
| Google Gemini | `gemini-4-argon` | `gemini-3.8-flash` | `gemini-3.5-flash-lite` |
| Mistral | `mistral-large-4-0` (UNVERIFIED) | `mistral-medium-latest` | `mistral-small-latest` |
| xAI Grok | `grok-4.7` | `grok-4.3` | `grok-build-0.1` |
| Moonshot Kimi | `kimi-k3` | `kimi-k2.7-code` | `kimi-k2.6` |
| Zhipu GLM | `glm-5.3` | `glm-5.2` | `glm-5.3-flash` |
| MiniMax | `MiniMax-M3` | `MiniMax-M3.1-Flash` | `MiniMax-M3.1-Flash` at low effort |

Key prompting findings that shape packets (full detail and sources in each family file):

- **Universal (prompting-universal.md):** state the goal and the reason; one delimiter style; rules first, data in the middle, the ask last; do not over-prompt reasoning models (no "think step by step" boilerplate); explicit autonomy, stopping, and verification rules for agents; a per-family effort vocabulary; set sampling only where the vendor asks for it.
- **Claude:** XML-tagged packet sections; start at the model's default effort (Opus medium, Sonnet high, Haiku medium); Haiku only for Light packets with explicit finish-and-verify instructions; Claude Code skill frontmatter extensions are not portable, so Heimdall does not depend on them.
- **OpenAI GPT and Codex:** lean packets (no "make a plan first" or status-update lines in Codex); state autonomy explicitly to counter GPT-6's tendency to ask; scope verification so small packets do not over-test; effort via `model_reasoning_effort`.
- **Meta Muse:** order packets objective, rules, numbered procedure, tools note, exact report format, completion rule; effort vocabulary differs by surface; Standard runs at `high` (the Muse Code default); never `none`; Glimmer makes one tool call per turn, so packets for it are smaller and carry compensation.
- **DeepSeek:** Pro at `high` for Frontier, `max` only for hard debugging; Flash for Standard and Light with compensation; Claude-specific features are inert when DeepSeek runs inside Claude Code.
- **Qwen:** thinking on by default; open-weights deployments need the vendor's sampling settings set explicitly; small models get numbered sub-steps and one concern per packet; repeat the report format at the end of the user turn.
- **Gemini:** rules and report format first, data in the middle, ask last; never lower temperature for "determinism"; preserve thought signatures in tool loops; add `AGENTS.md` to Gemini CLI's `context.fileName`.
- **Mistral:** `mistral-medium-latest` at high reasoning effort is the documented recommendation; Devstral API models are retired; headless Vibe always gets an explicit `--agent`.
- **Grok:** a detailed, stable, cacheable system block first; full context in the first message; never rewrite earlier turns.
- **Kimi, GLM, MiniMax:** usually run inside another harness through compatible endpoints; never send sampling parameters; set `high` effort explicitly because defaults are often `max`; record the effective model because the host UI shows its own slot names.

## 12. Installation design

- **Agent Skills specification:** `name` equals the directory name (`heimdall`), description 949 of 1024 characters, compatibility 248 of 500, `metadata` values are strings, body under 500 lines. `scripts/validate.sh` checks all of this.
- **Install paths:** the universal method, `git clone` plus `scripts/install.sh --harness <name>`, works in every harness that runs bash and is the default the README gives agents; native alternatives are the Claude Code plugin marketplace (this repository is its own marketplace), the Skills CLI (`npx skills add soubarnak/Heimdall`), `muse skills install` from a clone, `pi install git:…`, `gemini skills install`, and Codex `$skill-installer`. Windows without bash gets a PowerShell copy snippet.
- **scripts/install.sh** links (user scope) or copies (project scope) the skill into `~/.agents/skills`, `~/.claude/skills`, and `~/.qwen/skills` (or the project equivalents, plus `.grok/skills`), detects harnesses on `PATH`, refuses to overwrite directories it did not create without `--force`, and supports `--dry-run` and `--uninstall`.
- **Public repository:** installs need no credentials. Tracker operations use the user's own `gh` or `tea` sign-in, and the skill never handles tokens.

## 13. Research method and sources

- **Context7** was the primary source for library and vendor documentation (for example `/vercel-labs/skills`, `/websites/api-docs_deepseek`, `/websites/ai_google_dev_gemini-api`, `/google-gemini/gemini-cli`, `/mistralai/platform-docs-public`, `/websites/x_ai`, `/websites/platform_kimi_ai`, `/moonshotai/kimi-k2.5`). Each family file lists its Context7 ids and URLs under "Sources".
- **Official pages** where Context7 lacked coverage: platform.claude.com and code.claude.com; developers.openai.com and the openai-cookbook; dev.meta.ai (Muse model cards and prompting pages); docs.gitea.com; agentskills.io and agents.md.
- **Local CLIs** for harness facts: `--help` output and behavior of Claude Code, Codex CLI, Muse Code, OpenCode, pi, and Antigravity CLI; `gh` 2.103.1 and `tea` 0.16.0 against Gitea 1.27.1 for tracker commands; `claude plugin validate` and `muse skills validate` against this repository.
- **mattpocock/skills 1.3.1** (installed locally) for the TDD, spec, ticket, and review patterns.
- Every verified file carries "Verified 2026-10-25 against …" on its third line. Facts from third-party summaries only are marked UNVERIFIED.

## 14. Limits, unverified items, and risks

Limits by design:

- Merge conflicts are prevented by construction, not guaranteed absent (section 7).
- A Light-tier model cannot run the planning gates (G0–G3) or G6–G7. It may run the build loop of an already-planned build under the Light-tier conditions (production-orchestrator.md, section 3), and the resume protocol applies that rule to the model actually running.
- Chat apps without tools cannot run the build loop; they run the planning gates and hand off.
- Reviews by "a different model family" depend on the user having access to more than one vendor; otherwise a fresh-context reviewer of the same family is used.
- Own-PR approval is impossible under one account, so tracker verdicts are comments plus labels, not formal approvals.

Unverified (marked in the files):

- Antigravity CLI skill folders and instruction file; question tools for Gemini CLI, Qwen Code, Grok Build, Kimi Code CLI, Cursor, and GitHub Copilot; pi's `ask_question` behavior.
- The exact argument form of Codex's `$skill-installer`; the PowerShell install snippet has not been run on Windows.
- Grok Build headless flags (Agent Client Protocol is the official route) and the grok-code-fast guide wording.
- Mistral Large 4 model id details (model card returned 404) and per-model `xhigh` support; Qwen3.8 `reasoning_effort` values beyond the Hugging Face card.

Risks to watch:

- Model names and harness flags change quickly. agent-model-map.md, the family files, harness-adapters.md, and the per-harness files are the only places to update; no logic depends on specific names.
- GitHub issue dependencies and Gitea dependencies can be disabled per instance or repository; the tracker files define a body-section fallback and record which representation is in use.
- Parallel coders multiply cost. The concurrency cap defaults to 3 and calibration asks about budget when it cannot infer it.

## 15. Assumptions made

- **License:** MIT, "Copyright (c) 2026 soubarnak", chosen to match the MIT-licensed material adapted from mattpocock/skills. Change LICENSE if a different license is wanted.
- **Author and repository:** `soubarnak`, `https://github.com/soubarnak/Heimdall`, recorded in SKILL.md metadata and the plugin manifests.
- **Defaults:** concurrency cap 3; worktree root `../<repo>.worktrees`; pull-request merge path when a remote tracker exists; MVP operating mode unless the user picks another at G1.

## 16. Maintenance

- Run `scripts/validate.sh` before every commit; it checks the frontmatter, index coverage (references, assets, scripts), one-level-deep folders, dangling references and paths, the plugin manifests, a CHANGELOG entry for the current version, and common secret shapes, and runs `claude plugin validate` and `muse skills validate` when those CLIs exist.
- When a vendor ships new models, edit agent-model-map.md and that family's prompting file, and update the verification date.
- When a harness changes its skill folders or flags, edit harness-adapters.md (skill folders), the harness's own file (flags and grants), INSTALL.md, and scripts/install.sh together.
- `skills/heimdall/scripts/ticket-checks.sh` runs in user projects on any stack: keep it to bash, git, and coreutils; check it with `bash -n` and `shellcheck`; and test a change against a real ticket (a PASS case and each failure code) before release. Its codes and their routes are a contract with execution-loop.md, section 5, step 6, and loop-card.md.
- Keep `metadata.version` in SKILL.md and `version` in `.claude-plugin/plugin.json` equal, and record each release in CHANGELOG.md.

## 17. Audit and fixes (2026-10-26)

Version 1.2.0 followed an audit of the skill against its desired result (idea or SRS → shipped application through gated, tracker-visible, test-first, conflict-free multi-agent work, with research, ADRs, briefings, a visual progress report, a confirmed prototype, and one recommended answer per question). Three checks ran: a numbered-section cross-reference check (clean), a fresh-context review of the build loop that walked one ticket through GitHub with `pr`, local with `local`, and Gitea with a headless coder, and a live dry run of the installed skill from G0 to G3 in a scratch repository (`claude -p`, Sonnet, offline, local tracker).

Findings that blocked a ticket on GitHub or Gitea: the integration branch was never pushed, so no PR could target it; fix rounds never pushed, so reviews approved unpushed heads and the merge guard failed; headless coders could not commit (`acceptEdits` alone denies shell commands in `-p` mode, verified on Claude Code 2.1.310; Codex `workspace-write` confines writes to the worktree while a linked worktree commits into the main checkout's `.git`). Findings that made agents diverge: the review base SHA was undefined; the merger's update step contradicted the SHA guard; `git worktree add -b` failed on retries; no command produced the merge SHA; hotspots had no path mapping; lock release and the cap were undefined. Ambiguities: several status transitions had no trigger or command, slug and round were undefined, `STATUS: FAILED` and `VERDICT: STALE` had no route, branch deletion commands conflicted, `.heimdall/packets/` was never created, draft PRs had no trigger, the red-at-base check ignored dependency installation.

The dry run produced every artifact (spec, HANDOFF, STATE, briefings, research, three mockups, a prototype, nine tickets, five ADRs, AGENTS.md, the progress report) but locked G1 and G2 "provisionally" on a blanket "run the gates" instruction and committed the bootstrap before the G3 confirmation. The gate-level rule now defines what counts as a sign-off.

Design gaps closed at the same time: no single source for user story → ticket coverage (the progress report's "What works so far" had no input), no prototype pointer in tickets or packets, no templates for the G6 packets, the researcher and scout packets, the chat-to-agent kickoff, or the bootstrap AGENTS.md, and a grading rule that could cap an accepted recommendation at C. A second fresh-context review of the revised files confirmed 23 of the 24 items closed and raised 15 smaller ones (ticket body publication, reviewer permissions for the red-at-base check, dependency installation in fresh worktrees, the return route after a semantic conflict or a reverted merge, merge path `local` with a remote tracker, resume crash windows); all are closed in the same release. A second live run resumed the scratch build with the revised skill and took T01 through coder, review with the red-at-base check, squash merge, close, and a refreshed progress report on the local path. Sections 6, 7, and 8 describe the resulting protocol; CHANGELOG.md lists every change.

## 18. Review and live Light-tier run (2026-10-26, version 1.3.0)

A live run resumed the scratch build with Haiku as orchestrator (Light tier), a headless Sonnet coder, and a headless Opus reviewer, and took ticket T02 through the whole loop on the local path. The loop worked, but the Light-tier rule never fired: calibration skipped detection on resume, so STATE.md kept the previous Standard-tier orchestrator, the old Heimdall version, and the old ticket-table shape. Haiku also misread the commit order and flagged a false TDD violation that the reviewer corrected, the reviewer choice came from the user's own instruction file rather than from Heimdall's rule, and the progress report said "0 waiting on you" above three waiting items. A full review of the skill then listed 25 items: 8 fixes, 9 gaps, and 8 improvements.

Decisions:

- **Mechanical checks move out of model judgement.** Head, clean tree, base sync, scope, lockfile drift, commit order, and red-at-base are deterministic, so a script does them (`ticket-checks.sh`), run by the orchestrator before review. A Light-tier orchestrator no longer has to read `git log` order correctly, and reviewers need no script grant: they read the report and judge only what needs judgement (whether a red failure is real, whether a `NO-RED` result is a characterization test). The script stays bash with git and coreutils because it runs in user projects on any stack, and it is copied into `.heimdall/` because headless agents and later sessions cannot rely on the skill's install path.
- **Round cap counts only review verdicts.** Version 1.2.0 counted fix rounds caused by merge failures toward the cap of 2. That punished a ticket for another ticket's merge: a semantic conflict could exhaust a correct ticket's budget and escalate it to the user. Merge-repair rounds now increment the round number but are tallied in Health instead, so the health rule still catches a build where merges keep colliding.
- **Resume re-detects.** The tier rules apply to the model running now, so calibration runs its detection steps on every resume and skips only the question. Liveness (subagent id or PID) and dirty-worktree handling close the crash windows an interrupted session left open.
- **Acceptance tests are tickets.** One end-to-end test per Success Criterion gives G6 and the G7 smoke test a mechanical basis instead of a QA agent's narrative. They skip red-at-base and the commit-order rule because the test is the deliverable and passes by design once the implementing tickets are merged.
- **The tracker holds a recoverable copy.** The progress report and a STATE plus HANDOFF snapshot are each one comment on the spec issue, edited in place by comment id (never "edit last", which could hit a claim or a verdict comment). A new machine rebuilds `.heimdall/` from them. The local tracker cannot do this, so the user is told to back up `.heimdall/`.
- **G7 gets a packet.** The release is a fill-in plan with one go-ahead per outward step and a smoke test against the Success Criteria, run by the orchestrator itself rather than delegated.
- **Less to load per loop session.** The per-harness adapters moved to one file per harness and the loop has a one-page card, so a G4–G5 session loads only what its topology uses.

Not yet exercised live: concurrency above 1, merge path `pr` with real CI, Gitea, a change request, G6, G7, the chat kickoff, and Mermaid `init` rendering on GitHub. CHANGELOG.md lists every change.
