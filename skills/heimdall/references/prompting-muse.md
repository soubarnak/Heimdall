# Prompting — Meta Muse (and legacy Llama)

Verified 2026-10-25 against dev.meta.ai docs, the Muse Glimmer model card, the local `muse` CLI (Muse Code 1.4.13), and meta-llama repositories. Context7 has no Muse coverage yet; Meta's own docs are the primary source. Apply prompting-universal.md first.

## Models and tiers

Meta's current lineup is the **Muse** family. Llama 4 is legacy, open-weight only, and not listed on the hosted Meta Model API.

| Heimdall tier | Model ID | Access | Context | Notes |
|---|---|---|---|---|
| Frontier | `muse-wonder-1.0` | Model API (preview), Muse Code | 1,048,576 | "most capable"; effort minimal … max |
| Frontier | Muse Wonder Full | Muse Code subscription only | — | no API ID |
| Standard | `muse-spark-1.3` | Model API, Muse Code | 1,048,576 | "Recommended for new work"; supports `max`; audio not fully supported (use 1.2) |
| Standard | `muse-spark-1.2` | Model API, Muse Code | 1,048,576 | Muse Code docs name it the default; the local model catalog marks `muse-wonder-1.0` as default (conflict — check `muse model-profile`) |
| Light | `muse-spark-1.3` at `low`/`minimal` effort, or `-contributor` variants | Model API, Muse Code | — | contributor variants are cheaper; no `max` on 1.3-contributor |
| Light (self-hosted) | Muse Glimmer 30B | open weights (Apache 2.0) | 131,072+ | one tool call per turn |
| Standard (self-hosted) | Muse Spark Open (816B MoE, 42B active) | open weights (Muse Model License) | 1,048,576 | parallel tool calls |

Inputs: text, image, video, audio, PDF (hosted Spark/Wonder). Output: text.

## Reasoning effort — the vocabulary differs by surface

- Hosted API: `reasoning_effort` (Chat Completions) or `reasoning.effort` (Responses), `minimal` … `max`. `"none"` returns HTTP 400 on Muse Wonder and Muse Spark. `max` only on `muse-wonder-1.0` and `muse-spark-1.3`.
- Muse Code CLI: `--reasoning-effort none|minimal|low|medium|high|xhigh|max|ultra` (default `high`). "`ultra` is a client-side setting that maps to each provider's highest supported reasoning level." "The Meta provider does not accept `none`." `muse model-profile` shows what a model resolves to per effort tier.
- Muse Spark Open (self-hosted): `low|medium|high|xhigh` → reasoning strength 8/32/256/512 (default `xhigh`). "Reasoning can't be turned off"; `none` and `max` are rejected.
- Muse Glimmer: `reasoning_strength` template argument `xhigh|high|medium|low` (default `high`).
- Reasoning tokens count toward the output budget: set `max_tokens` / `max_output_tokens` generously.

## Prompting rules (Meta)

1. **Must-hold rules first.** "Muse Spark Open pays more attention to the beginning of the system prompt, so put the rules that must always hold first." Meta's template order: Objective → Priority rules → Decision procedure → Tools → Output → Completion, ending in "Return exactly: {…}".
2. **Explicit output contract.** State the output format and constraints up front; give an explicit schema for machine-read output. Use `response_format` with `json_schema` on the hosted API — "Decoding itself is constrained, so the output is guaranteed to conform" (recursive schemas return 400).
3. **Be specific about the role; avoid meta-instructions about internal behavior** (Glimmer prompting guide).
4. **Your system prompt is appended, not a replacement:** "Your system prompt doesn't replace the template's own system block; the template adds it to that block."
5. **Use the chat template; never hand-build special tokens.** "Always use apply_chat_template … Constructing the prompt string by hand is error-prone." OpenAI-compatible servers (vLLM, SGLang, llama.cpp) parse Meta's native ATEM tool format and return standard `tool_calls`.
6. **Sampling (open weights):** Glimmer temperature 1.0, top_p 0.95, top_k 64 — "Don't run this model greedy." Spark Open defaults temperature 1.0, top_p 1.0. Stop on `<|eot|>` only — "Never stop on `<|eom|>`."

## Tool calling

- Hosted: OpenAI-style `tools`. **`tool_choice` must be `"auto"`** — `"none"`, `"required"`, and named functions return HTTP 400. Parallel calls are supported: "append one `tool` message per call."
- Arguments are not guaranteed to validate: "Always parse and validate arguments in your own code."
- Glimmer: "supports one tool call per turn. It does not support parallel tool calls." Spark Open: parallel calls supported.
- Reasoning continuity: "The Chat Completions adapter (`@ai-sdk/openai-compatible`) does not preserve Muse Spark's reasoning across turns." Use the Responses surface for long agent loops.
- Long loops (Glimmer): "prune or summarize old turns before you hit the configured limit."

