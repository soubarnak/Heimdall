#!/usr/bin/env bash
# Read-only validation of the Heimdall skill repo. Exit 1 if any FAIL.
# Optional: HEIMDALL_ROOT overrides the repo root (used for testing fixtures).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="${HEIMDALL_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd -P)}"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: validate.sh   (read-only checks of skills/heimdall, plugin manifests, secrets)"
  exit 0
fi

command -v python3 >/dev/null 2>&1 || { echo "FAIL python3 not found"; exit 1; }

rc=0
python3 -I - "$ROOT" <<'PY' || rc=$?
import json, os, re, sys

root = sys.argv[1]
skill_dir = os.path.join(root, "skills", "heimdall")
skill_md = os.path.join(skill_dir, "SKILL.md")
fails = 0

def p(level, msg):
    global fails
    if level == "FAIL":
        fails += 1
    print(f"{level} {msg}")

def rel(path):
    return os.path.relpath(path, root)

# Names that look like .md files but are not skill files (external/generic names).
ALLOW_MD = {"readme.md", "skill.md", "agents.md", "claude.md", "gemini.md", "state.md",
            "changelog.md", "install.md", "license.md", "contributing.md"}

version = None
body_lines = []

# 1. SKILL.md exists, starts with frontmatter
fm = None
if not os.path.isfile(skill_md):
    p("FAIL", "skills/heimdall/SKILL.md missing")
else:
    text = open(skill_md, encoding="utf-8").read()
    lines = text.split("\n")
    if lines[0].strip() != "---":
        p("FAIL", "SKILL.md does not start with --- frontmatter")
    else:
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
        if end is None:
            p("FAIL", "SKILL.md frontmatter not closed")
        else:
            p("PASS", "SKILL.md has frontmatter")
            fm_lines = lines[1:end]
            body_lines = lines[end + 1:]
            # minimal YAML subset parser: top-level keys, one-level nested maps
            fm = {}
            cur = None
            for ln in fm_lines:
                if not ln.strip() or ln.lstrip().startswith("#"):
                    continue
                m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", ln)
                if m and not ln.startswith((" ", "\t")):
                    k, v = m.group(1), m.group(2).strip()
                    if v == "":
                        fm[k] = {}
                        cur = k
                    else:
                        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
                            v = v[1:-1]
                        fm[k] = v
                        cur = None
                else:
                    m2 = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(.*)$", ln)
                    if m2 and cur is not None and isinstance(fm.get(cur), dict):
                        v = m2.group(2).strip()
                        quoted = len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'"
                        if quoted:
                            v = v[1:-1]
                        fm[cur][m2.group(1)] = (v, quoted)

# 2. Frontmatter fields
if fm is not None:
    name = fm.get("name")
    if name != "heimdall":
        p("FAIL", f"frontmatter name is {name!r}, expected 'heimdall'")
    elif os.path.basename(skill_dir) != name:
        p("FAIL", "name does not match directory name")
    elif len(name) > 64 or not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", name):
        p("FAIL", "name violates format (^[a-z0-9]+(-[a-z0-9]+)*$, <=64)")
    else:
        p("PASS", "name == heimdall == directory name, format ok")
    d = fm.get("description")
    if not isinstance(d, str) or not d:
        p("FAIL", "description missing or empty")
    elif len(d) > 1024:
        p("FAIL", f"description too long ({len(d)} > 1024)")
    else:
        p("PASS", f"description ok ({len(d)} chars)")
    c = fm.get("compatibility")
    if c is not None:
        if not isinstance(c, str) or len(c) > 500:
            p("FAIL", "compatibility must be a string <= 500 chars")
        else:
            p("PASS", f"compatibility ok ({len(c)} chars)")
    allowed = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
    for k in fm:
        if k not in allowed:
            p("WARN", f"unexpected frontmatter key: {k}")
    md = fm.get("metadata")
    if isinstance(md, dict):
        bad = [k for k, (v, q) in md.items() if not q and not re.match(r"^\S*[A-Za-z]\S*$", v)]
        # unquoted numeric-looking values parse as non-strings in YAML
        bad += [k for k, (v, q) in md.items() if not q and re.match(r"^[0-9.]+$", v)]
        for k in sorted(set(bad)):
            p("FAIL", f"metadata.{k} must be a string (quote it)")
        if not bad:
            p("PASS", "metadata values are strings")
        if "version" in md:
            version = md["version"][0]
    elif md is not None:
        p("FAIL", "metadata must be a mapping")

# 3. body length
if body_lines:
    n = len(body_lines)
    if n >= 500:
        p("FAIL", f"SKILL.md body is {n} lines (limit < 500)")
    elif n >= 400:
        p("WARN", f"SKILL.md body is {n} lines (>= 400)")
    else:
        p("PASS", f"SKILL.md body {n} lines")

