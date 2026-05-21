#!/bin/bash
# CPA-X Service Manager
# Provides easy commands for status, restart, logs, config check, and more
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/cpa-common.sh"

SERVICE_NAME="cli-proxy-api"

usage() {
    cat <<EOF
${BOLD}CPA-X Service Manager${NC}
Usage: $0 {status|restart|logs|start|stop|config|models|help}

${BOLD}Commands:${NC}
  status          Show service status and uptime
  restart         Restart the CPA-X service
  start           Start the CPA-X service
  stop            Stop the CPA-X service
  logs            Follow live service logs
  config          Validate and show current configuration
  models          Show available models via API
  help            Show this help message
EOF
    exit 0
}

check_service_exists() {
    if ! systemctl list-units --type=service --all 2>/dev/null | grep -q "${SERVICE_NAME}"; then
        log_error "Service '${SERVICE_NAME}' not found."
        echo "Available services matching 'cpa' or 'proxy':"
        systemctl list-units --type=service --all 2>/dev/null | grep -iE "cpa|proxy" || true
        exit 1
    fi
}

# Ensure systemd is available
if ! command -v systemctl &>/dev/null; then
    log_error "systemctl not found. This script requires systemd."
    exit 1
fi

cmd="${1:-help}"

case "$cmd" in
    status)
        check_service_exists
        echo -e "${BOLD}CPA-X Service Status:${NC}"
        if systemctl is-active --quiet "${SERVICE_NAME}"; then
            echo -e "  ${GREEN}● active${NC}"
            echo ""
            systemctl show -p ActiveEnterTimestamp "${SERVICE_NAME}" 2>/dev/null \
                | sed 's/ActiveEnterTimestamp=/  Started: /'
            echo ""
            echo -e "${BOLD}Recent logs (last 10 lines):${NC}"
            journalctl -u "${SERVICE_NAME}" -n 10 --no-pager --output=short 2>/dev/null \
                || echo "  (no logs available)"
        else
            echo -e "  ${RED}✗ inactive${NC}"
            systemctl status "${SERVICE_NAME}" 2>&1 | head -5
        fi
        ;;
    start)
        check_service_exists
        echo -e "${BOLD}Starting CPA-X service...${NC}"
        sudo systemctl start "${SERVICE_NAME}"
        log_info "Service started."
        systemctl is-active "${SERVICE_NAME}"
        ;;
    stop)
        check_service_exists
        echo -e "${BOLD}Stopping CPA-X service...${NC}"
        sudo systemctl stop "${SERVICE_NAME}"
        log_warn "Service stopped."
        ;;
    restart)
        check_service_exists
        echo -e "${BOLD}Restarting CPA-X service...${NC}"
        sudo systemctl restart "${SERVICE_NAME}"
        if systemctl is-active --quiet "${SERVICE_NAME}"; then
            log_info "Service restarted and active."
        else
            log_error "Service failed to start after restart."
            systemctl status "${SERVICE_NAME}" 2>&1 | head -10
            exit 1
        fi
        ;;
    logs)
        check_service_exists
        echo -e "${CYAN}CPA-X Service Logs (Ctrl+C to exit):${NC}"
        exec journalctl -f -u "${SERVICE_NAME}" -o short
        ;;
    config)
        echo -e "${BOLD}CPA-X Configuration:${NC}"
        if [ -f "${CPA_CONFIG_FILE}" ]; then
            echo -e "  ${GREEN}✓ Main config:${NC} ${CPA_CONFIG_FILE}"
            if command -v python3 &>/dev/null; then
                if python3 -c "import yaml; yaml.safe_load(open('${CPA_CONFIG_FILE}'))" 2>/dev/null; then
                    echo -e "  ${GREEN}✓ YAML syntax: valid${NC}"
                else
                    echo -e "  ${RED}✗ YAML syntax: INVALID${NC}"
                fi
            fi
            echo "  Port: $(cpa_port)"
            echo "  Providers:"
            grep -A1 'name:' "${CPA_CONFIG_FILE}" | grep 'name:' \
                | sed 's/.*name: */    - /'
        else
            log_error "Config not found at ${CPA_CONFIG_FILE}"
        fi

        CONFIG_NIM="${CPA_CONFIG_DIR}/config-nim.yaml"
        if [ -f "$CONFIG_NIM" ]; then
            echo -e "  ${GREEN}✓ NIM config:${NC} ${CONFIG_NIM}"
        else
            echo -e "  ${YELLOW}⚠ NIM config not found at ${CONFIG_NIM}${NC}"
        fi
        ;;
    models)
        echo -e "${BOLD}Fetching models from CPA-X API...${NC}"
        API_KEY=$(cpa_first_api_key)
        API_URL=$(cpa_api_url "/v1/models")
        if [ -n "$API_KEY" ] && [ "$API_KEY" != "dashboard-key-2026" ]; then
            response=$(curl -s -H "Authorization: Bearer ${API_KEY}" "${API_URL}") || {
                log_error "Cannot reach CPA-X at ${API_URL}"
                exit 1
            }
        else
            echo -e "${YELLOW}No valid API key found, trying without auth...${NC}"
            response=$(curl -s "${API_URL}") || {
                log_error "Cannot reach CPA-X at ${API_URL}"
                exit 1
            }
        fi
        if command -v jq &>/dev/null; then
            count=$(echo "$response" | jq '.data | length' 2>/dev/null || echo "0")
            echo -e "  ${GREEN}Total models: ${count}${NC}"
            echo ""
            echo "$response" | jq -r '.data[] | "  \(.id)"' 2>/dev/null \
                || echo "$response" | head -50
        else
            echo "$response" | head -50
        fi
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        log_error "Unknown command: ${cmd}"
        usage
        ;;
esac
exit 0
