# Prompting — Moonshot Kimi, Zhipu GLM, MiniMax

Verified 2026-10-25 against platform.kimi.ai (Context7 `/websites/platform_kimi_ai`, `/moonshotai/kimi-k2.5`), docs.z.ai (Context7 `/zai-org/glm-5`, `/websites/z_ai_devpack`), and platform.minimax.io (Context7 `/websites/platform_minimax_io`). None of the three vendors publishes a prompting guide; their docs specify parameters and harness setup. Apply prompting-universal.md unchanged, plus the constraints below.

## Kimi (Moonshot)

| Heimdall tier | Model ID | Context | Thinking / effort |
|---|---|---|---|
| Frontier | `kimi-k3` | 1M | `reasoning_effort` low, high, max (default max) |
| Frontier | `kimi-k3.1-pro`, `kimi-k3.1-pro-highspeed` | — | constraints unclear |
| Standard (coding) | `kimi-k2.7-code`, `-highspeed` | 256K | thinking always on; `thinking: disabled` errors; no `reasoning_effort` |
| Light | `kimi-k2.6` | 256K | thinking on by default, can be disabled |

- **Fixed sampling:** "'Fixed' means the parameter cannot be modified: passing any other value returns an error, so do not pass it explicitly." K3: temperature 1.0, top_p 0.95. K2.6: 1.0 thinking, 0.6 non-thinking.
- `tool_choice`: K3 supports `auto`, `none`, `required`; K2.6 and K2.7-code do not support `required`.
- Base URLs: OpenAI `https://api.moonshot.ai/v1`; Anthropic `https://api.moonshot.ai/anthropic` (supports `cache_control` ephemeral 5m/1h).
- Claude Code: `ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic`, `ANTHROPIC_MODEL=kimi-k3[1m]`, Haiku tier `kimi-k2.7-code`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000`, `CLAUDE_CODE_EFFORT_LEVEL=max`.
- Self-hosted K2.5: vLLM `--tool-call-parser kimi_k2 --reasoning-parser kimi_k2` ("**required** for enabling tool calling").
- **Kimi Code CLI** (replaces the archived `kimi-cli`): instructions from `~/.kimi-code/AGENTS.md`, `~/.agents/AGENTS.md`, project `.kimi-code/AGENTS.md` or `AGENTS.md`; skills from `~/.kimi-code/skills/`, `~/.agents/skills/`, `.kimi-code/skills/`, `.agents/skills/` ("Project > User > Extra > Built-in"); `name` and `description` required.

## GLM (Zhipu / Z.ai)

| Heimdall tier | Model ID | Context / max output | Thinking / effort |
|---|---|---|---|
| Frontier | `glm-5.3` | 1M / 128K | thinking on; `reasoning_effort` low, high, max (default max) |
| Standard | `glm-5.2` | 1M | — |
| Light | `glm-5.3-flash` (multimodal), `glm-5.3-flashx` | — | — |
| Legacy | `glm-5`, `glm-4.7`, `glm-4.6` | GLM-5: 200K / 128K (page conflict) | GLM-5 thinking can be disabled |

- GLM-5.3 thinking: one page says disabling "is no longer supported"; the latest-model page says `disabled`/`none`/`off` map to `low` ("the request still runs with lightweight thinking"). Priority: "Explicit Effort > thinking toggle > default `max`." Set `reasoning_effort` explicitly and don't toggle thinking.
- No official sampling recommendation; don't send sampling parameters.
- Base URLs (GLM Coding Plan): Anthropic `https://api.z.ai/api/anthropic`; OpenAI Chat `https://api.z.ai/api/coding/paas/v4`; Responses `https://api.z.ai/api/v1`.
- Claude Code: `ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic`, Opus and Sonnet slots `glm-5.3[1m]`, Haiku slot `glm-5.3-flash[1m]`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000`. Also documented: Codex (Responses endpoint), Goose, Cline (context 1000000). `max` effort recommended for coding.

## MiniMax

| Heimdall tier | Model ID | Context | Thinking / effort |
|---|---|---|---|
| Frontier | `MiniMax-M3` | 1M | `thinking: adaptive` |
| Standard / Light | `MiniMax-M3.1-Flash` | 1M (text, image, video input) | "Thinking cannot be turned off" (`disabled` returns 400); effort low, medium, high, xhigh, max (default max) |

- Effort field: `output_config.effort` (Anthropic), `reasoning_effort` (OpenAI), `reasoning.effort` (Responses).
- `temperature`, `top_p`, `top_k`, `stop_sequences`: "Ignored - Not supported; no effect."
- Base URLs: Anthropic `https://api.minimax.io/anthropic` (recommended); OpenAI `https://api.minimax.io/v1`.

## Heimdall adapter (all three)

- These models usually run **inside another harness** (Claude Code, Codex, Kimi Code CLI) through Anthropic- or OpenAI-compatible endpoints. Use the host harness's packet style (prompting-claude.md or prompting-openai.md) and these constraints:
  - Never send sampling parameters (Kimi errors; MiniMax ignores).
  - Don't force `tool_choice: required` on Kimi K2.x.
  - Default effort is often `max` (Kimi K3, GLM-5.3, MiniMax): set `high` explicitly for Standard packets to control cost and latency.
- Add compensation (numbered sub-steps, self-check list) when a Flash/Light model executes a Standard+ ticket.
- Record the effective model in the RETURN REPORT — inside Claude Code the UI shows Claude slot names, not the real model.

## Unverified

Kimi K2 / K2-thinking API status; `kimi-k3.1-pro` limits; GLM context conflicts; GLM sampling (0.7 / 0.9 appears only in an auto-generated doc); MiniMax max output and M3 thinking toggle; skills / AGENTS.md support in GLM and MiniMax tooling.

## Sources

platform.kimi.ai/docs/{api/models-overview,guide/claude-code-kimi,guide/kimi-code-cli} · github.com/moonshotai/kimi-k2.5 README · github.com/MoonshotAI/kimi-cli (archived) · kimi.com/code/docs/en/kimi-code-cli/customization/{skills,agents}.html · docs.z.ai/{guides/llm/glm-5,guides/llm/glm-5.3,devpack/latest-model,devpack/tool/claude,devpack/tool/others,guides/overview/pricing} · github.com/zai-org/GLM-5 · platform.minimax.io/docs/{guides/text-generation,api-reference/text-anthropic-api,m-plan/other-tools}.
