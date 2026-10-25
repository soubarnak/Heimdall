# Prompting — Google Gemini (Gemini API, Gemini CLI)

Verified 2026-10-25 against ai.google.dev (Context7 `/websites/ai_google_dev_gemini-api`) and the Gemini CLI docs (Context7 `/google-gemini/gemini-cli`). Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model ID | Status | Context in / out | `thinking_level` (default) |
|---|---|---|---|---|
| Frontier | `gemini-4-argon` | Stable, new | 1,048,576 shared; sync output capped at 65,536 | low, medium, high (medium) |
| Frontier (preview) | `gemini-3.1-pro-preview` | Preview | 1M / 64K | low, medium, high (high) |
| Standard | `gemini-3.8-flash` | Stable, new | 1M / 64K | low, medium, high (medium) |
| Standard | `gemini-3.6-flash` | Stable | — | minimal, low, medium, high (medium) |
| Light | `gemini-3.5-flash-lite` | Stable | 1M / 65K | minimal, low, medium, high (minimal) |
| Legacy | `gemini-2.5-pro` / `-flash` / `-flash-lite` | served "until further notice" | 1,048,576 / 65,536 | 2.5-flash-lite thinking off by default |

Shut down or deprecated: `gemini-3-pro-preview`, `gemini-3.1-flash-lite-preview`, `gemini-2.0-flash`, `gemini-2.0-flash-lite`.

## Thinking control

- Use `thinking_level` (`thinkingLevel`). "`thinkingBudget` (`thinking_budget`) is deprecated. If passed alone, it maps to the nearest `thinkingLevel` … sending `thinkingBudget` and `thinkingLevel` together returns a `400` error."
- Python: `types.ThinkingConfig(thinking_level="medium")`.

## Prompting rules (Google, "Gemini 3 > Core prompting principles")

1. "Be precise and direct: State your goal clearly and concisely."
2. "Prioritize critical instructions: Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt."
3. Long context: "supply all the context first. Place your specific instructions or questions at the very _end_ of the prompt." Anchor with "Based on the information above…".
4. Delimiters: "XML-style tags (e.g., `<context>`, `<task>`) or Markdown headings are effective. Choose one format and use it consistently within a single prompt."
5. Don't over-engineer: "Gemini 3.x responds best to direct, clear instructions. Verbose or complex prompt engineering techniques designed for older models may cause the model to over-analyze."
6. **Temperature:** "For all Gemini 3 models, we strongly recommend keeping the temperature parameter at its default value of `1.0`." Lower values "may lead to unexpected behavior, such as looping or degraded performance."

Agentic system-instruction template (prompting-strategies page; paraphrased by the fetch tool — re-check before quoting): prefer calling a tool with available information over asking the user; on errors "change your strategy or arguments, not repeat the same failed call"; don't make the model narrate its plan in the response. Google warns: "High persistence increases success rates but risks higher token costs or loops."

## Tool calling — thought signatures

- "When using Gemini 4 and Gemini 3 models, you must pass back thought signatures during function calling, otherwise you will get a validation error (4xx status code)."
- Parallel calls: "Only the first `functionCall` part in the list will contain the signature. You must return the parts in the exact order received." Sequential calls: "You must return **all** accumulated signatures in the history."
- SDKs and Gemini CLI handle this when standard chat history is used. Custom tooling must too.

## Gemini CLI harness facts

- Context file: `GEMINI.md` (global `~/.gemini/GEMINI.md`, plus workspace and parents up to `.git`). AGENTS.md is read only if configured: `"context": { "fileName": ["AGENTS.md", "GEMINI.md"] }` in `settings.json`.
- Skills (lowest to highest precedence): built-in, extensions, user (`~/.gemini/skills/` or `~/.agents/skills/`), workspace (`.gemini/skills/` or `.agents/skills/`); `.agents/skills/` beats `.gemini/skills/` in the same tier. Workspace skills need a trusted folder (`/trust`).
- Install from Git: `gemini skills install https://github.com/<owner>/<repo>.git --consent`; extensions: `gemini extensions install <source> [--ref <ref>] [--consent]`.

## Heimdall adapter

- Frontier: `gemini-4-argon` at `high`. Standard: `gemini-3.8-flash` at `medium`. Light: `gemini-3.5-flash-lite` at `minimal`/`low`.
- Packets: rules and report format first (system text), HANDOFF excerpts in the middle, the ticket ask last. One delimiter style.
- Never lower temperature for "determinism" — use the acceptance criteria and report format instead.
- When Gemini CLI hosts Heimdall, add `AGENTS.md` to `context.fileName` so the repo's AGENTS.md pointer loads.

## Unverified

Structured-output schema limits; `gemini-3.8-pro` (seen in one example only); OpenAI-compat `reasoning_effort` mapping; `thinking_budget` ranges for 2.5 models.

## Sources

ai.google.dev/gemini-api/docs/{models,thinking,generate-content/gemini-3,generate-content/thought-signatures,prompting-strategies,generate-content/latest-model} · github.com/google-gemini/gemini-cli docs/cli/{gemini-md,using-agent-skills,skills}.md, docs/extensions/reference.md · Context7 `/websites/ai_google_dev_gemini-api`, `/google-gemini/gemini-cli`.
