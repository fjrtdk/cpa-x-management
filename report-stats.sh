#!/bin/bash

# report-stats.sh - CPA-X System Statistics Report Generator

# Configuration
API_ENDPOINT=${CPA_X_API_ENDPOINT:-"http://localhost:8080/v1/stats"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="${SCRIPT_DIR}/report-stats.md"

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

# Collect system metrics
echo "Collecting system metrics..."

# System uptime
UPTIME=$(uptime -p 2>/dev/null || uptime)

# System load (1, 5, 15 minute averages)
LOAD_AVG=$(awk '/load average/ {print $10,$11,$12}' /proc/uptime 2>/dev/null || uptime | awk -F'load average:' '{print $2}')

# Memory usage (in human readable)
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_FREE=$(free -h | awk '/^Mem:/ {print $4}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.1f%%", $3/$2 * 100}')

# Disk usage for root partition
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')

# Initialize API stats
ACTIVE_CONNECTIONS="N/A"
API_CALLS="N/A"
RESPONSE_TIME="N/A"
API_STATUS="Not reachable"

# Try to fetch API statistics
if command -v curl &> /dev/null; then
    echo "Attempting to fetch CPA-X statistics from ${API_ENDPOINT}..."
    if curl -s --connect-timeout 5 --max-time 10 "${API_ENDPOINT}" > "${SCRIPT_DIR}/api_response.json" 2>/dev/null; then
        API_STATUS="Reachable"
        # Try to parse JSON-like responses (simple extraction)
        API_RESPONSE=$(cat "${SCRIPT_DIR}/api_response.json")
        
        # Extract common field patterns (case-insensitive)
        ACTIVE_CONNECTIONS=$(echo "$API_RESPONSE" | grep -io '"active_connections"\s*:\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        API_CALLS=$(echo "$API_RESPONSE" | grep -io '"api_calls"\s*:\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        RESPONSE_TIME=$(echo "$API_RESPONSE" | grep -io '"response_time"\s*:\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        
        # Fallback to generic extraction if specific fields not found
        if [ -z "$ACTIVE_CONNECTIONS" ] || [ "$ACTIVE_CONNECTIONS" = "N/A" ]; then
            ACTIVE_CONNECTIONS=$(echo "$API_RESPONSE" | grep -io 'active_connections\s*[:=]\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        fi
        if [ -z "$API_CALLS" ] || [ "$API_CALLS" = "N/A" ]; then
            API_CALLS=$(echo "$API_RESPONSE" | grep -io 'api_calls\s*[:=]\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        fi
        if [ -z "$RESPONSE_TIME" ] || [ "$RESPONSE_TIME" = "N/A" ]; then
            RESPONSE_TIME=$(echo "$API_RESPONSE" | grep -io 'response_time\s*[:=]\s*[0-9.]*' | head -1 | grep -o '[0-9.]*')
        fi
        
        # Set defaults if still empty
        [ -z "$ACTIVE_CONNECTIONS" ] && ACTIVE_CONNECTIONS="N/A"
        [ -z "$API_CALLS" ] && API_CALLS="N/A"
        [ -z "$RESPONSE_TIME" ] && RESPONSE_TIME="N/A"
        
        rm -f "${SCRIPT_DIR}/api_response.json"
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
| API Endpoint | ${API_ENDPOINT} |
| API Status | ${API_STATUS} |
| Active Connections | ${ACTIVE_CONNECTIONS} |
| API Calls (total) | ${API_CALLS} |
| Avg Response Time | ${RESPONSE_TIME} |

EOF

echo "Report saved to: ${REPORT_FILE}"
