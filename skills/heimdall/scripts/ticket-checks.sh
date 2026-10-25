#!/usr/bin/env bash
# ticket-checks.sh - mechanical checks on a finished ticket, run before review.
#
# The build orchestrator copies this file to <project>/.heimdall/ticket-checks.sh
# at G3 setup and runs it from the main checkout after a coder reports a ticket
# done. It does not depend on where it is installed. It implements
# references/tdd-protocol.md section 6 (red-first evidence) and
# references/execution-loop.md section 5 (validate).
#
# Usage:
#   ticket-checks.sh --ticket T<nn> --worktree <abs path> --branch <branch> \
#     --integration <branch> --base <sha> --head <sha> \
#     --touch '<glob>' [--touch ...] --tests '<glob>' [--tests ...] \
#     [--lockfile '<glob>' ...] [--install '<cmd>'] --test-cmd '<cmd>' \
#     [--red required|skip] [--red-reason '<text>'] [--order required|skip] \
#     [--need-tests yes|no] [--scratch-root <dir>] [--timeout <seconds>] \
#     --out <abs report path>
#
# --test-cmd is needed only with --red required. --need-tests no is for tickets
# without tests to write (TDD: n/a, env); otherwise a diff without a changed test
# file is NO-TESTS, whatever --red says.
#
# Globs are matched against repo-relative paths with bash [[ == ]], where * also
# crosses /. Each glob is also tried with every "**/" removed. Test globs count
# as part of the touch set.
#
# Exit status: 0 = PASS, 1 = FAIL, 2 = usage error (nothing was checked).
#
# FAIL codes:
#   HEAD-MISMATCH    the ticket branch is not at the reported head sha
#   DIRTY-TREE       the ticket worktree has uncommitted or untracked files
#   BASE-NOT-SYNCED  base is not an ancestor of head or of the integration branch
#   OUT-OF-SCOPE     the diff touches a path outside the touch and tests globs
#   LOCKFILE-DRIFT   the diff touches a lockfile outside the touch set
#   COMMIT-ORDER     a feat commit has no test commit before it
#   NO-TESTS         the diff adds or changes no file matching the tests globs
#   NO-RED           the new tests already pass on the base code (any failing
#                    exit counts as RED; the reviewer reads the output to judge
#                    whether the failure is a missing behavior or a broken test)
#   SETUP-ERROR      install, copy or test run could not complete (or timed out)
#
# Read-only toward the ticket worktree and branch. It writes only a scratch
# worktree (always removed on exit) and the --out file.

set -u

usage() {
  sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
  printf 'ticket-checks: %s\n' "$*" >&2
  exit 2
}

need_val() { [ "$2" -ge 2 ] || die "$1 needs a value"; }

ticket="" worktree="" branch="" integration="" base_in="" head_in=""
install_cmd="" test_cmd="" red=required red_reason="" order=required need_tests=yes
scratch_root="" timeout_s=900 out=""
touch_globs=() test_globs=() lock_globs=()

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --ticket) need_val "$1" $#; ticket=$2; shift 2 ;;
    --worktree) need_val "$1" $#; worktree=$2; shift 2 ;;
    --branch) need_val "$1" $#; branch=$2; shift 2 ;;
    --integration) need_val "$1" $#; integration=$2; shift 2 ;;
    --base) need_val "$1" $#; base_in=$2; shift 2 ;;
    --head) need_val "$1" $#; head_in=$2; shift 2 ;;
    --touch) need_val "$1" $#; touch_globs+=("$2"); shift 2 ;;
    --tests) need_val "$1" $#; test_globs+=("$2"); shift 2 ;;
    --lockfile) need_val "$1" $#; lock_globs+=("$2"); shift 2 ;;
    --install) need_val "$1" $#; install_cmd=$2; shift 2 ;;
    --test-cmd) need_val "$1" $#; test_cmd=$2; shift 2 ;;
    --red) need_val "$1" $#; red=$2; shift 2 ;;
    --red-reason) need_val "$1" $#; red_reason=$2; shift 2 ;;
    --order) need_val "$1" $#; order=$2; shift 2 ;;
    --need-tests) need_val "$1" $#; need_tests=$2; shift 2 ;;
    --scratch-root) need_val "$1" $#; scratch_root=$2; shift 2 ;;
    --timeout) need_val "$1" $#; timeout_s=$2; shift 2 ;;
    --out) need_val "$1" $#; out=$2; shift 2 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
done

