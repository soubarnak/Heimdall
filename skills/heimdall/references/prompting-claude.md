# Prompting — Anthropic Claude

Verified 2026-10-25 against platform.claude.com and code.claude.com (sources at the end). Apply prompting-universal.md first.

## Models and tiers

| Heimdall tier | Model ID | Context / max output | Default effort | Thinking | Use for |
|---|---|---|---|---|---|
| Frontier | `claude-fable-5-1` | 1M / 128K | high | adaptive, always on | hardest long-horizon agentic coding, research; highest cost |
| Frontier | `claude-opus-5-5` | 1M / 128K | medium | adaptive, always on | "long-running agentic coding and knowledge work"; default orchestrator |
| Standard | `claude-sonnet-5-5` | 1M / 128K | high | adaptive or `between_tools` | "best combination of speed and intelligence"; most executors |
| Light | `claude-haiku-5-5` | 1M / 128K | medium | adaptive; can be disabled at low–high | subagents, routing, extraction, mechanical packets |

- Effort values: `low`, `medium`, `high`, `xhigh`, `max` via `output_config.effort`; thinking via `thinking: {"type": "adaptive"}`. Setting `budget_tokens` returns 400 on 4.7 and later.
- Opus 5.5 and Fable 5.1 reject `thinking: disabled` and forced tool use (`tool_choice` forcing a specific tool). Haiku 5.5 still accepts forced tool use.
- Sonnet 5.5 returns 400 for `temperature`, `top_p`, `top_k`.
- Claude Code model aliases: `haiku`, `sonnet`, `opus`, `fable`, or a full ID; `/model` and `/effort` switch in-session.
- Claude Code can also drive other vendors' models through `ANTHROPIC_BASE_URL` (DeepSeek, Kimi, GLM, MiniMax, Meta document this). Then the *model's* family file applies, not this one.

## Core prompting rules (Anthropic)

1. **Be explicit.** "Think of Claude as a brilliant but new employee who lacks context on your norms and workflows." Say what to do, not what to avoid, and give the reason.
2. **XML tags** separate instructions, context, input, and examples: "Wrapping each type of content in its own tag … reduces misinterpretation." Use consistent, descriptive tag names (`<handoff>`, `<acceptance_criteria>`, `<repo_report>`).
3. **Examples:** "Include 3–5 examples for best results", wrapped in `<example>` / `<examples>`, relevant and diverse.
4. **Long context:** "Place your long documents and inputs near the top of your prompt, above your query, instructions, and examples"; queries at the end "can improve response quality by up to 30 percent."
5. **Action vs suggestion:** "If you say 'can you suggest some changes,' Claude will sometimes provide suggestions rather than implementing them." Say "make these changes."
6. **No blanket tool rules:** "Instructions such as 'If in doubt, use [tool]' cause overtriggering." Write targeted conditions.
7. **Thinking:** "Claude calibrates its thinking based on two factors: the `effort` parameter and query complexity." Control depth with effort, not with "think carefully" lines (Opus 5.5 guide: removing such lines made replies start sooner). For JSON-reasoning tasks on Sonnet 5.5, "Think the problem through before you answer." helps.
8. **Ground answers in files:** instruct the model to read relevant files before answering questions about code (Anthropic's `<investigate_before_answering>` pattern).

## Agentic and long-horizon guidance

- **State and fresh context:** Claude "can work on a complex task, save the state, and continue with a fresh context window." Use structured state (a tests/status file), plain-text progress notes, and git checkpoints. Heimdall's STATE.md, DECISIONS.md, and per-ticket worktrees and branches implement this.
- **Compaction:** tell the model what a compaction summary must preserve (Fable 5.1 guide). For Heimdall: current gate, Settled Decisions, open acceptance criteria, file paths of artifacts.
- **Subagents:** "Claude's latest models orchestrate subagents natively" — and over-use them. Scope it: "Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that don't need to share state." Fable 5.1: keep the lead agent working while subagents run.
- **Finishing:** Sonnet 5.5: "Keep working until everything the user asked for is done, and only stop to ask when you can't go on without the user or before a risky step." and "When the work the user asked for is done and checked, stop and report." Haiku 5.5 may stop early in long prompts; add the same instruction.
- **Verification:** Haiku 5.5 at low/medium "sometimes reports a code change as done without running a check" — require the check's output in the return report. Opus 5.5 (unattended): "Treat a text-only end of turn as a report rather than as proof the task is done."
- **Autonomous runs (Fable 5.1):** "You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task…" — then define what to do at a mandatory gate (stop and write STATE.md).
- **Over-engineering:** older Opus versions tended "to overengineer by creating extra files, adding unnecessary abstractions" (guide text written for 4.5/4.6). Keep a minimal-change instruction in executor packets.
- **Edits:** "Prefer targeted edits over whole-file rewrites." Batch independent reads: "First privately list what you need next; then request every item that doesn't depend on another's result in this one response."

## Heimdall adapter — writing packets for Claude executors

- Wrap HANDOFF excerpts, acceptance criteria, and the return-report format in XML tags.
- Tier: Haiku for Light packets only, with explicit finish-and-verify instructions; Sonnet for Standard; Opus (or Fable for the hardest) for Frontier and for the orchestrator.
- Effort: start at the model default (Opus medium, Sonnet high, Haiku medium); raise only for High-risk tickets.
- In Claude Code, dispatch packets as subagents (`.claude/agents/*.md` with `model:` and `effort:` fields, or the Agent tool) — see harness-adapters.md.
- Claude Code skills-specific frontmatter (`context: fork`, `model`, `effort`, `allowed-tools`) is not portable; Heimdall does not depend on it.

## Unverified

Haiku 5.5 release date. Exact Opus 5.5 / Sonnet 5.5 prompting pages were read in part.

## Sources

platform.claude.com/docs/en/models/{opus-5-5,sonnet-5-5,haiku-5-5,fable-5-1}/overview · …/build-with-claude/effort · …/build-with-claude/context-windows · …/build-with-claude/thinking-troubleshooting · …/build-with-claude/prompt-engineering/claude-prompting-best-practices · …/prompt-engineering/prompting-claude-{fable-5-1,opus-5-5,sonnet-5-5,haiku-5-5} · …/agents-and-tools/agent-skills/best-practices · code.claude.com/docs/en/{skills,sub-agents,plugins-reference,plugin-marketplaces,memory} · Context7 `/websites/platform_claude_en`, `/websites/platform_claude_en_api`.
