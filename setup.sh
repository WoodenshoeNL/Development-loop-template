#!/bin/bash
# Session start script — run at the beginning of a session (any machine).
# Idempotent: safe to run repeatedly.
#
# TEMPLATE: Set EXPECTED_PREFIX to match PROJECT_ISSUE_PREFIX in loop.py
#
# Typical flow:
#   1. Check required tools (adjust lists below for your project)
#   2. git pull when the tree is clean
#   3. Enforce beads issue_prefix for this repo
#   4. Optional: scripts/install-toolchains.sh (only if present)
#   5. Import .beads/issues.jsonl into the local DB

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# TEMPLATE: Must match PROJECT_ISSUE_PREFIX in loop.py (kebab-case).
EXPECTED_PREFIX="my-project"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[ok]${NC}    $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail() { echo -e "${RED}[fail]${NC}  $*"; }

echo "=== Development loop — session start ==="
echo ""

check_tool() {
    local name="$1" cmd="${2:-$1}" install_hint="$3"
    if command -v "$cmd" &>/dev/null; then
        ok "$name: $(${cmd} --version 2>/dev/null | head -1)"
    else
        fail "$name not found. $install_hint"
        MISSING=1
    fi
}

MISSING=0
# TEMPLATE: Add/remove tools your agents need.
check_tool "git"     git     "https://git-scm.com/downloads"
check_tool "br"      br      "curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh | bash"
check_tool "claude"  claude  "npm install -g @anthropic-ai/claude-code"
check_tool "codex"   codex   "npm install -g @openai/codex"

if [[ "$MISSING" -eq 1 ]]; then
    echo ""
    warn "Some tools are missing. Install them and re-run this script."
    exit 1
fi

# TEMPLATE: Optional Python / uv — remove or adjust if unused.
if command -v uv &>/dev/null; then
    if ! uv python find --managed-python 3.12 &>/dev/null; then
        echo "Installing Python 3.12 via uv..."
        uv python install 3.12
    fi
    UV_PYTHON="$(uv python find --managed-python 3.12)"
    ok "Python (uv): $UV_PYTHON"
else
    warn "uv not found — skipping managed Python check (optional)"
    UV_PYTHON="python3"
fi

echo ""
echo "--- Git sync ---"

if ! git diff --quiet || ! git diff --cached --quiet; then
    warn "You have uncommitted local changes:"
    git status --short
    echo ""
    warn "Skipping git pull — commit or stash your changes first."
else
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    UPSTREAM="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo '')"
    if [[ -z "$UPSTREAM" ]]; then
        warn "No upstream configured for branch '$CURRENT_BRANCH' — skipping pull"
    else
        BEFORE="$(git rev-parse HEAD)"
        if git pull --ff-only --quiet 2>/dev/null; then
            AFTER="$(git rev-parse HEAD)"
            if [[ "$BEFORE" == "$AFTER" ]]; then
                ok "git: already up to date"
            else
                NEW_COMMITS="$(git log --oneline "$BEFORE..$AFTER" | wc -l | tr -d ' ')"
                ok "git: pulled $NEW_COMMITS new commit(s)"
                git log --oneline "$BEFORE..$AFTER" | sed 's/^/        /'
            fi
            if [[ -f "$SCRIPT_DIR/.stop" ]]; then
                rm "$SCRIPT_DIR/.stop"
                ok ".stop file removed — agent loops can run"
            fi
        else
            warn "git pull --ff-only failed (diverged?). Check manually:"
            echo "  git status; git log --oneline -5"
        fi
    fi
fi

echo ""
echo "--- br config ---"

ACTUAL_PREFIX="$(br config get issue_prefix 2>/dev/null || echo '')"

if [[ "$ACTUAL_PREFIX" == "$EXPECTED_PREFIX" ]]; then
    ok "br issue_prefix: $ACTUAL_PREFIX"
else
    warn "br issue_prefix is '$ACTUAL_PREFIX', expected '$EXPECTED_PREFIX'. Fixing..."
    br config set issue_prefix "$EXPECTED_PREFIX"
    ok "br issue_prefix set to $EXPECTED_PREFIX"
fi

echo ""
echo "--- optional bootstrap scripts ---"