[ -n "$ticket" ] || die "--ticket is required"
[ -n "$worktree" ] || die "--worktree is required"
[ -n "$branch" ] || die "--branch is required"
[ -n "$integration" ] || die "--integration is required"
[ -n "$base_in" ] || die "--base is required"
[ -n "$head_in" ] || die "--head is required"
[ -n "$out" ] || die "--out is required"
[ "${#touch_globs[@]}" -gt 0 ] || die "at least one --touch is required"
[ "${#test_globs[@]}" -gt 0 ] || die "at least one --tests is required"
case $red in required|skip) ;; *) die "--red must be required or skip" ;; esac
case $order in required|skip) ;; *) die "--order must be required or skip" ;; esac
case $need_tests in yes|no) ;; *) die "--need-tests must be yes or no" ;; esac
case $timeout_s in ''|*[!0-9]*) die "--timeout must be a number of seconds" ;; esac
case $ticket in *[!A-Za-z0-9_-]*) die "--ticket has odd characters: $ticket" ;; esac
if [ "$red" = required ] && [ -z "$test_cmd" ]; then die "--test-cmd is required"; fi

W=$worktree
[ -d "$W" ] || die "worktree is not a directory: $W"
[ "$(git -C "$W" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] ||
  die "not a git worktree: $W"
base=$(git -C "$W" rev-parse --verify --quiet "$base_in^{commit}") || die "unknown base sha: $base_in"
head=$(git -C "$W" rev-parse --verify --quiet "$head_in^{commit}") || die "unknown head sha: $head_in"
integ=$(git -C "$W" rev-parse --verify --quiet "$integration^{commit}") || die "unknown integration branch: $integration"
bshort=$(git -C "$W" rev-parse --short "$base")
hshort=$(git -C "$W" rev-parse --short "$head")

out_dir=$(dirname "$out")
mkdir -p "$out_dir" 2>/dev/null && [ -w "$out_dir" ] || die "cannot write to $out_dir"

if [ -z "$scratch_root" ]; then scratch_root=$(dirname "$W"); fi
[ -d "$scratch_root" ] || die "scratch root is not a directory: $scratch_root"
scratch_root=$(cd "$scratch_root" && pwd -P)
ticket_lc=$(printf '%s' "$ticket" | tr '[:upper:]' '[:lower:]')
scratch=$scratch_root/scratch-$ticket_lc

is_registered_worktree() {
  local want real
  want=$1
  real=$(cd "$1" 2>/dev/null && pwd -P) || real=$1
  git -C "$W" worktree list --porcelain 2>/dev/null | while IFS= read -r line; do
    case $line in "worktree $want"|"worktree $real") echo yes; break ;; esac
  done | grep -q yes
}

scratch_stale=no
if [ "$red" = required ] && [ -e "$scratch" ]; then
  if is_registered_worktree "$scratch"; then
    scratch_stale=yes
  else
    die "scratch path exists and is not a registered worktree: $scratch"
  fi
fi

# --- helpers -----------------------------------------------------------------

