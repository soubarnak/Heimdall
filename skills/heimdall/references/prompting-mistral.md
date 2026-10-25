# Prompting — Mistral (Medium 3.5, Large, Devstral, Vibe)

Verified 2026-10-25 against docs.mistral.ai, the platform-docs-public repo (Context7 `/mistralai/platform-docs-public`), and the Mistral Vibe README (Context7 `/mistralai/mistral-vibe`). Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model ID | Context | Notes |
|---|---|---|---|
| Frontier | `mistral-large-4-0` (Large 4, v26.10, open weights) | UNVERIFIED (model card 404) | |
| Standard (coding default) | `mistral-medium-latest` = Medium 3.5 (`mistral-medium-3-5-26-04`) | 256K | "Our frontier-class multimodal model optimized for agentic and coding use cases"; open weights (Modified MIT); released 2026-04-28 |
| Standard | `mistral-large-latest` (Large 3) | 256K | |
| Light | `mistral-small-latest` (Small 3.2 or Small 4 — sources conflict) | 256K (Small 4) | |
| Light (local) | Devstral Small 2 (24B, open weights) | — | "tuned for agentic and code tasks" |

**Devstral API models are retired:** Devstral 2 (`devstral-2512`) retired 2026-07-31; Devstral Small 2 API 2026-03-31; Devstral Medium 1.0 2026-05-31. The Devstral 2 card says "Use Mistral Medium 3.5 for new integrations." The `devstral-latest` alias still appears on one docs page; whether it resolves is UNVERIFIED — don't use it.

## Reasoning control

- `reasoning_effort`: `none`, `minimal`, `low`, `medium`, `high`, `xhigh` (per-model support for `xhigh` UNVERIFIED).
- Medium 3.5: "For agentic and code use cases, `reasoning_effort="high"` is recommended."
- Requests over the context window return `400 Bad Request`; token counts include input and output.
- Temperature max 1.5. No coding-agent temperature recommendation published.

## Prompting guidance (official, sparse)

- "it is **recommended to provide context and custom instructions** under the `system` role umbrella."
- "Mistral models respect system prompts the same way as OpenAI models. Pass them as the first message with `role: "system"`."
- No dedicated prompting guide exists. Apply prompting-universal.md unchanged; write OpenAI-style system + user packets.

## Mistral Vibe harness facts

- Context: `AGENTS.md` at `~/.vibe/AGENTS.md` or in project directories, "loaded from cwd up to the trust root"; closer directories win; "Files are only loaded for trusted folders."
- Custom system prompts (`~/.vibe/prompts/<name>.md`, `system_prompt_id`) "entirely replace the default one" — don't replace it for Heimdall; use AGENTS.md and the skill.
- Skills: `skill_paths` in `config.toml`, `.agents/skills/` (project, trusted only), `.vibe/skills/`, `~/.vibe/skills/`, `~/.agents/skills/`. Frontmatter `name`, `description`, `user-invocable`, `allowed-tools`. No Git-URL install command documented.
- **Safety:** "In programmatic mode (`vibe --prompt …`), Vibe falls back to `auto-approve` when `--agent` is not provided, and interactive tools such as `ask_user_question` are disabled. Pass `--agent plan` explicitly if you want a read-only programmatic run." Built-in agents: `default`, `plan`, `accept-edits`, `smart-approve`, `auto-approve`.

## Heimdall adapter

- Standard: `mistral-medium-latest` at `high` (the documented recommendation). Frontier: Large 4 at `high`/`xhigh`. Light: Small at `low`.
- Headless dispatch to Vibe: always pass `--agent` explicitly (`plan` for review packets, `accept-edits` for build packets); never rely on the default auto-approve. User consent is required (harness-adapters.md).
- Gates cannot be answered inside `vibe --prompt` (question tool disabled) — run gates in the orchestrating session.

## Unverified

Large 4 context and output limits; current `mistral-small-latest` mapping; max output for any model; any official Mistral agent-reliability guidance.

## Sources

docs.mistral.ai/models/{overview,devstral-2-25-12,mistral-medium-3-5-26-04} · github.com/mistralai/platform-docs-public (function-calling, reasoning, known-limitations, temperature, offline-models, migration-guides, vibe/code/safety-approvals-permissions) · github.com/mistralai/mistral-vibe README · Context7 `/mistralai/platform-docs-public`, `/mistralai/mistral-vibe`.