TOOLCHAIN_SCRIPT="$SCRIPT_DIR/scripts/install-toolchains.sh"
if [[ -f "$TOOLCHAIN_SCRIPT" ]]; then
    echo "Running scripts/install-toolchains.sh ..."
    bash "$TOOLCHAIN_SCRIPT"
else
    ok "no scripts/install-toolchains.sh — skipping (add one if your project needs toolchains)"
fi

echo ""
echo "--- beads DB ---"

DB_PATH="$SCRIPT_DIR/.beads/beads.db"
if [[ -f "$DB_PATH" ]]; then
    ok "DB exists — running incremental import"
else
    warn "No DB found — building from JSONL"
fi

py_count_open() {
    "$UV_PYTHON" -c 'import json,sys; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else len(d.get("issues",[])))' 2>/dev/null || echo '?'
}

if br sync --import-only --rename-prefix --quiet 2>/dev/null; then
    OPEN_COUNT="$(br list --status=open --json 2>/dev/null | py_count_open)"
    ok "beads DB ready ($OPEN_COUNT open issues)"
else
    fail "br sync failed — check br version and JSONL integrity"
    exit 1
fi

if ! br sync --flush-only --quiet 2>/dev/null; then
    if br sync --flush-only --force --quiet 2>/dev/null; then
        if ! git diff --quiet -- .beads/issues.jsonl 2>/dev/null; then
            warn "Renamed issue IDs written to JSONL — committing and pushing"
            git add .beads/issues.jsonl
            git commit -m "chore: normalize issue IDs to ${EXPECTED_PREFIX} prefix" --quiet \
                && git push --quiet \
                && ok "Normalized JSONL pushed" \
                || warn "Could not push — commit manually: git push"
        fi
    fi
fi

IN_PROGRESS="$(br list --status=in_progress --json 2>/dev/null | "$UV_PYTHON" -c '
import json, sys
issues = json.load(sys.stdin)
if not isinstance(issues, list): issues = issues.get("issues", [])
for i in issues:
    print(f"  {i[\"id\"]}  {(i.get(\"title\") or \"\")[:60]}")
' 2>/dev/null || echo '')"
if [[ -n "$IN_PROGRESS" ]]; then
    warn "Tasks currently in_progress (may be stale from another VM):"
    echo "$IN_PROGRESS"
fi

echo ""
echo "--- Git identity ---"
GIT_USER="$(git config user.name 2>/dev/null || echo '')"
GIT_EMAIL="$(git config user.email 2>/dev/null || echo '')"

if [[ -z "$GIT_USER" || -z "$GIT_EMAIL" ]]; then
    warn "Git identity not set."
    echo "  git config --global user.name  'Your Name'"
    echo "  git config --global user.email 'you@example.com'"
else
    ok "Git identity: $GIT_USER <$GIT_EMAIL>"
fi

if command -v cargo &>/dev/null; then
    echo ""
    echo "--- cargo-sweep (optional) ---"
    if command -v cargo-sweep &>/dev/null; then
        ok "cargo-sweep: $(cargo-sweep --version 2>/dev/null | head -1)"
    else
        warn "cargo-sweep not found — loop.py can fall back to manual incremental cleanup"
        if cargo install cargo-sweep --quiet 2>/dev/null; then
            ok "cargo-sweep installed"
        else
            warn "cargo-sweep install failed — ignored"
        fi
    fi
fi

mkdir -p "$SCRIPT_DIR/logs"
ok "logs/ directory ready"

echo ""
HOSTNAME_ID="${HOSTNAME:-$(hostname)}"
echo "=== Ready on ${HOSTNAME_ID} ==="
echo ""
echo "Agent loops (examples — TEMPLATE: adjust --zone to your ZONES in loop.py):"
echo "  ./loop.py --agent claude --loop dev                    # ${HOSTNAME_ID}-claude"
echo "  ./loop.py --agent claude --loop dev --zone main       # scoped to zone main"
echo "  ./loop.py --agent codex  --loop dev --zone main"
echo "  ./loop.py --agent cursor --loop dev --zone main"
echo ""
echo "Agent loops (review):"
echo "  ./loop.py --agent claude --loop qa"
echo "  ./loop.py --agent claude --loop arch"
echo "  ./loop.py --agent claude --loop quality"
