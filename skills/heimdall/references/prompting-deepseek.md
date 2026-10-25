# Prompting — DeepSeek

Verified 2026-10-25 against api-docs.deepseek.com (Context7 `/websites/api-docs_deepseek`). Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model ID | Context | Notes |
|---|---|---|---|
| Frontier | `deepseek-v4-pro` (DeepSeek-V4-Pro-0813) | 1M | text only; Responses and Anthropic APIs supported |
| Standard | `deepseek-flash` (DeepSeek-V4.1-Flash-1017) at `high` | 1M | "simply use `deepseek-flash` to access the latest model"; vision supported |
| Light | `deepseek-flash` with thinking `none`/`low` | 1M | fastest, cheapest |

- Max output up to 384K. Default `max_tokens`: 8K non-thinking, 64K thinking, 128K at `max` effort.
- `deepseek-chat` and `deepseek-reasoner` were discontinued on 2026-07-24; `deepseek-v4-flash` names are retired and served by V4.1-Flash.

## Thinking and effort

- "Thinking mode is enabled by default, with the default effort being `high`."
- OpenAI format: `thinking: {type: "enabled" | "disabled"}` (pass in `extra_body` with the OpenAI SDK) and `reasoning_effort`: `none`, `low`, `high`, `max` (`none` disables thinking; `minimal` maps to `low`; `medium` and `xhigh` map to `high`).
- Anthropic format: `output_config.effort` = `low`, `high`, `max`.
- "Thinking mode does not support the `temperature`, `presence_penalty`, or `frequency_penalty` parameters" — they are silently ignored. Don't rely on sampling for control.

## Tool calling and structured output

- Tool calls work in both thinking and non-thinking modes.
- **Pass `reasoning_content` back in tool loops:** "If your code does not correctly pass back `reasoning_content`, the API will return a 400 error."
- Strict tool schemas (beta): `base_url="https://api.deepseek.com/beta"`, `strict: true`, every property required, `additionalProperties: false`; length/count constraints unsupported.
- JSON mode: `response_format: {type: "json_object"}` — and the prompt must ask for JSON, or the API returns 400.

## Harnesses

- DeepSeek documents integrations for Claude Code, Codex, OpenCode, OpenClaw, Hermes, and others, plus its own DeepSeek Harness (developer preview).
- Claude Code via the Anthropic-compatible endpoint: `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic`, `ANTHROPIC_MODEL=deepseek-flash[1m]`, `CLAUDE_CODE_SUBAGENT_MODEL=deepseek-flash`, `CLAUDE_CODE_EFFORT_LEVEL=max`. Model mapping: `claude-opus*` → `deepseek-v4-pro`; `claude-sonnet*` / `claude-haiku*` → `deepseek-flash`.
- On that endpoint `cache_control`, `top_k`, `disable_parallel_tool_use`, and `thinking.budget_tokens` are ignored; `document`, `search_result`, and MCP blocks are unsupported.
- pi lists `deepseek/deepseek-v4-pro` and `deepseek/deepseek-flash` as providers.

## Prompting guidance

DeepSeek publishes no V4-specific prompting guide. The only official prompting advice is the 2025 DeepSeek-R1 README (historical; R1 only): temperature 0.5–0.7, "System prompts should be avoided, with all instructions placed in the user prompt." Do not apply the R1 rules to V4 by default — V4 runs inside harnesses that always send a system prompt. Instead:

- Apply prompting-universal.md unchanged; keep packets explicit and self-contained.
- Put the acceptance criteria and the exact report format in the **user turn** of the packet as well as any system text — this satisfies both the R1-era advice and normal harness behavior.
- Use effort, not prompt phrases, to control reasoning; start at the default `high`.

## Heimdall adapter

- Frontier packets → `deepseek-v4-pro` at `high`; `max` only for hard debugging. Standard → `deepseek-flash` at `high`. Light → `deepseek-flash` at `low`.
- Inside Claude Code with DeepSeek, Claude-specific features (prompt caching, document blocks) are inert; keep packets small enough not to rely on caching.
- Add compensation (explicit sub-steps, a self-check list) when Flash executes Standard+ tickets.

## Unverified

Whether `deepseek-chat` / `deepseek-reasoner` now hard-fail; skills / AGENTS.md support in DeepSeek Harness; tool-call reliability claims beyond the docs.

## Sources

api-docs.deepseek.com/{updates,quick_start/pricing,guides/thinking_mode,guides/anthropic_api,guides/tool_calls,quick_start/agent_integrations,quick_start/agent_integrations/claude_code} · github.com/deepseek-ai/deepseek-r1 README · Context7 `/websites/api-docs_deepseek`, `/deepseek-ai/deepseek-r1`.
