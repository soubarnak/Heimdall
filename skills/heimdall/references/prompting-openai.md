# Prompting — OpenAI GPT and Codex (ChatGPT agents, Codex CLI)

Verified 2026-10-25 against developers.openai.com, learn.chatgpt.com (Codex docs), the openai-cookbook, and the local `codex-cli 0.163.0`. Apply prompting-universal.md first.

## Models and tiers (GPT-6 family)

| Heimdall tier | Model ID | Official positioning | Context / max output | Effort values (API) |
|---|---|---|---|---|
| Frontier | `gpt-6-astra` | "our flagship model for complex reasoning and coding"; API default starting point | 1,050,000 (max input 922,000) / 128,000 | low, medium, high, xhigh, max (no `none`, no `minimal`) |
| Standard (Codex default choice) | `gpt-6.1-sol` | "balance intelligence and cost"; Codex docs: "For complex coding and agentic workflows, use GPT-6.1 Sol when available" | same | low, medium (default), high, xhigh, max |
| Standard | `gpt-6-sol` | "built for complex coding and agentic workflows" | same | none, low, medium (default), high, xhigh, max |
| Light | `gpt-6-luna` | "Our most efficient model for focused, high-volume tasks" | same | none, low, medium (default), high, xhigh, max |

- Codex CLI adds effort `ultra` ("uses subagents to work on parts of a task in parallel"); config keys: `model`, `model_reasoning_effort` (`low|medium|high|xhigh|max|ultra`), `model_verbosity`.
- Codex harness catalog (local `codex debug models`) reports smaller context windows than the API (272K–500K) and a `low` default effort for `gpt-6.1-sol`. Trust the harness for in-Codex limits.
- Tool calling requires the Responses API for Astra and 6.1 Sol. When effort is not `none`, remove `temperature`, `top_p`, `top_logprobs`.
- Legacy: `gpt-5.6-sol` (alias `gpt-5.6`) still served; `gpt-5.3-codex` deprecated, shuts down 2027-04-01; several GPT-5.x models retired from Codex sign-in during 2026.
- Effort guidance (model-selection guide, summarized): Luna low for fine-grained edits and simple extraction; 6.1 Sol medium for complex technical work; Astra medium for ambitious projects needing broad context; xhigh for demanding analysis. Start at medium; reserve max.

## GPT-6 behavior notes (official, latest-model guide)

The guide gives five behavior notes "observed with GPT-6 Astra" and says to use its prompts "as a starting point across the GPT-6 model family":

1. **Initiative:** the model "is more likely to ask the user a question when additional input could materially change the result" — it may stop where you expected it to assume and continue. In packets, state which decisions it may make on its own.
2. **Instruction sensitivity:** it "can be more sensitive to instructions contained in skills and other files, such as `AGENTS.md`. We **strongly recommend** auditing skills and other files." Keep AGENTS.md and skill text free of stale or conflicting rules.
3. **Style:** it "tends toward detailed, formatted responses." Specify length and structure (e.g. the exact RETURN REPORT format).
4. **Subagents:** it "may delegate less often than desired." Say when and how much to use subagents.
5. **Testing:** it "tends to be thorough in testing" — on small tasks, broader than needed. Scope the verification you want.

Migration: "GPT-6 Astra and GPT-6.1 Sol do not support `none`; use `low` instead." "The user's instructions take precedence over guidelines provided in a skill."

## Codex prompting guide (cookbook; written for gpt-5.x-codex, still the Codex-specific reference)

- Remove scaffolding the model already does: "remove all prompting for the model to communicate an upfront plan, preambles, or other status updates during the rollout."
- Start from the standard Codex prompt and add tactically: "start with our standard Codex-Max prompt as your base and make tactical additions."
- Autonomy: "Persist until the task is fully handled end-to-end within the current turn whenever feasible" and "do not end your turn with clarifications unless truly blocked."
- Anti-looping: "if you find yourself re-reading or re-editing the same files without clear progress, stop."
- Planning tool: "Skip using the planning tool for straightforward tasks (roughly the easiest 25%)."
- Tools: use the exact `apply_patch` implementation ("the model has been trained" on it); a string-typed shell command beat a list; "Strictly avoid raw `cmd`/terminal when a dedicated tool exists."
- Output: "Default: be very concise; friendly coding teammate tone."
- AGENTS.md: Codex "loads these files automatically," later directories overriding earlier ones.

