# Installing Heimdall

This file is written for an AI coding agent that has been given the repository URL and asked to install the Heimdall skill. People can follow it too.

- Repository: `https://github.com/soubarnak/Heimdall` (public; no credentials needed)
- Skill directory inside the repository: `skills/heimdall/` (the folder that contains `SKILL.md`)
- Skill name: `heimdall`

## Instructions for the installing agent

1. **Identify your harness:** the tool you are running in (Claude Code, Codex CLI, Muse Code, and so on), not the model. If you cannot tell, ask the user. If you have no shell or file tools, you are in a chat app; go to "Chat apps".
2. **Install** with the universal method (A) and your harness's `--harness` value, or with the native method for your harness (B to G). Use user scope (all projects) unless the user asks for one project only.
3. **Verify** with "Verify the install".
4. **Report to the user:** where the skill was installed; that skills load when a session starts, so they must start a new session; how to invoke it; and the tracker setup if they want GitHub or Gitea issues ("Tracker setup").

Do not modify the skill files during installation. Do not install Docker; Heimdall uses rootless podman when a project needs containers.

## Harness table

| Harness | `--harness` value | Native method | Invoke with |
|---|---|---|---|
| Claude Code | `claude` | B. Plugin | `/heimdall` (plugin: `/heimdall:heimdall`) |
| Codex CLI | `codex` | C. Skills CLI, D. `$skill-installer` | `$heimdall` or `/skills` |
| Muse Code | `muse` | E. `muse skills install` | `/heimdall` |
| OpenCode | `opencode` | C. Skills CLI | ask "use Heimdall" |
| pi | `pi` | F. `pi install` | `/heimdall` or ask |
| Gemini CLI | `gemini` | G. `gemini skills install` | `/heimdall` or ask |
| Antigravity CLI | `agy` | — | ask "use Heimdall" |
| Qwen Code | `qwen` | — | `/heimdall` or ask |
| Mistral Vibe | `vibe` | — | ask "use Heimdall" |
| Grok Build | `grok` | — | ask "use Heimdall" |
| Kimi Code CLI | `kimi` | — | ask "use Heimdall" |
| Cursor | `cursor` | C. Skills CLI | ask "use Heimdall" |
| GitHub Copilot | `copilot` | — | ask "use Heimdall" |
| Chat app (claude.ai, ChatGPT, Meta AI) | — | see "Chat apps" | — |

Every harness also activates the skill from its description when the user says "use Heimdall" or "take this idea to shipment".

## A. Universal method: clone and install script

Works in every harness that can run bash (Linux, macOS, WSL, Git Bash). Running it again updates the skill.

```bash
d="$HOME/.local/share/heimdall"
if [ -d "$d/.git" ]; then git -C "$d" pull --ff-only; else git clone --depth 1 https://github.com/soubarnak/Heimdall.git "$d"; fi
"$d/scripts/install.sh" --harness <value from the table>
```

The script links (user scope) or copies (project scope) `skills/heimdall` into:

- `~/.agents/skills/heimdall`, which Codex CLI, Muse Code, OpenCode, pi, Gemini CLI, Mistral Vibe, Grok Build, Kimi Code CLI, Cursor, and GitHub Copilot read;
- `~/.claude/skills/heimdall` for Claude Code;
- `~/.qwen/skills/heimdall` for Qwen Code.

Options:

```bash
"$d/scripts/install.sh" --dry-run                                  # show what it would do
"$d/scripts/install.sh"                                            # auto: harnesses found on PATH or in config folders
"$d/scripts/install.sh" --harness all                              # every target
"$d/scripts/install.sh" --harness claude,codex                     # several harnesses
"$d/scripts/install.sh" --scope project --project-dir ~/code/myapp # copy into one project
"$d/scripts/install.sh" --uninstall                                # remove what it installed
```

It never overwrites a directory it did not create unless you pass `--force`. With no harness detected, it installs only the shared `~/.agents/skills` target and says so.

### Windows without bash

In PowerShell. This copies the skill; run it again to update.

```powershell
git clone --depth 1 https://github.com/soubarnak/Heimdall.git "$HOME\.local\share\heimdall"
foreach ($t in "$HOME\.agents\skills", "$HOME\.claude\skills") {
  New-Item -ItemType Directory -Force $t | Out-Null
  Remove-Item -Recurse -Force "$t\heimdall" -ErrorAction SilentlyContinue
  Copy-Item -Recurse "$HOME\.local\share\heimdall\skills\heimdall" "$t\heimdall"
}
```

If the clone folder already exists, run `git -C "$HOME\.local\share\heimdall" pull` instead of `git clone`. Add `"$HOME\.qwen\skills"` to the list for Qwen Code.

## B. Claude Code plugin

This repository is its own plugin marketplace (`.claude-plugin/marketplace.json`).

```bash
claude plugin install heimdall --marketplace soubarnak/Heimdall     # Claude Code 2.1.275 or later
```

