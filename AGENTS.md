# AGENTS.md — working on the Heimdall repository

This repository contains one Agent Skill, `skills/heimdall/`. These instructions are for agents that edit the skill itself. To install the skill, follow INSTALL.md. To use it, invoke it in your harness ("use Heimdall").

## Layout

- `skills/heimdall/SKILL.md` — entry point. Frontmatter `name` must stay `heimdall` and match the directory name; `description` at most 1024 characters; `compatibility` at most 500; `metadata` values are quoted strings. Keep the body under 500 lines.
- `skills/heimdall/references/` — protocols, loaded on demand. One level deep: references point to other references and assets, never to nested folders.
- `skills/heimdall/assets/` — templates the skill fills. Their shape is a contract with the protocols that cite them.
- `scripts/install.sh`, `scripts/validate.sh` — installer and checks. Both must stay POSIX-friendly bash with no dependencies beyond git and python3.
- `.claude-plugin/` — Claude Code plugin and marketplace manifests. Keep `version` equal to `metadata.version` in SKILL.md.
- `docs/ADAPTATION_REPORT.md` — the design record. Update it when a design decision changes.

## Rules for changes

1. **Keep the index whole.** Every file in `references/` and `assets/` is listed in SKILL.md's reference index or asset list. Adding, renaming, or removing a file updates SKILL.md in the same change.
2. **One source per fact.** Naming conventions (ticket ids, branch and worktree names, packet and report paths, labels, status tokens) are defined in production-orchestrator.md, execution-loop.md, and agent-roles.md; other files cite them. Change all citing files together, then grep for the old form.
3. **Model and harness facts are dated.** agent-model-map.md, the prompting files, harness-adapters.md, and the tracker files say when and against what they were verified. Update the date with the facts, and mark anything not verified as UNVERIFIED rather than guessing.
4. **Write for any model.** No instructions that only one vendor's model or harness can follow, unless the text names that harness.
5. **No secrets, ever.** No tokens, keys, or personal credentials in any file. `scripts/validate.sh` scans for common token shapes.
6. **Containers mean podman.** Examples use rootless podman and `Containerfile`; never Docker.
7. **Run the checks** before committing: `scripts/validate.sh` must end with no FAIL lines. If the `claude` or `muse` CLIs are installed, the script also runs their validators.
8. **Versioning.** Bump `metadata.version` in SKILL.md and `version` in `.claude-plugin/plugin.json` together, and add a CHANGELOG.md entry.