## General GPT agent guidance (GPT-5-era cookbook; still useful, label as legacy)

- Contradictions are "more damaging" — the model "expends reasoning tokens searching for a way to reconcile the contradictions."
- Eagerness is tunable in the prompt: for less, a tool-call budget ("an absolute maximum of 2 tool calls") and a lower effort; for more, "keep going until the user's query is completely resolved."
- Verbosity is both a parameter (`verbosity: low|medium|high`) and steerable in natural language.
- Markdown in API output is off by default; ask for it explicitly when needed.
- Reasoning models: "Developer messages are the new system messages." "Avoid chain-of-thought prompts." "Try zero shot first, then few shot if needed."

## Codex CLI harness facts

- Instruction files: `~/.codex/AGENTS.override.md` or `~/.codex/AGENTS.md` (global), then every `AGENTS.md` from the project root down to the working directory; files over `project_doc_max_bytes` (32 KiB default) are silently truncated. Untrusted projects skip AGENTS.md.
- Skills: `.agents/skills` (repo, scanned from cwd up to the root), `$HOME/.agents/skills` (user), `/etc/codex/skills` (admin); the source also scans `$CODEX_HOME/skills` (`~/.codex/skills`). Invoke with `$heimdall` or `/skills`; implicit invocation follows the description.
- Subagents: `features.multi_agent` (stable, on by default) gives `spawn_agent` / `wait_agent`; roles in `.codex/agents/*.toml` or `[agents.<name>]`; defaults via `agents.default_subagent_model`, `agents.default_subagent_reasoning_effort`.
- Headless: `codex exec -m <model> -s workspace-write -o <file> "<prompt>"`; `--json` streams JSONL events; `--output-schema` constrains the final message; `--ephemeral` keeps no session files.
- Sandbox: `-s read-only | workspace-write | danger-full-access`; approvals `-a on-request | never` (interactive).

## Heimdall adapter — writing packets for GPT / Codex executors

- Keep the packet prompt lean: goal, scope, Settled Decisions pointer, acceptance criteria, stopping rule, report format. Do not add "make a plan first" or "give status updates" lines in Codex.
- State autonomy explicitly ("make reasonable assumptions within Settled Decisions; stop only for destructive actions or contradictions with HANDOFF") — this counters GPT-6's tendency to ask.
- Scope verification ("run the test file for this module and the full suite once at the end") to avoid over-testing small packets.
- Markdown headings or XML tags both work; pick one per packet.
- Effort: Light packets `low` (Luna), Standard `medium` (6.1 Sol), Frontier `high` (Astra or 6.1 Sol); orchestrating from Codex: 6.1 Sol or Astra at medium/high.
- Dispatch from another harness: `codex exec -m gpt-6.1-sol -c model_reasoning_effort="medium" -s workspace-write -C <worktree> -o .heimdall/reports/T<nn>-coder-<r>.md "$(cat .heimdall/packets/T<nn>-coder-<r>.md)"` — only with the user's consent (harness-adapters.md).

## Unverified / conflicts

- The Codex CLI default model when `model` is unset is not named in the docs.
- No standalone GPT-6 prompting guide exists; the guidance above is a section of the latest-model page.
- Custom prompts (`~/.codex/prompts`) are deprecated in the docs in favor of skills.

## Sources

developers.openai.com/api/docs/models/{gpt-6-astra,gpt-6.1-sol,gpt-6-sol,gpt-6-luna,gpt-5.6,gpt-5.3-codex} · …/guides/latest-model · …/guides/model-selection · …/guides/reasoning · …/guides/reasoning-best-practices · …/guides/code-generation · cookbook: examples/gpt-5/codex_prompting_guide.ipynb, gpt-5_prompting_guide.ipynb, gpt-5-2_prompting_guide.ipynb · learn.chatgpt.com/docs/{models,build-skills,config-file/config-reference,agent-configuration/agents-md,custom-prompts} · github.com/openai/codex (agents_md.rs, host_roots.rs, exec/src/cli.rs) · local `codex --help`, `codex exec --help`, `codex features list`, `codex debug models` · Context7 `/openai/codex`, `/websites/developers_openai`, `/openai/openai-cookbook`, `/openai/openai-agents-python`.
