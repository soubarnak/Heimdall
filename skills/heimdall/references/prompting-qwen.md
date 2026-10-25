# Prompting — Qwen (Qwen3.8, Qwen3-Coder, Qwen Code)

Verified 2026-10-25 against the Qwen3.8 README and Hugging Face card, the Qwen3-Coder README, qwen.readthedocs.io, and the Qwen Code docs (Context7 `/qwenlm/qwen3.8`, `/qwenlm/qwen3-coder`, `/qwenlm/qwen-code`, `/websites/qwen_readthedocs_io`). Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model | Context | Notes |
|---|---|---|---|
| Frontier | Qwen3.8 Max (API, proprietary) or Qwen3.8-2.4T-A95B (open, 2026-08-12) | 262,144 native, 1M with YaRN | thinking on by default |
| Standard | Qwen3.8-27B (open, Apache-2.0, 2026-08-14) or Qwen3.8 Plus (API) | 262,144 native, 1M with YaRN | reasoning budget up to 262,144; final answer up to 131,072 |
| Standard (coding) | Qwen3-Coder | 256K native, 1M with YaRN | "specially designed function call format" |
| Light | Qwen3.8-Flash-Next, Qwen3.6-35B-A3B, Qwen3.5 small sizes | — | add compensation |

Older Qwen3 (2025): 32,768 pretraining context (131,072 with YaRN); Qwen3-2507 Instruct is non-thinking only and Thinking-2507 is thinking only.

## Thinking control

- Qwen3.8: thinking on by default. Disable with `enable_thinking: False` inside `chat_template_kwargs` (top-level on QwenCloud).
- `reasoning_effort`: `xhigh` (default), `medium`, `low` — values from the HF card only; the README says only "Reasoning depth can be tuned with `reasoning_effort`." Treat values as UNVERIFIED and check the serving stack.
- `preserve_thinking` is on by default; `False` keeps only the latest user turn's thinking.
- Older Qwen3 soft switches `/think` and `/no_think` in user or system messages ("The model will follow the most recent instruction in multi-turn conversations"). The Qwen3.8 card does not mention them — don't rely on them for Qwen3.8.

## Sampling (open weights — set these explicitly)

| Model / mode | temperature | top_p | top_k | min_p | presence_penalty |
|---|---|---|---|---|---|
| Qwen3.8 thinking | 1.0 | 0.95 | 20 | 0.0 | 0.0 |
| Qwen3.8 non-thinking | 0.7 | 0.80 | 20 | 0.0 | 1.5 |
| Qwen3 / 2507 thinking | 0.6 | 0.95 | 20 | 0 | — |
| Qwen3 / 2507 non-thinking | 0.7 | 0.8 | 20 | 0 | — |

- "DO NOT use greedy decoding, as it can lead to performance degradation and endless repetitions."
- Presence penalty: "higher values may cause language mixing and slightly lower performance."
- A harness that hard-codes Qwen3 sampling (temperature 0.6) does not match Qwen3.8 thinking (1.0).

## Tool calling

- Serve Qwen3.8 with `--tool-call-parser qwen3_coder --reasoning-parser qwen3` (vLLM/SGLang).
- Qwen3-Coder format: tools listed inside `<tools>` in the system prompt; the model emits `<tool_call>` XML tags with JSON inside. Use the server's parser — don't parse by hand.
- OpenAI-compatible Chat Completions is documented; QwenCloud also claims Anthropic compatibility (base URL not found).

## Prompting guidance

Qwen publishes no Qwen3.8 prompting guide beyond the sampling table and thinking switches. Apply prompting-universal.md unchanged. Practical consequences:

- Self-hosted Qwen is the most fragile setup in Heimdall's matrix: wrong sampling, a missing parser, or greedy decoding fails silently (loops, language mixing). Verify the serving config before dispatching packets.
- Keep packets explicit and short; split Standard tickets into smaller tickets when executing on 27B or smaller.

## Qwen Code harness

- Official harness, "optimized for Qwen models".
- Instruction files: `~/.qwen/QWEN.md` (global), `QWEN.md` (project, committed), `.qwen/QWEN.local.md` (personal); "If your repository already has an `AGENTS.md` file for other AI tools, Qwen reads that too."
- Skills: `skills/<name>/SKILL.md` with `name`, `description`, optional `priority` (see harness-adapters.md for exact roots).
- `modelProviders` accepts `openai`, `anthropic`, `gemini` protocol keys; per model `wireApi`: `chat-completions` or `responses`.

## Heimdall adapter

- Frontier: Qwen3.8 Max / 2.4T at `xhigh`. Standard: Qwen3.8-27B or Plus at `xhigh` (default) with thinking on. Light: `low` or non-thinking with the non-thinking sampling row.
- Compensation for 27B and below: numbered sub-steps, an explicit self-check list, one concern per packet.
- Put the RETURN REPORT format at the end of the user turn as well as in any system text.

## Unverified

Qwen3.8 `reasoning_effort` values; `/think` support on Qwen3.8; Qwen3-Coder-Next specs; QwenCloud Anthropic base URL; tool-call reliability in long loops.

## Sources

github.com/qwenlm/qwen3.8 README · huggingface.co/Qwen/Qwen3.8-27B · huggingface.co/Qwen · github.com/qwenlm/qwen3-coder README · qwen.readthedocs.io/en/latest/getting_started/quickstart.html · github.com/qwenlm/qwen-code docs/users/features/skills.md, docs/users/configuration/auth.md · Context7 `/qwenlm/qwen3.8`, `/qwenlm/qwen3-coder`, `/qwenlm/qwen-code`, `/websites/qwen_readthedocs_io`.
