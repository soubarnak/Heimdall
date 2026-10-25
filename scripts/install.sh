#!/usr/bin/env bash
# Install the Heimdall agent skill into the skill folders read by coding-agent harnesses.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SRC="$REPO_ROOT/skills/heimdall"
SKILL=heimdall

ALL_HARNESSES=(claude codex muse opencode pi gemini agy qwen vibe grok kimi cursor copilot)

usage() {
  cat <<USAGE
Usage: install.sh [options]

Install the Heimdall skill (skills/heimdall) into harness skill folders.

Options:
  --scope user|project   Install scope (default: user)
  --project-dir DIR      Project directory for project scope (default: current dir)
  --harness LIST         auto (default), all, or comma-separated list of:
                         ${ALL_HARNESSES[*]}
  --link                 Symlink to this repo (default for user scope)
  --copy                 Copy the skill (default for project scope)
  --force                Replace an existing target that is not a link to this source
  --dry-run              Print actions only, change nothing
  --uninstall            Remove targets (only links to this source, or directories
                         whose SKILL.md frontmatter has name: heimdall)
  -h, --help             Show this help

Targets, user scope:    ~/.agents/skills/heimdall (shared), ~/.claude/skills/heimdall (claude),
                        ~/.qwen/skills/heimdall (qwen)
Targets, project scope: .agents/skills/heimdall (shared, all but grok), .grok/skills/heimdall (grok),
                        .claude/skills/heimdall (claude), .qwen/skills/heimdall (qwen)
USAGE
}

die() { echo "error: $*" >&2; exit 1; }

scope=user
project_dir=
harness_arg=auto
mode=
force=0
dry=0
uninstall=0

while [ $# -gt 0 ]; do
  case "$1" in
    --scope) [ $# -ge 2 ] || die "--scope needs a value"; scope=$2; shift 2 ;;
    --scope=*) scope=${1#*=}; shift ;;
    --project-dir) [ $# -ge 2 ] || die "--project-dir needs a value"; project_dir=$2; shift 2 ;;
    --project-dir=*) project_dir=${1#*=}; shift ;;
    --harness) [ $# -ge 2 ] || die "--harness needs a value"; harness_arg=$2; shift 2 ;;
    --harness=*) harness_arg=${1#*=}; shift ;;
    --link) mode="link"; shift ;;
    --copy) mode="copy"; shift ;;
    --force) force=1; shift ;;
    --dry-run) dry=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
done

case "$scope" in user|project) ;; *) die "--scope must be user or project" ;; esac
[ -z "$project_dir" ] || [ "$scope" = project ] || die "--project-dir only valid with --scope project"
[ -n "$mode" ] || { [ "$scope" = user ] && mode="link" || mode="copy"; }
[ -f "$SRC/SKILL.md" ] || die "skill source not found: $SRC"

if [ "$scope" = project ]; then
  [ -n "$project_dir" ] || project_dir=$PWD
  [ -d "$project_dir" ] || die "project dir not found: $project_dir"
  base=$(cd "$project_dir" && pwd -P)
else
  [ -n "${HOME:-}" ] || die "HOME is not set"
  base=$HOME
fi

# harness -> target path
target_for() {
  case "$scope:$1" in
    user:claude)     echo "$base/.claude/skills/$SKILL" ;;
    user:qwen)       echo "$base/.qwen/skills/$SKILL" ;;
    project:claude)  echo "$base/.claude/skills/$SKILL" ;;
    project:qwen)    echo "$base/.qwen/skills/$SKILL" ;;
    project:grok)    echo "$base/.grok/skills/$SKILL" ;;
    *)               echo "$base/.agents/skills/$SKILL" ;;
  esac
}

valid_harness() {
  local h
  for h in "${ALL_HARNESSES[@]}"; do [ "$h" = "$1" ] && return 0; done
  return 1
}

# auto detection: CLI on PATH or user config dir exists
detect() {
  local h cmd dir
  for h in "${ALL_HARNESSES[@]}"; do
    case "$h" in
      cursor)  cmd=cursor-agent ;;
      *)       cmd=$h ;;
    esac
    case "$h" in
      claude)   dir=$HOME/.claude ;;
      codex)    dir=$HOME/.codex ;;
      muse)     dir=$HOME/.config/muse ;;
      opencode) dir=$HOME/.config/opencode ;;
      pi)       dir=$HOME/.pi ;;
      gemini)   dir=$HOME/.gemini ;;
      agy)      dir= ;;
      qwen)     dir=$HOME/.qwen ;;
      vibe)     dir=$HOME/.vibe ;;
      grok)     dir=$HOME/.grok ;;
      kimi)     dir=$HOME/.kimi-code ;;
      cursor)   dir=$HOME/.cursor ;;
      copilot)  dir=$HOME/.copilot ;;
    esac
    if command -v "$cmd" >/dev/null 2>&1 || { [ -n "$dir" ] && [ -d "$dir" ]; }; then
      echo "$h"
    fi
  done
}

