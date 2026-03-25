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

# TEMPLATE: optional — uv, lang runtimes, services (reuse snippets from your stack)
# if command -v uv &>/dev/null; then ok "uv present"; else ...; fi

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
echo "--- runtime directories (TEMPLATE paths) ---"
OWNER="${SUDO_USER:-root}"
mkdir -p "$SCRIPT_DIR/logs"
chown "$OWNER":"$OWNER" "$SCRIPT_DIR/logs" 2>/dev/null || true
ok "logs/ ready"

echo ""
echo "--- binary checks (TEMPLATE: release artifact names) ---"
# TEMPLATE: replace with your real binary names after first release build
# check_binary "my-server" "$SCRIPT_DIR/target/release/my-server"

echo ""
echo -e "${BOLD}=== Installation complete ===${NC}"
echo ""
echo "Next: clone as a normal user, run ./setup.sh, then see README.md and AGENTS.md."
