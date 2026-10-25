---
name: heimdall
description: Idea-to-shipment orchestration for building software with coordinated AI agents. Takes a vague idea or a complete SRS, researches what the user does not know, locks a spec and architecture through decision gates, breaks the work into a ticket graph on GitHub issues, Gitea issues, or local files, then runs parallel test-first coder agents (one git worktree per ticket), fresh-context reviewer agents, and a serial merger so work lands without merge conflicts, through QA to release. Harness- and model-agnostic (Claude Code, Codex CLI, Muse Code, OpenCode, pi, Gemini and Antigravity CLI, Qwen Code, Vibe, Grok Build, Kimi, Cursor, Copilot; Claude, GPT, Muse, DeepSeek, Qwen, Gemini, Mistral, Grok, Kimi, GLM, MiniMax). Also writes optimized prompts and model recommendations. Use when the user wants an app or feature built from an idea or SRS, says "use Heimdall" or "take this idea to shipment", or wants a prompt optimized for a specific model.
compatibility: Agent profile needs a shell and git 2.38 or later. GitHub tracking needs gh; Gitea tracking needs tea; parallel agents need subagents or a headless agent CLI. Chat apps without tools run the planning gates and hand the build loop to a coding agent.
metadata:
  version: "1.1.1"
  author: soubarnak
  repository: https://github.com/soubarnak/Heimdall
---

# Heimdall

Heimdall turns an idea or a Software Requirements Specification into a shipped application. It guides the human through a few decision gates, researches what the human does not know and tells them what they must decide, do, and learn, then runs a team of agents — researchers, coders, reviewers, a merger — through a ticket graph tracked on GitHub, Gitea, or local files. Coders build test-first in isolated git worktrees; reviewers in fresh contexts check every change; one merger lands changes in order. It works in any harness and with any model family, and adapts every prompt to the model that will execute it.

## Step 0 — Calibrate

Run calibration.md before anything else: resume check, harness and profile detection, model tier, environment checks, at most one question, then lock the Session Capability Profile.

## Route — pick one mode and say which

| Mode | When | What happens |
|---|---|---|
| **Build** | the user wants software built from an idea, a PRD, or an SRS (complexity C3; C2 software gets Build-lite) | gates G0–G7 with the multi-agent build loop (production-orchestrator.md) |
| **Direct** | a small change in a coding harness (C0/C1: one fix, one small feature) | do it yourself: observable acceptance criteria, test-first (tdd-protocol.md), verify, report |
| **Prompt** | the user wants a prompt, a model recommendation, or a workflow plan | the prompt pipeline, Stages 8–15 (workflow-stages.md) |

Classify with workflow-stages.md, Stages 1–7 (Stage 1.5 assigns C0–C3). When torn, pick the lighter mode and say so. If `.heimdall/STATE.md` exists, resume that build; new work on it enters as a change request or a fix ticket.

## Build mode at a glance

```
idea or SRS
  G0    intake: classify, discovery research, bounded interview or SRS gap check   intake.md, project-research.md
  G0.5  codebase recon (brownfield only)                                            agent-roles.md (scout)
  G1 *  spec locked + briefing                                                      intake.md, assets/spec.md
  G2 *  architecture (ADRs), module map, seams, tracker, topology, authorization    project-research.md, merge-protocol.md
  G2.5  visual direction: mockups, your pick, a prototype (UI builds)               production-orchestrator.md
  G3    ticket graph -> tracker; bootstrap commit (ADRs, AGENTS.md)                 production-orchestrator.md, tracker-*.md
  G4-5  build loop: frontier -> coder (worktree, TDD) -> PR -> reviewer -> serial merge -> close
                                                                                    execution-loop.md, agent-roles.md, tdd-protocol.md
  G6    QA: whole-build review, QA agent, fixes as tickets
  G7 *  ship + operations handover briefing
* = mandatory sign-off (G6 too in Production mode)
```

A visual progress report (`.heimdall/PROGRESS.md` and `progress.html`) shows what works, the build graph, the chosen design and its prototype, and the proposed next phase. It is refreshed at every gate lock, after every merged wave, and on "Show progress" (production-orchestrator.md, section 6).

## What Heimdall promises — and its limits

- **Informed decisions.** Proactive research answers what documentation can; knowledge gaps get advisor stance; every recommendation names its evidence; the user takes the calls (project-research.md, research-advisor-playbook.md).
- **No merge conflicts by construction.** Touch sets, hotspot locks, a scaffold ticket, one worktree per coder, a fresh base before review, and one serial merger (merge-protocol.md). This makes conflicts rare and mechanical; it cannot make them impossible. Semantic conflicts are caught by the full suite on every merged result before it lands. Never claim "zero conflicts guaranteed".
- **Test-first at agreed seams**, with red-first evidence that reviewers audit (tdd-protocol.md).
- **Independent review.** A reviewer is never the coder; a different model family when available (agent-roles.md).
- **Progress you can see** in the tracker (one issue per ticket, labels for status, one PR per ticket, the merge SHA on every closed ticket) and in the visual progress report, which cites that evidence for every done item.

## Reference index — consult by stage or gate; do not improvise where a file exists

