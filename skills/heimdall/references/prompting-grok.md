# Prompting — xAI Grok (Grok 4.x, Grok Build)

Verified 2026-10-25 against docs.x.ai (Context7 `/websites/x_ai`, `/llmstxt/x_ai_llms_txt`). Several pages were read through a fetch summary; those facts are marked [summary]. Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model ID | Context | Price per 1M in / cached / out (<200K) |
|---|---|---|---|
| Frontier | `grok-4.7` | 500K; "no text output limit" | $2.00 / $0.50 / $6.00 |
| Frontier | `grok-4.6` | 500K | same |
| Standard | `grok-4.3` | 1M | $1.25 / $0.20 / $2.50 |
| Standard | `grok-4.20-0309-reasoning` (also `-non-reasoning`, `grok-4.20-multi-agent-0309`) | 1M | $1.25 / $0.20 / $2.50 |
| Light (coding) | `grok-build-0.1` (alias `grok-code-fast-1` [summary]) | 256K | $1.00 / $0.20 / $2.00 |

The models page recommends `grok-4.7` for code [summary]. Grok Build model is "Currently in early access."

## Reasoning control

- `reasoning_effort` (Chat) or `reasoning.effort` (Responses): `low`, `medium`, `high` (default), `xhigh` (grok-4.6+).
- `GET /v1/models` exposes `capabilities.reasoning_effort` per model — query it instead of guessing.
- Grok 4.7 Responses "always returns `reasoning.encrypted_content`"; pass reasoning items back unchanged.
- `logprobs` / `top_logprobs` are silently ignored on grok-4.20 and newer.

## Prompting guidance

Caching best practices (verbatim, docs.x.ai prompt-caching page) — these also shape packet layout:

- "Always set `x-grok-conv-id` (or `prompt_cache_key` for Responses API) — Routes requests to the same server, maximizing cache hits."
- "Never modify earlier messages — Only append new ones. Any edit, removal, or reorder breaks the cache."
- "Front-load static content — Place system prompts, few-shot examples, and reference documents at the beginning where they form a stable prefix."

grok-code-fast prompting guide (primary page returned 404; search excerpt only, UNVERIFIED wording):

- Prefer native tool calling over "XML-based tool-call outputs, which may hurt performance."
- Give a detailed system prompt covering the task, expectations, and edge cases.
- "The model expects substantial context in the initial user message."

Long loops: "Long agent loops additionally benefit from context compaction" (grok-4.5 page).

## Grok Build harness facts (beta)

- Context files: `AGENTS.md` / `Agents.md` / `AGENT.md` from cwd up to the repo root; also `CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/` — "Grok is fully compatible with Claude Code with zero configuration needed."
- Skills: project `./.grok/skills/` (walked to repo root); user `~/.grok/skills/` and `~/.agents/skills/`; plugin `skills/` dirs; `[skills] paths` in `~/.grok/config.toml`. Project-level `.agents/skills/` is not listed — install Heimdall at user level or in `.grok/skills/`.
- No Git-URL install; marketplace via `[[marketplace.sources]]` and `/plugins`; local plugins via `--plugin-dir <PATH>`.
- Headless `grok -p` is cited only by third parties (UNVERIFIED); Agent Client Protocol is official.

## Heimdall adapter

- Frontier: `grok-4.7` at `high` (default). Standard: `grok-4.3` at `medium`/`high`. Light: `grok-build-0.1`.
- Put a detailed, stable system block first (cacheable); HANDOFF excerpts next; the ticket ask last. Never rewrite earlier turns in a dispatch loop.
- Give the executor the full context in the first user message; don't drip-feed.

## Unverified

The grok-code-fast prompting guide text (404); `grok-code-fast-1` alias; Grok Build headless flags; project `.agents/skills` support in Grok Build.

## Sources

docs.x.ai/developers/{models,models/grok-code-fast-1,release-notes,advanced-api-usage/prompt-caching/best-practices,model-capabilities/text/reasoning,rest-api-reference/inference/models,grok-4-5} · docs.x.ai/build/features/skills-plugins-marketplaces · Context7 `/websites/x_ai`, `/llmstxt/x_ai_llms_txt`.