scratch_made=no
# shellcheck disable=SC2329  # runs through the EXIT trap
cleanup() {
  if [ "$scratch_made" = yes ]; then
    git -C "$W" worktree remove --force "$scratch" >/dev/null 2>&1 || rm -rf "$scratch"
    git -C "$W" worktree prune >/dev/null 2>&1
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

glob_match() { # path glob
  local p=$1 g=$2 g2
  # shellcheck disable=SC2053
  [[ $p == $g ]] && return 0
  g2=${g//\*\*\//}
  # shellcheck disable=SC2053
  [[ $g2 != "$g" && $p == $g2 ]] && return 0
  return 1
}

match_any() { # path glob...
  local p=$1 g
  shift
  for g in "$@"; do glob_match "$p" "$g" && return 0; done
  return 1
}

default_lock_names="package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb uv.lock poetry.lock Pipfile.lock Cargo.lock go.sum Gemfile.lock composer.lock"
if [ "${#lock_globs[@]}" -eq 0 ]; then
  for n in $default_lock_names; do lock_globs+=("$n" "*/$n"); done
fi
all_scope=("${touch_globs[@]}" "${test_globs[@]}")

codes=()
add_code() {
  local c
  for c in ${codes[@]+"${codes[@]}"}; do [ "$c" = "$1" ] && return; done
  codes+=("$1")
}

join() { # sep items...
  local sep=$1 r="" i
  shift
  for i in "$@"; do r="${r:+$r$sep}$i"; done
  printf '%s' "$r"
}

notes=()
add_note() { notes+=("$1"); }

# git with quoting off so odd paths come back verbatim
g() { git -c core.quotepath=off --no-optional-locks -C "$W" "$@"; }

# --- 1. head -----------------------------------------------------------------
if branch_sha=$(g rev-parse --verify --quiet "$branch^{commit}"); then
  if [ "$branch_sha" = "$head" ]; then
    r_head="PASS ($branch @ $hshort)"
  else
    add_code HEAD-MISMATCH
    r_head="FAIL HEAD-MISMATCH (branch at $(g rev-parse --short "$branch_sha"), expected $hshort)"
  fi
else
  add_code HEAD-MISMATCH
  r_head="FAIL HEAD-MISMATCH (branch $branch not found, expected $hshort)"
fi

# --- 2. clean tree -----------------------------------------------------------
dirty=$(g status --porcelain 2>&1)
if [ -z "$dirty" ]; then
  r_clean="PASS"
else
  add_code DIRTY-TREE
  n_dirty=$(printf '%s\n' "$dirty" | wc -l | tr -d ' ')
  r_clean="FAIL DIRTY-TREE ($n_dirty entries)"
  while IFS= read -r l; do r_clean="$r_clean
    $l"; done < <(printf '%s\n' "$dirty" | head -n 20)
  [ "$n_dirty" -gt 20 ] && r_clean="$r_clean
    ... $((n_dirty - 20)) more"
fi

# --- 3. base -----------------------------------------------------------------
bad=()
g merge-base --is-ancestor "$base" "$head" || bad+=("base is not an ancestor of head")
g merge-base --is-ancestor "$base" "$integ" || bad+=("base is not an ancestor of $integration")
if [ "${#bad[@]}" -eq 0 ]; then
  r_base="PASS"
else
  add_code BASE-NOT-SYNCED
  r_base="FAIL BASE-NOT-SYNCED ($(join '; ' "${bad[@]}"))"
fi

# --- 4. scope ----------------------------------------------------------------
n_in=0 oos=() lock=()
while IFS= read -r p; do
  [ -n "$p" ] || continue
  if match_any "$p" "${all_scope[@]}"; then
    n_in=$((n_in + 1))
  elif match_any "$p" "${lock_globs[@]}"; then
    lock+=("$p")
  else
    oos+=("$p")
  fi
done < <(g diff --name-only --no-renames "$base...$head")
if [ "${#oos[@]}" -eq 0 ] && [ "${#lock[@]}" -eq 0 ]; then
  r_scope="PASS ($n_in files inside the touch set)"
else
  r_scope="FAIL"
  if [ "${#oos[@]}" -gt 0 ]; then
    add_code OUT-OF-SCOPE
    r_scope="$r_scope OUT-OF-SCOPE: $(join ', ' "${oos[@]}")"
  fi
  if [ "${#lock[@]}" -gt 0 ]; then
    add_code LOCKFILE-DRIFT
    [ "${#oos[@]}" -gt 0 ] && r_scope="$r_scope; FAIL"
    restore=""
    for p in "${lock[@]}"; do
      restore="${restore:+$restore; }git restore --source=$bshort -- $p"
    done
    r_scope="$r_scope LOCKFILE-DRIFT: $(join ', ' "${lock[@]}") (restore, in the ticket worktree: $restore)"
  fi
fi

# --- 5. commit order ---------------------------------------------------------
if [ "$order" = skip ]; then
  r_order="SKIPPED"
else
  n_test=0 n_feat=0 test_seen=0 order_bad=()
  prefix_re="^(test|feat|fix|refactor)\\($ticket\\):"
  while IFS=$'\t' read -r sha subj; do
    [ -n "$sha" ] || continue
    s=$(git -C "$W" rev-parse --short "$sha")
    if [[ $subj =~ $prefix_re ]]; then
      case ${BASH_REMATCH[1]} in
        test) n_test=$((n_test + 1)); test_seen=1 ;;
        feat)
          n_feat=$((n_feat + 1))
          if [ "$test_seen" -eq 0 ]; then
            in_commit=no
            while IFS= read -r p; do
              [ -n "$p" ] && match_any "$p" "${test_globs[@]}" && in_commit=yes
            done < <(g show --name-only --format= "$sha")
            if [ "$in_commit" = yes ]; then
              add_note "test and code in one commit $s: the report must quote the red output"
            else
              order_bad+=("$s $subj")
            fi
          fi
          test_seen=0
          ;;
      esac
    else
      add_note "commit $s has no $ticket conventional prefix: $subj"
    fi
  done < <(g log --reverse --no-merges --format='%H%x09%s' "$base..$head")
  if [ "${#order_bad[@]}" -eq 0 ]; then
    r_order="PASS ($n_test test, $n_feat feat commits)"
  else
    add_code COMMIT-ORDER
    r_order="FAIL COMMIT-ORDER: $(join '; ' "${order_bad[@]}")"
  fi
fi

# --- 6. tests and red at base -------------------------------------------------
tfiles=()
while IFS= read -r p; do
  [ -n "$p" ] && match_any "$p" "${test_globs[@]}" && tfiles+=("$p")