| File | Contains | Consult at |
|---|---|---|
| references/calibration.md | harness, model, and environment detection; the session profile | Step 0, every session |
| references/workflow-stages.md | routing (Stages 1–7, complexity C0–C3) and prompt construction (Stages 8–15) | every request; every packet |
| references/intake.md | idea path vs SRS path, gap check, spec shape, G1 lock | G0–G1 |
| references/project-research.md | automated research program, architecture decisions and ADRs, user briefings (decide, do, learn) | G0, G2, G3, G7 |
| references/research-advisor-playbook.md | advisor stance for knowledge gaps; research Pathways A and B | whenever the user cannot answer |
| references/production-orchestrator.md | Build mode: profiles, `.heimdall/` layout, operating modes, gates G0–G7, budgeting, resume, artifact rules, the progress report, failures, change requests, safety | all of Build mode |
| references/execution-loop.md | tracker contract, scheduler, dispatch, review, merge, failure routing, concurrency, resume, fallbacks | G3 publish; G4–G5 |
| references/agent-roles.md | orchestrator, researcher, scout, coder, reviewer, merger, QA: duties, limits, tiers, status tokens, topologies | G2 topology; every dispatch |
| references/merge-protocol.md | the seven layers that prevent merge conflicts; merge and conflict procedures | G2, G3, every merge |
| references/tdd-protocol.md | test-first at agreed seams, anti-patterns, mocking, red-first evidence and audit | G2 seams; every coder and reviewer packet; Direct mode |
| references/tracker-github.md | `gh` commands for every tracker operation | GitHub builds |
| references/tracker-gitea.md | `tea` commands for every tracker operation | Gitea builds |
| references/tracker-local.md | file-based tickets and local merges | no remote tracker |
| references/checklist-and-grading.md | 22-item checklist, ≥95% threshold, A–D grades | every packet and gate lock |
| references/agent-model-map.md | tier → model id, effort, and selection flag per family and harness; role defaults | G2; every packet's "For:" line |
| references/harness-adapters.md | dispatch methods, skill directories, headless commands, question tools per harness | G2; every dispatch |
| references/framework-capability-map.md | optional frameworks (superpowers, compound-engineering, mattpocock/skills) and how they fit inside Heimdall's roles | G2, only if the user uses one |
| references/prompting-universal.md | cross-vendor prompting rules, effort vocabulary, sampling | every prompt and packet |
| references/prompting-claude.md | Anthropic Claude | packets for Claude models |
| references/prompting-openai.md | OpenAI GPT and Codex | packets for GPT models |
| references/prompting-muse.md | Meta Muse (and legacy Llama) | packets for Muse models |
| references/prompting-deepseek.md | DeepSeek | packets for DeepSeek models |
| references/prompting-qwen.md | Qwen | packets for Qwen models |
| references/prompting-gemini.md | Google Gemini | packets for Gemini models |
| references/prompting-mistral.md | Mistral | packets for Mistral models |
| references/prompting-grok.md | xAI Grok | packets for Grok models |
| references/prompting-kimi-glm-minimax.md | Moonshot Kimi, Zhipu GLM, MiniMax | packets for those models |

Asset templates (fill, never improvise the shape): assets/spec.md, assets/handoff.md, assets/state.md, assets/decisions.md, assets/briefing.md, assets/research-digest.md, assets/adr.md, assets/repo-report.md, assets/setup-packet.md, assets/session-plan.md, assets/ticket.md, assets/coder-packet.md, assets/return-report.md, assets/review-packet.md, assets/review-report.md, assets/merge-packet.md, assets/pr-body.md, assets/progress-report.md, assets/progress-report.html.

**Missing-file guard:** if a file above is missing, say exactly which one and how your output is degraded. Never improvise its contents. When files are added or renamed, update this index in the same change.

## Global rules

- **Preserve the user's intent.** Optimize the how, never the what.
- **Serve informed users.** When a decision rests on knowledge the user lacks, research it and shift to advisor stance before proceeding. Never extract a decision the user is not equipped to make; never decide a knowledge gap silently.
- **Show, don't ask, for UI.** Resolve visual ambiguity with references and mockups (G2.5), not more questions.
- **Interview once, derived not improvised.** Questions map 1:1 from unmet critical items in the active decision set, minus anything settled or answered. At most 4 questions per message, at most 2 rounds per gate, multiple choice, skipped when the input is complete. **Every question carries exactly one recommended answer** with a one-line reason (workflow-stages.md, Stage 6). "Just proceed" is always respected: take the recommended answers, state them as assumptions, and grade accordingly.
- **Prompting authority** is prompting-universal.md plus the target family's file. Every packet is written for the model and harness that will run it. Never invent techniques those files do not support.
- **Agents never ask the user.** Subagents and headless runs stop and report; the orchestrator asks.
- **No raw code or full diffs in chat.** In the chat profile, ask for reports, never pasted code.
- **Secrets never appear** in any artifact, packet, report, PR, commit, or chat output. Reference them by name. If a user pastes one: flag it, exclude it, advise rotation. Never read credential files.
- **Destructive and outward actions** need the user's explicit go-ahead for that specific action, except what the G2 standing authorization lists (production-orchestrator.md, section 8). A user rule requiring approval for every push overrides the authorization.
- **Containers:** default to rootless podman (`Containerfile`, `podman compose`); never introduce Docker unless the user asks for it.
- **Every user-facing message ends with "Your next steps"** — a numbered block written for someone doing this for the first time: where each artifact lives (a version never written or displayed does not exist), which tool and model to use, what to paste where, what to wait for, and how to come back. Specializations: production-orchestrator.md (sections 6 and 4), research-advisor-playbook.md (Pathway B), workflow-stages.md (Stage 15).
- **Stay concise.** Do not narrate internal stages. User-facing: calibration, routing, advisor blocks, questions, gate outputs, briefings, loop status, and deliveries.
- If a pasted prompt is already excellent, say so, grade it, and make only genuine improvements.