# 4. every references/*.md mentioned in SKILL.md
ref_dir = os.path.join(skill_dir, "references")
asset_dir = os.path.join(skill_dir, "assets")
refs = sorted(f for f in os.listdir(ref_dir) if f.endswith(".md")) if os.path.isdir(ref_dir) else []
assets = sorted(f for f in os.listdir(asset_dir) if f.endswith(".md")) if os.path.isdir(asset_dir) else []
if os.path.isfile(skill_md):
    st = open(skill_md, encoding="utf-8").read()
    missing = [f for f in refs if f not in st]
    for f in missing:
        p("FAIL", f"references/{f} not mentioned in SKILL.md")
    if not missing:
        p("PASS", f"all {len(refs)} reference files listed in SKILL.md")

# 5. dangling .md references
known = set(refs) | set(assets) | {"SKILL.md"}
tok = re.compile(r"\b[a-z0-9]+(?:-[a-z0-9]+)*\.md\b")
md_files = []
for dp, dn, fn in os.walk(skill_dir):
    for f in fn:
        if f.endswith(".md"):
            md_files.append(os.path.join(dp, f))
dangling = 0
for path in sorted(md_files):
    in_sources = False
    in_fence = False
    for i, ln in enumerate(open(path, encoding="utf-8").read().split("\n"), 1):
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
        h = re.match(r"^(#+)\s+(.*)$", ln) if not in_fence else None
        if h:
            in_sources = h.group(2).strip().lower() == "sources" and len(h.group(1)) == 2
        if in_sources:
            continue
        for m in tok.finditer(ln):
            s = m.start()
            if s > 0 and ln[s - 1] in "/.":
                continue
            t = m.group(0)
            if t in known or t.lower() in ALLOW_MD:
                continue
            # part of URL or path-like token (e.g. https://x/y-z.md handled above; also host.name-x.md)
            if re.search(r"[A-Za-z0-9_.-]/[^\s]*" + re.escape(t) + r"$", ln[:m.end()].split()[-1] if ln[:m.end()].split() else ""):
                continue
            p("FAIL", f"dangling reference {t} at {rel(path)}:{i}")
            dangling += 1
if not dangling:
    p("PASS", "no dangling .md references")

# 6. whole-line backtick-wrapped prose
wrapped = 0
for path in sorted(md_files):
    in_fence = False
    for i, ln in enumerate(open(path, encoding="utf-8").read().split("\n"), 1):
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if re.match(r"^`[^`].*`$", ln):
            p("WARN", f"whole-line backtick-wrapped text at {rel(path)}:{i}")
            wrapped += 1
if not wrapped:
    p("PASS", "no whole-line backtick-wrapped prose")

# 7. plugin manifests
pj = os.path.join(root, ".claude-plugin", "plugin.json")
mj = os.path.join(root, ".claude-plugin", "marketplace.json")
pj_data = None
for path in (pj, mj):
    if not os.path.isfile(path):
        p("WARN", f"{rel(path)} absent")
        continue
    try:
        data = json.load(open(path, encoding="utf-8"))
        p("PASS", f"{rel(path)} parses as JSON")
        if path == pj:
            pj_data = data
    except Exception as e:
        p("FAIL", f"{rel(path)} invalid JSON: {e}")
if pj_data is not None:
    pv = pj_data.get("version") if isinstance(pj_data, dict) else None
    if version is None:
        p("WARN", "no SKILL.md metadata.version to compare with plugin.json")
    elif pv != version:
        p("FAIL", f"plugin.json version {pv!r} != SKILL.md metadata.version {version!r}")
    else:
        p("PASS", f"plugin.json version == SKILL.md version ({version})")

# 8. secret scan (reports file:line and pattern name only)
pats = {
    "github-token": r"ghp_[A-Za-z0-9]{20,}",
    "github-pat": r"github_pat[_]",
    "sk-key": r"sk-[A-Za-z0-9]{20,}",
    "aws-access-key": r"AKIA[0-9A-Z]{16}",
    "slack-token": r"xox[baprs]-",
    "private-key": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
}
cp = {k: re.compile(v) for k, v in pats.items()}
hits = 0
for dp, dn, fn in os.walk(root):
    dn[:] = [d for d in dn if d != ".git"]
    for f in fn:
        path = os.path.join(dp, f)
        if os.path.islink(path):
            continue
        try:
            data = open(path, "rb").read()
        except OSError:
            continue
        if b"\0" in data[:4096]:
            continue
        for i, ln in enumerate(data.decode("utf-8", "replace").split("\n"), 1):
            for k, rx in cp.items():
                if rx.search(ln):
                    p("FAIL", f"possible secret ({k}) at {rel(path)}:{i}")
                    hits += 1
if not hits:
    p("PASS", "no secrets found")

sys.exit(1 if fails else 0)
PY

# 9. optional external validators
if command -v claude >/dev/null 2>&1; then
  echo "--- claude plugin validate"
  if (cd "$ROOT" && claude plugin validate "$ROOT"); then echo "PASS claude plugin validate"; else echo "FAIL claude plugin validate"; rc=1; fi
fi
if command -v muse >/dev/null 2>&1; then
  echo "--- muse skills validate"
  if muse skills validate "$ROOT/skills/heimdall"; then echo "PASS muse skills validate"; else echo "FAIL muse skills validate"; rc=1; fi
fi

if [ "$rc" -ne 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: OK"
