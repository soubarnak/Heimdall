# Agent-Model Map

Read at calibration (the recommended rows of the agent roster, calibration.md, section 5), at G2 (execution topology), and for every packet's "For:" line. Heimdall recommends a **tier** per role and per ticket, and the user chooses the agent for each purpose; this file translates the tier into a concrete model, an effort level, and the flag that selects them in each harness. Verified 2026-10-25 from the family files; when vendors ship new models, edit this file and the family file only — no logic changes.

## Tiers

- **Light** — mechanical, well-scoped work: scaffolding steps, config, small fixes, scouting, single-library doc lookups.
- **Standard** — most coder tickets, reviews, merges, and research digests.
- **Frontier** — orchestration (G1–G3 especially), cross-module or ambiguous tickets, hard debugging, Production reviews of High-risk tickets.

Budget rule: recommend the LOWEST capable tier; never default upward "to be safe". Raise effort before raising tier.

## Role defaults

The recommended answer for each roster row; the user's choice replaces it.

| Role | Tier | Effort |
|---|---|---|
| Orchestrator | Frontier (Standard acceptable; Light only for the build loop or Build-lite — production-orchestrator.md, section 3) | the family's default; one step higher for G1–G3 |
| Researcher | Standard (Frontier for synthesis across many sources) | high |
| Scout | Light | low–medium |
| Coder | per ticket (set at G3) | Light low · Standard default · Frontier high |
| Reviewer | Standard; Frontier for High-risk tickets in Production | high |
| Merger | Standard | medium |
| QA agent | Standard | high |

## Models per family and tier

Details, caveats, and sources live in the family files.

| Family | Frontier | Standard | Light | Family file |
|---|---|---|---|---|
| Anthropic Claude | `claude-opus-5-5` (medium–high); `claude-fable-5-1` for the hardest work | `claude-sonnet-5-5` (high) | `claude-haiku-5-5` (medium) | prompting-claude.md |
| OpenAI GPT | `gpt-6-astra` (high) | `gpt-6.1-sol` (medium); `gpt-6-sol` | `gpt-6-luna` (low) | prompting-openai.md |
| Meta Muse | `muse-wonder-1.0` (high) | `muse-spark-1.3` (high) | `muse-spark-1.3` at low, or a `-contributor` variant | prompting-muse.md |
| DeepSeek | `deepseek-v4-pro` (high; max only for hard debugging) | `deepseek-flash` (high) | `deepseek-flash` (low or none) | prompting-deepseek.md |
| Qwen | Qwen3.8 Max (API) | Qwen3.8 Plus (API), Qwen3-Coder, Qwen3.8-27B (self-hosted) | Qwen3.8-Flash-Next | prompting-qwen.md |
| Google Gemini | `gemini-4-argon` (high) | `gemini-3.8-flash` (medium) | `gemini-3.5-flash-lite` (minimal–low) | prompting-gemini.md |
| Mistral | `mistral-large-4-0` (UNVERIFIED) | `mistral-medium-latest` (reasoning_effort high) | `mistral-small-latest` | prompting-mistral.md |
| xAI Grok | `grok-4.7` (high) | `grok-4.3` | `grok-build-0.1` | prompting-grok.md |
| Moonshot Kimi | `kimi-k3` (high; default is max) | `kimi-k2.7-code` | `kimi-k2.6` | prompting-kimi-glm-minimax.md |
| Zhipu GLM | `glm-5.3` (high; default is max) | `glm-5.2` | `glm-5.3-flash` | prompting-kimi-glm-minimax.md |
| MiniMax | `MiniMax-M3` | `MiniMax-M3.1-Flash` | `MiniMax-M3.1-Flash` (low) | prompting-kimi-glm-minimax.md |

## Selecting model and effort per harness

| Harness | Subagent | Headless | In session |
|---|---|---|---|
| Claude Code | `.claude/agents/<name>.md`: `model:` (`haiku`, `sonnet`, `opus`, `fable`, full id), `effort:`; or the Agent tool's model parameter | `claude -p … --model <alias or id> --effort <level>` | `/model`, `/effort` |
| Codex CLI | `.codex/agents/*.toml`; `agents.default_subagent_model`, `agents.default_subagent_reasoning_effort` | `codex exec -m <id> -c model_reasoning_effort="<level>"` | `/model`; `codex debug models` lists the catalog |
| Muse Code | native subagents (model per spawn) | `muse exec --model <id> --reasoning-effort <level>` | `muse model-profile` shows what each effort resolves to |
| OpenCode | `.opencode/agents/<name>.md`: `model: provider/model` | `opencode run -m <provider/model>` | model picker |
| pi | `pi-subagents` package (optional) | `pi -p … --model <provider/id> --thinking <level>` | model picker |
| Antigravity CLI | — | `agy -p … --model <id> --effort <level>` | — |
| Gemini CLI | `.gemini/agents/*.md` | per the CLI's model flag (prompting-gemini.md) | `/model` |
| Cursor | `.cursor/agents/` (`model`) | — (user-driven) | model picker; auto mode off |

## Pinning rules

- Pin the model and effort in every packet's "For:" line; consistency within a ticket is the contract.
- **Auto model selection** (Cursor auto mode and similar): off for Standard and Frontier tickets; acceptable on Light tickets.
- If a harness cannot pin, say so in the packet and require the red-at-base check for that ticket.
- Cross-vendor models inside another harness (`ANTHROPIC_BASE_URL`, Codex `base_url`): record the effective model, not the slot alias (harness-adapters.md, section 5).

## Degradation

A family or harness not in these tables → tier advice alone still applies ("use your mid-size model at its default effort"). Never guess concrete model names for families not listed here.