done < <(g diff --name-only --no-renames --diff-filter=AM "$base" "$head")
if [ "${#tfiles[@]}" -gt 0 ]; then
  r_tests="${#tfiles[@]} test files added or changed"
elif [ "$need_tests" = yes ]; then
  add_code NO-TESTS
  r_tests="FAIL NO-TESTS (no added or changed file matches the tests globs)"
else
  r_tests="none (not required for this ticket)"
fi

red_out="not run"
if [ "$red" = skip ]; then
  r_red="SKIPPED: ${red_reason:-no reason given}"
else
  if [ "${#tfiles[@]}" -eq 0 ]; then
    r_red="not run: no test files"
  else
    if [ "$scratch_stale" = yes ]; then
      git -C "$W" worktree remove --force "$scratch" >/dev/null 2>&1
      git -C "$W" worktree prune >/dev/null 2>&1
    fi
    step=""
    if wt_err=$(git -C "$W" worktree add --detach "$scratch" "$base" 2>&1); then
      scratch_made=yes
    else
      step="create scratch worktree"
      red_out=$wt_err
    fi

    run_limited() { # runs "$@" in the scratch tree, limited by --timeout when possible
      if command -v timeout >/dev/null 2>&1; then
        (cd "$scratch" && timeout "$timeout_s" "$@" </dev/null 2>&1)
      else
        (cd "$scratch" && "$@" </dev/null 2>&1)
      fi
    }

    if [ -z "$step" ] && [ -n "$install_cmd" ] && [ "$install_cmd" != none ]; then
      red_out=$(run_limited bash -c "$install_cmd"); rc=$?
      if [ "$rc" -eq 124 ]; then step="install (timed out after ${timeout_s}s)"
      elif [ "$rc" -ne 0 ]; then step="install (exit $rc)"; fi
    fi

    if [ -z "$step" ]; then
      for p in "${tfiles[@]}"; do
        if ! { mkdir -p "$scratch/$(dirname "$p")" && g show "$head:$p" >"$scratch/$p"; }; then
          step="copy test file $p"; red_out="could not copy $p from $hshort"; break
        fi
      done
    fi

    if [ -n "$step" ]; then
      add_code SETUP-ERROR
      r_red="FAIL SETUP-ERROR: $step"
    else
      red_out=$(run_limited bash -c "$test_cmd \"\$@\"" _ "${tfiles[@]}"); rc=$?
      if [ "$rc" -eq 124 ]; then
        add_code SETUP-ERROR
        r_red="FAIL SETUP-ERROR: test run (timed out after ${timeout_s}s)"
      elif [ "$rc" -eq 126 ] || [ "$rc" -eq 127 ]; then
        add_code SETUP-ERROR
        r_red="FAIL SETUP-ERROR: test run (command not runnable, exit $rc)"
      elif [ "$rc" -ne 0 ]; then
        r_red="RED (${#tfiles[@]} test files fail on the base code; judge the output below)"
      else
        add_code NO-RED
        r_red="FAIL NO-RED (the new tests pass on the base code)"
      fi
    fi
  fi
fi

# --- report ------------------------------------------------------------------
if [ "${#codes[@]}" -eq 0 ]; then
  verdict="CHECKS: PASS"; status=0
else
  verdict="CHECKS: FAIL: $(join ', ' "${codes[@]}")"; status=1
fi

{
  printf '%s\n' "$verdict"
  printf 'TICKET CHECKS — %s — head %s — base %s — %s\n' "$ticket" "$hshort" "$bshort" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf -- '- head: %s\n' "$r_head"
  printf -- '- clean tree: %s\n' "$r_clean"
  printf -- '- base: %s\n' "$r_base"
  printf -- '- scope: %s\n' "$r_scope"
  printf -- '- commit order: %s\n' "$r_order"
  printf -- '- tests: %s\n' "$r_tests"
  printf -- '- red-at-base: %s\n' "$r_red"
  printf '\n## Notes\n'
  if [ "${#notes[@]}" -eq 0 ]; then printf 'none\n'; else
    for n in "${notes[@]}"; do printf -- '- NOTE: %s\n' "$n"; done
  fi
  printf '\n## Commits\n'
  g log --reverse --no-merges --format='%h %s' "$base..$head"
  printf '\n## Red-at-base output (last 80 lines)\n'
  if [ "$red_out" = "not run" ]; then
    printf 'not run\n'
  else
    # shellcheck disable=SC2016  # the backticks are a literal markdown fence
    printf '```\n%s\n```\n' "$(printf '%s\n' "$red_out" | tail -n 80)"
  fi
} >"$out.tmp.$$"
if ! mv "$out.tmp.$$" "$out"; then rm -f "$out.tmp.$$"; die "could not write $out"; fi

cat "$out"
exit "$status"
