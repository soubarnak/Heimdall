# Prompting — Universal Rules (all model families)

Verified 2026-10-25. These rules hold across the vendor guides cited in the family files. Family files override this file where they disagree. When you write any prompt or packet, apply this file first, then the target family's file:

| Family | File | Covers |
|---|---|---|
| Anthropic Claude | prompting-claude.md | Fable, Opus, Sonnet, Haiku |
| OpenAI GPT / Codex | prompting-openai.md | GPT-6 Astra / Sol / Luna, Codex CLI, ChatGPT |
| Meta Muse (and Llama) | prompting-muse.md | Muse Wonder, Spark, Glimmer, Llama 4 legacy |
| DeepSeek | prompting-deepseek.md | V4 Pro, Flash |
| Qwen | prompting-qwen.md | Qwen3.8, Qwen3-Coder, Qwen Code |
| Google Gemini | prompting-gemini.md | Gemini 4 / 3.x, Gemini CLI |
| Mistral | prompting-mistral.md | Medium 3.5, Large, Devstral (retired), Vibe |
| xAI Grok | prompting-grok.md | Grok 4.x, Grok Build |
| Kimi, GLM, MiniMax | prompting-kimi-glm-minimax.md | Kimi K3/K2.x, GLM-5.x, MiniMax M3 |

## 1. Say exactly what you want, and why

- Treat the model as a capable new colleague with zero context. Anthropic's test: "Show your prompt to a colleague with minimal context on the task and ask them to follow it." Google: "Be precise and direct: State your goal clearly and concisely." OpenAI (reasoning models): "Keep prompts simple and direct."
- Give the reason behind each important constraint. A model that knows the purpose generalizes correctly to cases the rule did not list.
- Ask for action explicitly. "Can you suggest some changes" produces suggestions, not edits (Anthropic).

## 2. Structure: one delimiter style, used consistently

- Separate instructions, context, input data, and examples. XML-style tags (`<context>`, `<task>`) or Markdown headings both work; Google: "Choose one format and use it consistently within a single prompt." Claude has the strongest documented preference for XML tags.
- Number steps only when order matters.

## 3. Placement: rules first, data in the middle, the ask last

- Put must-hold rules, role, and output format in the system prompt or at the very start. Meta (Muse Spark Open): "pays more attention to the beginning of the system prompt, so put the rules that must always hold first." Google: "Place essential behavioral constraints … in the System Instruction or at the very beginning."
- Put long documents ABOVE the specific question. Anthropic: queries at the end "can improve response quality by up to 30 percent". Google: "Place your specific instructions or questions at the very end of the prompt." Anchor with a transition such as "Based on the information above, …".

## 4. Don't over-prompt modern reasoning models

- Reasoning depth is a **parameter**, not a phrase. Set effort through the API or harness (table in section 7); don't add "think step by step" to reasoning models. OpenAI: "Avoid chain-of-thought prompts." Google: verbose prompt engineering "may cause the model to over-analyze."
- Blanket rules over-trigger. Anthropic: "Instructions such as 'If in doubt, use [tool]' cause overtriggering." Write targeted conditions instead.
- Remove contradictions. OpenAI (GPT-5 guide): contradictory instructions are "more damaging"; the model "expends reasoning tokens searching for a way to reconcile the contradictions." Contradictions also break smaller open models silently.
- Audit every instruction file the model can see (AGENTS.md, CLAUDE.md, skills). OpenAI (GPT-6): the model "can be more sensitive to instructions contained in skills and other files, such as `AGENTS.md`."

## 5. Examples

- Use 3–5 relevant, diverse examples when format or judgment consistency matters (Anthropic). Wrap them so they are not mistaken for instructions.
- For reasoning models, try zero-shot first, then add examples if needed (OpenAI reasoning guide).

## 6. Agentic work: autonomy, stopping, verification, state

