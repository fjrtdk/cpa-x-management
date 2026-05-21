#!/bin/bash
# CPA-X shared library — sourced by management and report scripts.
# Provides: config values, API key extraction, color helpers, logging.
# Usage: source "${SCRIPT_DIR}/lib/cpa-common.sh"

# set -euo pipefail  ← intentionally omitted; callers own their shell flags

# ── Paths (override via env before sourcing) ────────────────────────────
: "${CPA_CONFIG_DIR:="${HOME}/.cli-proxy-api"}"
: "${CPA_CONFIG_FILE:="${CPA_CONFIG_DIR}/config.yaml"}"

# ── Colors (auto-detects TTY) ──────────────────────────────────────────
if [ -t 1 ]; then
    BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    RED='\033[0;31m';   CYAN='\033[0;36m';   NC='\033[0m'
else
    BOLD=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; NC=''
fi

# ── Config helpers ─────────────────────────────────────────────────────

# Get a scalar value from the CPA-X config by top-level key.
# Usage: cpa_config_value "port"       # → 8317
cpa_config_value() {
    local key="$1"
    if [ ! -f "${CPA_CONFIG_FILE}" ]; then
        echo ""
        return 1
    fi
    grep -E "^${key}:" "${CPA_CONFIG_FILE}" 2>/dev/null \
        | awk '{print $2}' | tr -d '"'
}

# Get the CPA-X API port from config, falling back to 8317.
cpa_port() {
    local port
    port=$(cpa_config_value "port")
    echo "${port:-8317}"
}

# Extract the first client API key from config.
# Falls back to "dashboard-key-2026" if no key found.
cpa_first_api_key() {
    if [ ! -f "${CPA_CONFIG_FILE}" ]; then
        echo "dashboard-key-2026"
        return
    fi
    local key
    key=$(grep -A 100 '^api-keys:' "${CPA_CONFIG_FILE}" 2>/dev/null \
        | grep -E '^\s*-\s*sk-' \
        | head -1 \
        | sed -E 's/^[[:space:]]*-[[:space:]]*//')
    echo "${key:-dashboard-key-2026}"
}

# Build the local API base URL from config port.
# Usage: cpa_api_url "/v1/models"  # → http://127.0.0.1:8317/v1/models
cpa_api_url() {
    local path="${1:-}"
    echo "http://127.0.0.1:$(cpa_port)${path}"
}

# ── Logging ────────────────────────────────────────────────────────────
log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Temp file helper ───────────────────────────────────────────────────
# Usage: tmp=$(cpa_mktemp); trap 'rm -f "$tmp"' EXIT
cpa_mktemp() {
    mktemp -t "cpa-x.XXXXXX"
}