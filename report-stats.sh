#!/bin/bash
# report-stats.sh - CPA-X System Statistics Report Generator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/cpa-common.sh"

REPORT_FILE="${SCRIPT_DIR}/report-stats.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

echo "Collecting system metrics..."

# System uptime
UPTIME=$(uptime -p 2>/dev/null || uptime)

# System load (read from /proc/loadavg for accuracy)
if [ -r /proc/loadavg ]; then
    LOAD_AVG=$(awk '{printf "%s, %s, %s", $1, $2, $3}' /proc/loadavg)
else
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
fi

# Memory usage
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h  | awk '/^Mem:/ {print $3}')
MEM_FREE=$(free -h  | awk '/^Mem:/ {print $4}')
MEM_PERCENT=$(free     | awk '/^Mem:/ {printf "%.1f%%", $3/$2 * 100}')

# Disk usage for root partition
DISK_TOTAL=$(df -h /   | awk 'NR==2 {print $2}')
DISK_USED=$(df -h /    | awk 'NR==2 {print $3}')
DISK_FREE=$(df -h /    | awk 'NR==2 {print $4}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')

# ── CPA-X API stats (best-effort) ──
API_STATUS="Not reachable"
ACTIVE_CONNECTIONS="N/A"
API_CALLS="N/A"
RESPONSE_TIME="N/A"

API_URL=$(cpa_api_url "/v1/stats")
API_KEY=$(cpa_first_api_key)

if command -v curl &>/dev/null; then
    echo "Attempting to fetch CPA-X statistics from ${API_URL}..."
    tmpfile=$(cpa_mktemp)
    trap 'rm -f "$tmpfile"' RETURN

    if curl -sS --connect-timeout 5 --max-time 10 \
        -H "Authorization: Bearer ${API_KEY}" \
        "${API_URL}" > "$tmpfile" 2>/dev/null; then
        API_STATUS="Reachable"

        if command -v jq &>/dev/null && jq empty "$tmpfile" 2>/dev/null; then
            ACTIVE_CONNECTIONS=$(jq -r '.active_connections // "N/A"' "$tmpfile")
            API_CALLS=$(jq -r '.api_calls // "N/A"' "$tmpfile")
            RESPONSE_TIME=$(jq -r '.response_time // "N/A"' "$tmpfile")
        else
            # Fallback: grep-based extraction for non-JSON or no-jq envs
            api_resp=$(cat "$tmpfile")
            ACTIVE_CONNECTIONS=$(echo "$api_resp" | grep -io '"active_connections"\s*:\s*[0-9.]*' | head -1 | grep -o '[0-9.]*' || echo "N/A")
            API_CALLS=$(echo "$api_resp"          | grep -io '"api_calls"\s*:\s*[0-9.]*'          | head -1 | grep -o '[0-9.]*' || echo "N/A")
            RESPONSE_TIME=$(echo "$api_resp"      | grep -io '"response_time"\s*:\s*[0-9.]*'     | head -1 | grep -o '[0-9.]*' || echo "N/A")
        fi
    else
        API_STATUS="Connection failed"
    fi
else
    API_STATUS="curl not installed"
fi

# Generate markdown report
cat <<EOF > "${REPORT_FILE}"
# CPA-X System Statistics Report

**Generated:** ${TIMESTAMP}

## System Overview

| Metric | Value |
|--------|-------|
| System Uptime | ${UPTIME} |
| System Load (1, 5, 15 min) | ${LOAD_AVG} |
| Memory Total | ${MEM_TOTAL} |
| Memory Used | ${MEM_USED} |
| Memory Free | ${MEM_FREE} |
| Memory Usage | ${MEM_PERCENT} |
| Disk Total (/) | ${DISK_TOTAL} |
| Disk Used (/) | ${DISK_USED} |
| Disk Free (/) | ${DISK_FREE} |
| Disk Usage (/) | ${DISK_PERCENT} |

## CPA-X Operational Metrics

| Metric | Value |
|--------|-------|
| API Endpoint | ${API_URL} |
| API Status | ${API_STATUS} |
| Active Connections | ${ACTIVE_CONNECTIONS} |
| API Calls (total) | ${API_CALLS} |
| Avg Response Time | ${RESPONSE_TIME} |

EOF

echo "Report saved to: ${REPORT_FILE}"