## Muse Code harness facts (local `muse --help`, dev.meta.ai/docs/muse-code)

- Instruction files: per directory level, the first of `AGENTS.md`, `CLAUDE.md`, `.agents/AGENTS.md`, `.claude/CLAUDE.md`; deeper directories win.
- Skills: user roots `$XDG_CONFIG_HOME/muse/skills`, `~/.agents/skills`, plus foreign roots `~/.claude/skills` and `$CODEX_HOME/skills` (fallback `~/.codex/skills`); project roots `.agents/skills`, `.codex/skills`, `.claude/skills`. Project skills, rules, and hooks load only after workspace trust (`--trust-workspace` or the trust prompt). `muse skills install <local-path> [--scope user] [--name] [--force]`, `muse skills validate <path>`, `muse skills list --source all`, `muse skills import --from claude|codex`. Skills are loaded with the `read_skill` tool.
- Headless: `muse exec` runs one prompt non-interactively; `--prompt-file`, `--model`, `--reasoning-effort`, `--approval-mode untrusted|on-request|never`, `--trust-workspace`, `--output-schema FILE` (Meta provider only), `--max-model-steps N`, `--json` (JSONL events), `--worktree`. Exit codes: 0 completed, 1 failed/cancelled/step cap, 2 usage error.
- Subagents: a lead session spawns child agents (`/subagents`, `/tasks`); `--subagent-worktree-isolation` isolates only when a child asks; `--agents <JSON>` overlays one agent definition (JSON shape undocumented).
- Questions to the user: `request_user_input` tool; headless runs use `--user-input-auto-resolve` (auto-cancels prompts) or `--disable-request-user-input`.
- Meta blog guidance: put standing rules in a `developer` message rather than `system`; give an objective check such as a failing test; scope each agent role to its own toolset.
- Other harnesses with documented Muse setup: Codex (`wire_api = "responses"`, `base_url = "https://api.meta.ai/v1"`), Claude Code (`ANTHROPIC_BASE_URL=https://api.meta.ai`), OpenCode (`@ai-sdk/openai-compatible`; loses reasoning across turns), pi (`meta/` provider).

## Legacy Llama 4 (open weights)

Llama 4 Scout (17Bx16E, 10M context) and Maverick (17Bx128E, 1M context), released 2025-04-05, knowledge cutoff August 2024. Prompt format: `<|header_start|>role<|header_end|>…<|eot|>`. Tools: JSON function definitions in the system turn; output `[func(k=v), …]` (python_list) or JSON; parallel calls native. Meta's tool system prompt: "ONLY use functions that are EXPLICITLY listed" and "NEVER combine text and function calls in the same response." Use Llama 4 only as a Light executor with heavy compensation.

## Heimdall adapter — writing packets for Muse executors

- Order the packet prompt the Meta way: objective → non-negotiable rules (Settled Decisions, safety) → numbered procedure → tools note → exact RETURN REPORT format → completion rule ("Stop when every acceptance criterion has evidence, then output the report and nothing else").
- Put rules first; put HANDOFF excerpts after the rules, the specific ticket ask last.
- Effort: Light `low`, Standard `high` (Muse Code default), Frontier (`muse-wonder-1.0`) `xhigh`; never `none`.
- Executing on Glimmer: one tool call per turn — split work into smaller packets and add compensation (explicit sub-steps, self-check list).
- Dispatch from another harness: `muse exec --model muse-spark-1.3 --reasoning-effort high "<packet prompt>"` — only with the user's consent.

## Unverified

Muse Wonder model-card details (PDF not readable); hosted Muse pricing; Muse Spark Open release date; whether hosted Spark uses exactly the Spark Open template.

## Sources

dev.meta.ai/llms.txt · dev.meta.ai/docs/{models,tool-calling,structured-output,reasoning,coding-agents}.md · dev.meta.ai/docs/muse-glimmer/prompting.md · dev.meta.ai/docs/muse-spark-open/{prompting,settings}.md · dev.meta.ai/docs/muse-code/configuration.md · huggingface.co/meta-models/Muse-Glimmer-30B · github.com/meta-llama/llama-models (models/llama4/MODEL_CARD.md, prompt_format.md) · local `muse --help`, `muse skills --help`, `muse skills list` · Context7 `/meta-llama/llama-models`, `/meta-llama/llama-cookbook`, `/websites/llama_meta`.