On older versions: `claude plugin marketplace add soubarnak/Heimdall`, then `claude plugin install heimdall@heimdall`. Inside a session the command is `/plugin install heimdall --marketplace soubarnak/Heimdall`. Invoke the skill as `/heimdall:heimdall`. Update with `claude plugin marketplace update heimdall`, then `claude plugin update heimdall@heimdall`. Use either the plugin or method A for Claude Code, not both.

## C. Skills CLI (`npx skills`)

Needs Node.js. Links the skill into the folders of the harnesses you name.

```bash
npx skills add soubarnak/Heimdall -g -a codex          # user scope, one harness (examples: codex, claude-code, cursor, opencode, pi)
npx skills add soubarnak/Heimdall -a codex             # project scope: run in the project root
```

Update with `npx skills update`. Remove with `npx skills remove heimdall`.

## D. Codex CLI built-in installer

In a Codex session:

```
$skill-installer install https://github.com/soubarnak/Heimdall/tree/main/skills/heimdall
```

Restart Codex afterwards. The installer's exact argument form is not documented; if it rejects the URL, use method A.

## E. Muse Code

`muse skills install` takes a local path, so clone first (the first two lines of method A), then:

```bash
muse skills validate "$HOME/.local/share/heimdall/skills/heimdall"
muse skills install "$HOME/.local/share/heimdall/skills/heimdall" --scope user
```

## F. pi

```bash
pi install git:github.com/soubarnak/Heimdall
```

## G. Gemini CLI

```bash
gemini skills install https://github.com/soubarnak/Heimdall.git --path skills/heimdall --consent
```

## Chat apps

Chat apps without file tools cannot install skills from a repository. Two options for the user:

- Upload `skills/heimdall/SKILL.md` and the files in `skills/heimdall/references/` and `skills/heimdall/assets/` as project knowledge (claude.ai Projects, ChatGPT Projects or custom GPTs, Meta AI), and use the body of `SKILL.md` as the project instructions. Heimdall then runs in its chat profile: it runs the planning gates and hands the build loop to a coding agent.
- Or install it in a coding agent with the methods above and keep the chat app for planning.

## Verify the install

```bash
for f in ~/.agents/skills/heimdall/SKILL.md ~/.claude/skills/heimdall/SKILL.md ~/.qwen/skills/heimdall/SKILL.md; do
  [ -f "$f" ] && echo "$f: $(sed -n 2p "$f")"
done
```

Each installed target prints `name: heimdall`. Then the user starts a new session in the harness and asks "Use Heimdall. What can you do?". A working install runs calibration and describes its three modes (Build, Direct, Prompt). Harness checks:

- Claude Code: `/heimdall` (or `/heimdall:heimdall`) appears in the slash-command menu.
- Codex CLI: `/skills` lists `heimdall`.
- Muse Code: `muse skills validate <path>` reports the skill as valid.

From a clone you can also run the repository's own checks: `scripts/validate.sh`.

## Tracker setup

Heimdall tracks progress as issues on GitHub, on Gitea, or as local files. The user signs in once; the agent never handles tokens.

- **GitHub:** the `gh` CLI (commands verified with 2.103.1), signed in with `gh auth login`. Blocking relationships use GitHub's issue dependencies API, with a fallback to a `Blocked by` section in the issue body.
- **Gitea:** the `tea` CLI (commands verified with tea 0.16.0 against Gitea 1.27.1), signed in with `tea login add`. Native blocking edges need issue dependencies enabled for the repository; otherwise Heimdall falls back to a `Blocked by` section in the issue body.
- **Local:** nothing to install. Tickets live in `.heimdall/tickets/`.

Other prerequisites for Build mode: git 2.38 or later (for `git merge-tree --write-tree`), the test tooling of the project's stack, and rootless podman if the project needs containers.

## Update and uninstall

| Method | Update | Uninstall |
|---|---|---|
| A. Clone and script | run the method A commands again | `"$HOME/.local/share/heimdall/scripts/install.sh" --uninstall` |
| B. Claude plugin | `claude plugin marketplace update heimdall`, then `claude plugin update heimdall@heimdall` | `claude plugin uninstall heimdall@heimdall` |
| C. Skills CLI | `npx skills update` | `npx skills remove heimdall` |
| D, E, F, G | run the install command again | the harness's skill-removal command, or delete the skill folder |

## Troubleshooting

- **The skill does not appear:** start a new session; check the folder for your harness above; for project scope, check that the folder is trusted (Muse Code, pi, Gemini CLI, and Mistral Vibe load project skills only in trusted folders).
- **The skill is listed twice:** some harnesses read several folders (Muse Code, OpenCode, and Cursor also read `~/.claude/skills`). Both entries are the same skill.
- **`git pull --ff-only` fails:** the clone was edited locally. Delete `~/.local/share/heimdall` and run method A again.
- **Claude Code ignores `AGENTS.md`:** Claude Code reads `CLAUDE.md`. Heimdall writes a `CLAUDE.md` containing `@AGENTS.md` in projects it builds.
