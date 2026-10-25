# Installing Heimdall

This file is written for an AI coding agent that has been given the repository URL and asked to install the Heimdall skill. Humans can follow it too.

- Repository: `https://github.com/soubarnak/Heimdall` (private: you need read access)
- Skill directory inside the repo: `skills/heimdall/` (the folder containing `SKILL.md`)
- Skill name: `heimdall`

## Instructions for the installing agent

1. **Identify your harness.** Use the table in step 3. If you cannot tell, ask the user which tool they run you in.
2. **Check access to the private repository** before anything else (see "Private repository access"). If access fails, stop and tell the user exactly which command failed. Never ask the user to paste a token into the chat.
3. **Install with the method for your harness.** Use the first row that matches. User scope (all projects) is the default; use project scope only if the user asks for it.
4. **Verify** with the checks in "Verify the install".
5. **Report to the user:** where the skill was installed, how to invoke it in their harness, and the tracker setup they still need ("Tracker setup").

Do not modify the skill files during installation. Do not install Docker; Heimdall uses rootless podman when it needs containers.

## Private repository access

Every install method below fetches from GitHub with the user's own git credentials.

```bash
gh auth status                  # must show a signed-in account with access to soubarnak/Heimdall
gh auth setup-git               # lets plain git (and installers that use it) authenticate through gh
gh repo view soubarnak/Heimdall --json name -q .name    # prints "Heimdall" when access works
```

If `gh` is missing or not signed in, ask the user to run `gh auth login` themselves. SSH access (`git@github.com:soubarnak/Heimdall.git`) also works for the clone-based methods.

## Install per harness

| Harness | Recommended method | Invoke with |
|---|---|---|
| Claude Code | Plugin marketplace (A) or clone and script (G) | `/heimdall:heimdall` (plugin) or `/heimdall` (skills folder) |
| Codex CLI | Skills CLI (B), `$skill-installer` (C), or clone and script (G) | `$heimdall` or `/skills` |
| Gemini CLI | `gemini skills install` (D) | `/heimdall` or by description |
| Muse Code | Clone, validate, install (E) | `/heimdall` or by description |
| pi | `pi install` (F) or clone and script (G) | `/heimdall` or by description |
| OpenCode, Qwen Code, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, GitHub Copilot, Antigravity CLI | Skills CLI (B) or clone and script (G) | `/heimdall`, the skill picker, or by description |
| A chat app without file tools (claude.ai, ChatGPT, Meta AI) | Not installable as a skill; see "Chat apps" | — |

Every harness also activates the skill from its description: "use Heimdall", "take this idea to shipment".

### A. Claude Code plugin marketplace

This repository is its own plugin marketplace (`.claude-plugin/marketplace.json`).

```bash
gh auth setup-git                                   # private repo: git must be able to authenticate
claude plugin install heimdall --marketplace soubarnak/Heimdall     # one step (Claude Code 2.1.275 or later)
```

On older versions, add the marketplace first: `claude plugin marketplace add soubarnak/Heimdall`, then `claude plugin install heimdall@heimdall`. Inside a Claude Code session the same command is `/plugin install heimdall --marketplace soubarnak/Heimdall`. Invoke the skill as `/heimdall:heimdall`. Update with `claude plugin marketplace update heimdall`, then `claude plugin update heimdall@heimdall`.

### B. Skills CLI (`npx skills`) — most Agent Skills harnesses

The Skills CLI clones the repository (it tries your git credentials, then `gh repo clone`, then SSH) and links the skill into each harness's folder.

```bash
npx skills add soubarnak/Heimdall -g                 # user scope, every detected harness
npx skills add soubarnak/Heimdall -g -a codex        # user scope, one harness
npx skills add soubarnak/Heimdall                    # project scope (run in the project root)
```

Update with `npx skills update`. Remove with `npx skills remove heimdall`.

### C. Codex CLI built-in installer

In a Codex session, ask the built-in installer for the skill directory:

```
$skill-installer install https://github.com/soubarnak/Heimdall/tree/main/skills/heimdall
```

Restart Codex afterwards so it loads the new skill. The installer's exact argument form is not documented; if it rejects the URL, use method B or G.

### D. Gemini CLI

```bash
gemini skills install https://github.com/soubarnak/Heimdall.git --path skills/heimdall --consent
```

Gemini CLI also reads `~/.agents/skills/`, so method G works as well. How `gemini skills install` authenticates to a private repository is not documented; if it fails, use method G.

### E. Muse Code

`muse skills install` takes a local path, so clone first:

```bash
git clone https://github.com/soubarnak/Heimdall.git ~/.local/share/heimdall
muse skills validate ~/.local/share/heimdall/skills/heimdall
muse skills install ~/.local/share/heimdall/skills/heimdall --scope user
```