harnesses=()
fallback=0
case "$harness_arg" in
  all) harnesses=("${ALL_HARNESSES[@]}") ;;
  auto)
    while IFS= read -r h; do [ -n "$h" ] && harnesses+=("$h"); done < <(detect)
    if [ ${#harnesses[@]} -eq 0 ]; then
      fallback=1
      echo "No harness detected; falling back to the shared target only."
      harnesses=(codex)
    fi
    ;;
  *)
    IFS=',' read -r -a harnesses <<<"$harness_arg"
    for h in "${harnesses[@]}"; do
      valid_harness "$h" || die "unknown harness: '$h' (valid: ${ALL_HARNESSES[*]})"
    done
    ;;
esac

is_ours() { # path is a link to SRC, or a dir with name: heimdall frontmatter
  local t=$1
  if [ -L "$t" ]; then
    [ "$(readlink -f "$t" 2>/dev/null)" = "$SRC" ]
    return
  fi
  [ -d "$t" ] && [ -f "$t/SKILL.md" ] || return 1
  awk 'NR==1 && $0!="---" {exit 1}
       NR>1 && $0=="---" {exit f?0:1}
       NR>1 && /^name:[ \t]*"?heimdall"?[ \t]*$/ {f=1}
       END {if (NR==0) exit 1}' "$t/SKILL.md"
}

run() { # print or execute
  if [ "$dry" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi
}

declare -A done_target   # target -> action (dedupe)
rows=()
rc=0

for h in "${harnesses[@]}"; do
  t=$(target_for "$h")
  if [ -n "${done_target[$t]+x}" ]; then
    rows+=("$h|$t|same target as above")
    continue
  fi
  action=
  if [ "$uninstall" -eq 1 ]; then
    if [ ! -e "$t" ] && [ ! -L "$t" ]; then
      action="not installed"
    elif is_ours "$t"; then
      if [ -L "$t" ]; then run rm -- "$t"; else run rm -rf -- "$t"; fi
      action="removed"
    else
      action="SKIPPED (not Heimdall; left untouched)"
    fi
  else
    if [ -L "$t" ] && is_ours "$t"; then
      action="already installed"
      if [ "$mode" = copy ] && [ "$force" -eq 1 ]; then
        run rm -- "$t"; run mkdir -p -- "$(dirname "$t")"; run cp -R -- "$SRC" "$t"
        action="replaced link with copy"
      fi
    elif [ -e "$t" ] || [ -L "$t" ]; then
      if [ "$force" -eq 1 ]; then
        if [ -L "$t" ]; then run rm -- "$t"; else run rm -rf -- "$t"; fi
        run mkdir -p -- "$(dirname "$t")"
        if [ "$mode" = link ]; then run ln -s -- "$SRC" "$t"; else run cp -R -- "$SRC" "$t"; fi
        action="replaced ($mode)"
      else
        action="REFUSED (exists; use --force)"
        rc=1
      fi
    else
      run mkdir -p -- "$(dirname "$t")"
      if [ "$mode" = link ]; then run ln -s -- "$SRC" "$t"; else run cp -R -- "$SRC" "$t"; fi
      action="installed ($mode)"
    fi
  fi
  done_target[$t]=$action
  rows+=("$h|$t|$action")
done

echo
label=install; [ "$uninstall" -eq 1 ] && label=uninstall
echo "Heimdall $label | scope=$scope mode=$mode$([ "$dry" -eq 1 ] && echo ' | DRY RUN')"
printf '%-10s %-12s %s\n' HARNESS ACTION TARGET
for r in "${rows[@]}"; do
  IFS='|' read -r h t a <<<"$r"
  printf '%-10s %s\n' "$h" "-> $t"
  printf '%-10s   %s\n' "" "$a"
done

[ "$uninstall" -eq 1 ] && exit "$rc"

echo
echo "Verify:"
for h in "${harnesses[@]}"; do
  t=$(target_for "$h")
  case "$h" in
    claude)   echo "  claude:   run /heimdall or ask 'use Heimdall'" ;;
    codex)    echo "  codex:    \$heimdall" ;;
    muse)     echo "  muse:     muse skills validate $t; muse skills list --source all" ;;
    opencode) echo "  opencode: start opencode, then ask to use the heimdall skill" ;;
    pi)       echo "  pi:       pi --skill $t, or start pi and ask" ;;
  esac
done
echo
echo "Notes:"
echo "  - Claude Code users can alternatively use the plugin marketplace route (see INSTALL.md)."
echo "  - Muse and OpenCode also read ~/.claude/skills, so they may list the skill twice"
echo "    (same content, harmless)."
[ "$fallback" -eq 1 ] && echo "  - No harness was detected; only the shared target was used. Pass --harness to choose."
exit "$rc"
