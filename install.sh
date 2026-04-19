#!/bin/bash
# install.sh — optional system dependencies (Debian/Ubuntu).
#
# TEMPLATE: Rename flags, package lists, and binary names for your project.
# This template keeps a minimal structure: common packages + placeholders.
#
# Usage:
#   sudo ./install.sh              # install all defined components
#   sudo ./install.sh --primary    # component "primary" only
#   sudo ./install.sh --secondary # component "secondary" only
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[ok]${NC}    $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail() { echo -e "${RED}[fail]${NC}  $*"; }
info() { echo -e "${BOLD}[--]${NC}    $*"; }

INSTALL_PRIMARY=0
INSTALL_SECONDARY=0

for arg in "$@"; do
    case "$arg" in
        --primary)   INSTALL_PRIMARY=1 ;;
        --secondary) INSTALL_SECONDARY=1 ;;
        --help|-h)
            echo "Usage: sudo $0 [--primary] [--secondary]"
            echo "  (no flags = install all defined components)"
            exit 0
            ;;
        *)
            fail "Unknown argument: $arg"
            echo "Usage: sudo $0 [--primary] [--secondary]"
            exit 1
            ;;
    esac
done

if [[ "$INSTALL_PRIMARY" -eq 0 && "$INSTALL_SECONDARY" -eq 0 ]]; then
    INSTALL_PRIMARY=1
    INSTALL_SECONDARY=1
fi

if [[ "$EUID" -ne 0 ]]; then
    fail "Run as root or with sudo."
    exit 1
fi

if ! command -v apt-get &>/dev/null; then
    fail "apt-get not found. Extend this script for your distro or install packages manually."
    exit 1
fi

echo ""
echo -e "${BOLD}=== TEMPLATE: Project name — system dependencies ===${NC}"
WHAT_INSTALLING=()
[[ "$INSTALL_PRIMARY"   -eq 1 ]] && WHAT_INSTALLING+=("primary")
[[ "$INSTALL_SECONDARY" -eq 1 ]] && WHAT_INSTALLING+=("secondary")
info "Installing: $(IFS='+'; echo "${WHAT_INSTALLING[*]}")"
echo ""

echo "--- package lists (TEMPLATE: edit) ---"

COMMON_PKGS=(
    ca-certificates
    curl
    git
)

# TEMPLATE: e.g. build deps, interpreters, libs for your server or daemon
PRIMARY_PKGS=(
)

# TEMPLATE: e.g. GUI libs, desktop dependencies
SECONDARY_PKGS=(
)

PKGS=("${COMMON_PKGS[@]}")
[[ "$INSTALL_PRIMARY"   -eq 1 ]] && PKGS+=("${PRIMARY_PKGS[@]}")
[[ "$INSTALL_SECONDARY" -eq 1 ]] && PKGS+=("${SECONDARY_PKGS[@]}")

info "Updating package lists..."
apt-get update -qq

if [[ "${#PKGS[@]}" -gt 0 ]]; then
    info "Installing: ${PKGS[*]}"
    apt-get install -y --no-install-recommends "${PKGS[@]}"
    ok "packages installed"
else
    warn "No EXTRA_PKGS defined beyond common set — only common packages installed"
    apt-get install -y --no-install-recommends "${COMMON_PKGS[@]}"
    ok "common packages installed"
fi

# ── uv + Python (optional) ────────────────────────────────────────────────────
# TEMPLATE: Remove this section if your project does not use Python.

echo ""
echo "--- uv + Python (optional) ---"

if command -v uv &>/dev/null; then
    ok "uv already present: $(uv --version)"
else
    if curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh; then
        ok "uv installed: $(uv --version)"
    else
        warn "uv install failed — skipping Python setup"
    fi
fi

if command -v uv &>/dev/null; then
    uv python install 3.12

    PYTHON_BIN="$(uv python find 3.12 2>/dev/null || uv python find)"
    PYTHON_LIB_DIR="$(realpath "$(dirname "$PYTHON_BIN")/../lib")"

    # Register with runtime dynamic linker
    echo "$PYTHON_LIB_DIR" > /etc/ld.so.conf.d/uv-python.conf
    ldconfig
    ok "libpython registered with ldconfig: $PYTHON_LIB_DIR"

    # Create unversioned linker symlink if missing (needed by build-time linkers)
    if [[ ! -e /usr/lib/x86_64-linux-gnu/libpython3.12.so ]]; then
        ln -sf libpython3.12.so.1.0 /usr/lib/x86_64-linux-gnu/libpython3.12.so
        ok "linker symlink: /usr/lib/x86_64-linux-gnu/libpython3.12.so -> libpython3.12.so.1.0"
    else
        ok "linker symlink already present: /usr/lib/x86_64-linux-gnu/libpython3.12.so"
    fi
    ldconfig
fi

echo ""
echo "--- optional script hooks (TEMPLATE) ---"
EXTRA_INSTALL="$SCRIPT_DIR/scripts/install-extra.sh"
if [[ -f "$EXTRA_INSTALL" ]]; then
    info "Running scripts/install-extra.sh"
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" bash "$EXTRA_INSTALL"
    else
        bash "$EXTRA_INSTALL"
    fi
else
    ok "no scripts/install-extra.sh — add project-specific steps there if needed"
fi

TOOLCHAIN_SCRIPT="$SCRIPT_DIR/scripts/install-toolchains.sh"
if [[ -f "$TOOLCHAIN_SCRIPT" ]]; then
    info "Running scripts/install-toolchains.sh"
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" bash "$TOOLCHAIN_SCRIPT"
    else
        bash "$TOOLCHAIN_SCRIPT"
    fi
fi

echo ""
echo "--- runtime directories ---"
OWNER="${SUDO_USER:-root}"

create_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chown "$OWNER":"$OWNER" "$dir"
        ok "created $dir"
    else
        ok "$dir already exists"
    fi
}

create_dir "$SCRIPT_DIR/logs"

# TEMPLATE: Create additional runtime directories your project needs.
# [[ "$INSTALL_PRIMARY"   -eq 1 ]] && create_dir "$SCRIPT_DIR/data"
# [[ "$INSTALL_SECONDARY" -eq 1 ]] && create_dir "$SCRIPT_DIR/cache"

echo ""
echo "--- binary checks (TEMPLATE: release artifact names) ---"

check_binary() {
    local name="$1" path="$2"
    if [[ -x "$path" ]]; then
        ok "$name binary found at $path"
    else
        warn "$name binary not found at $path"
        # TEMPLATE: replace with your actual build command
        echo "       Build with: <your build command> -p $name"
    fi
}

# TEMPLATE: uncomment and replace with your actual binary names after first build
# [[ "$INSTALL_PRIMARY"   -eq 1 ]] && check_binary "my-server" "$SCRIPT_DIR/target/release/my-server"
# [[ "$INSTALL_SECONDARY" -eq 1 ]] && check_binary "my-client" "$SCRIPT_DIR/target/release/my-client"

echo ""
echo -e "${BOLD}=== Installation complete ===${NC}"
echo ""

# TEMPLATE: Replace with actual run commands for your project
if [[ "$INSTALL_PRIMARY" -eq 1 ]]; then
    echo "Primary component:"
    echo "  # TEMPLATE: ./target/release/my-server --config config.toml"
    echo ""
fi

if [[ "$INSTALL_SECONDARY" -eq 1 ]]; then
    echo "Secondary component:"
    echo "  # TEMPLATE: ./target/release/my-client"
    echo ""
fi

echo "Next: clone as a normal user, run ./setup.sh, then see README.md and AGENTS.md."