Muse Code also reads `~/.agents/skills/`, so method G works as well.

### F. pi

```bash
pi install git:github.com/soubarnak/Heimdall
```

pi also reads `~/.agents/skills/`, so method G works as well.

### G. Clone and install script — works for every harness

```bash
git clone https://github.com/soubarnak/Heimdall.git ~/.local/share/heimdall
~/.local/share/heimdall/scripts/install.sh --dry-run      # shows what it would do
~/.local/share/heimdall/scripts/install.sh                # user scope, harnesses detected on PATH
```

The script links (user scope) or copies (project scope) `skills/heimdall` into:

- `~/.agents/skills/heimdall`, which serves Codex, Muse Code, OpenCode, pi, Gemini CLI, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, and GitHub Copilot;
- `~/.claude/skills/heimdall` for Claude Code;
- `~/.qwen/skills/heimdall` for Qwen Code.

Useful options:

```bash
scripts/install.sh --harness all                          # every target, detected or not
scripts/install.sh --harness claude,codex                 # only these harnesses
scripts/install.sh --scope project --project-dir ~/code/myapp    # copy into a project
scripts/install.sh --uninstall                            # remove what it installed
```

It never overwrites a directory it did not create unless you pass `--force`. With the default link mode, `git -C ~/.local/share/heimdall pull` updates every harness at once.

### Chat apps

Chat apps without file tools cannot load skills from a repository. Two options:

- Upload `skills/heimdall/SKILL.md` and the files in `skills/heimdall/references/` and `skills/heimdall/assets/` as project knowledge (claude.ai Projects, ChatGPT Projects or custom GPTs, Meta AI), and use `SKILL.md` as the project instructions. Heimdall then runs in its chat profile: it runs the planning gates and hands the build loop to a coding agent.
- Or install it in a coding agent with the methods above and keep the chat app for planning only.

## Verify the install

```bash
ls ~/.agents/skills/heimdall/SKILL.md ~/.claude/skills/heimdall/SKILL.md 2>/dev/null   # whichever you installed
head -3 ~/.agents/skills/heimdall/SKILL.md                                             # shows name: heimdall
```

Then, in the harness, start a new session and ask: "Use Heimdall. What can you do?" A working install answers with its three modes (Build, Direct, Prompt) and runs calibration first. Harness-specific checks:

- Claude Code: `/heimdall` (or `/heimdall:heimdall`) appears in the slash-command menu.
- Codex CLI: `/skills` lists `heimdall`.
- Muse Code: `muse skills validate <path>` prints that the skill is valid.

From a clone you can also run the repository's own checks: `scripts/validate.sh`.

## Tracker setup

Heimdall tracks progress as issues on GitHub, on Gitea, or as local files. The user signs in once; the agent never handles tokens.

- **GitHub:** the `gh` CLI (commands verified with 2.103.1), signed in with `gh auth login`. Blocking relationships use GitHub's issue dependencies API, with a fallback to a `Blocked by` section in the issue body.
- **Gitea:** the `tea` CLI (commands verified with tea 0.16.0 against Gitea 1.27.1), signed in with `tea login add`. Native blocking edges need issue dependencies enabled for the repository; otherwise Heimdall falls back to a `Blocked by` section in the issue body.
- **Local:** nothing to install. Tickets live in `.heimdall/tickets/`.

Other prerequisites for Build mode: git 2.38 or later (for `git merge-tree --write-tree`), and the test tooling of the project's stack. Podman (rootless) if the project needs containers.

## Update and uninstall

| Method | Update | Uninstall |
|---|---|---|
| A. Claude plugin | `claude plugin marketplace update heimdall`, then `claude plugin update heimdall@heimdall` | `claude plugin uninstall heimdall@heimdall` |
| B. Skills CLI | `npx skills update` | `npx skills remove heimdall` |
| C, D, E, F | re-run the install command | the harness's skill-removal command, or delete the skill folder |
| G. Clone and script | `git -C ~/.local/share/heimdall pull` (link mode) | `scripts/install.sh --uninstall` |

## Troubleshooting

- **"Repository not found" or 404:** the account lacks access to the private repository, or git is not using the `gh` credentials. Run `gh auth status` and `gh auth setup-git`.
- **The skill does not appear:** restart the harness; check the folder for your harness in the table above; check that the project folder is trusted (Muse Code, pi, Gemini CLI, Mistral Vibe load project skills only in trusted folders).
- **Claude Code ignores `AGENTS.md`:** Claude Code reads `CLAUDE.md`. Heimdall writes a `CLAUDE.md` containing `@AGENTS.md` in projects it builds.
- **Two copies conflict:** some harnesses read several folders (Muse Code and Cursor also read `~/.claude/skills`). Both copies are the same skill; if they diverge, reinstall with one method.