- State the stopping rule explicitly. Vendors differ in default eagerness (Haiku 5.5 may stop early; GPT-6 Astra may ask questions where you expected it to assume; Codex guide: "do not end your turn with clarifications unless truly blocked"). Every Heimdall packet says when to keep going, when to stop, and what to hand back.
- Require evidence, not claims. Haiku 5.5 at low/medium effort "sometimes reports a code change as done without running a check"; Opus 5.5 guide: "Treat a text-only end of turn as a report rather than as proof the task is done."
- Keep state on disk (progress notes, test status, git commits). Anthropic: the latest models "perform especially well in using git to track state across multiple sessions." Heimdall's `.heimdall/` files are this state.
- Tell the model what to preserve when context is compacted or summarized (Fable 5.1 guide; Muse Glimmer: "prune or summarize old turns before you hit the configured limit").
- Prefer targeted edits over whole-file rewrites (Fable 5.1 guide); prefer the harness's dedicated tools over raw shell where one exists (Codex guide).
- Parallelize independent tool calls when the model supports it — but some models allow only one tool call per turn (Muse Glimmer). Check the family file.

## 7. Reasoning-effort vocabulary by family

| Family | Parameter | Values | Notes |
|---|---|---|---|
| Claude | `output_config.effort` + `thinking: {type: "adaptive"}` | low, medium, high, xhigh, max | `budget_tokens` returns 400 on 4.7+; Opus 5.5 / Fable 5.1 thinking cannot be disabled |
| OpenAI GPT-6 | `reasoning.effort` (Responses) | none*, low, medium, high, xhigh, max | *`none` not on Astra / 6.1 Sol; Codex CLI adds `ultra` (parallel subagents) |
| Meta Muse (hosted) | `reasoning_effort` / `reasoning.effort` | minimal … max | `none` returns 400; Muse Code adds `ultra` alias = highest level |
| DeepSeek V4 | `reasoning_effort` or `thinking.type` | none, low, high, max | `none` disables thinking; default high |
| Qwen3.8 | `enable_thinking` + `reasoning_effort` | low, medium, xhigh (UNVERIFIED) | thinking on by default |
| Gemini 3.x / 4 | `thinking_level` | minimal, low, medium, high (per model) | `thinking_budget` deprecated; never send both |
| Mistral | `reasoning_effort` | none … xhigh | "high" recommended for agentic/code (Medium 3.5) |
| Grok | `reasoning_effort` | low, medium, high, xhigh | xhigh on grok-4.6+ |
| Kimi K3 / GLM-5.3 / MiniMax | `reasoning_effort` | low, high, max (Kimi, GLM); low … max (MiniMax) | thinking often cannot be disabled |

Budget rule: start at the vendor's recommended default and move up only for measured gains. Higher effort costs time and quota.

## 8. Sampling parameters

- Many reasoning models ignore or reject `temperature` / `top_p`: Claude Sonnet 5.5 returns 400; GPT-6 requires removing them when effort is not `none`; DeepSeek thinking mode ignores them; Kimi fixes them (other values return an error); MiniMax ignores them. Default: don't send sampling parameters to hosted reasoning models.
- Open-weight models need the vendor's published sampling: Qwen3.8 thinking temperature 1.0, top_p 0.95, top_k 20; Muse Glimmer temperature 1.0, top_p 0.95, top_k 64; Gemini 3.x keep temperature at 1.0. Never decode greedily (Qwen, Muse: repetition and loops).

## 9. Multi-turn hygiene

Return reasoning artifacts exactly as received, or the next call fails or degrades: Claude thinking blocks, Gemini thought signatures (missing → 400), DeepSeek `reasoning_content` in tool loops (missing → 400), xAI `reasoning.encrypted_content`, OpenAI reasoning items / `phase`. Harnesses handle this; custom tooling must too.

## 10. Tool calls

- Prefer native tool calling over tools described in prose or XML text (xAI guidance).
- Validate tool arguments in code; Meta: generated arguments "are not guaranteed to validate."
- Some endpoints restrict `tool_choice` (Meta hosted: only `"auto"`; Kimi K2.x: no `required`; Claude Opus/Fable 5.x: forced tool use returns an error).
