#!/bin/bash

# Script to manage the CPA-X service
# Provides easy commands for status, restart, and log viewing

# Check if the script is called with an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 {status|restart|logs}"
    exit 1
fi

# Get the command and execute the corresponding action
cmd=$1

case "$cmd" in
    status)
        echo "CPA-X Service Status:"
        systemctl is-active cli-proxy-api
        ;;
    restart)
        echo "Restarting CPA-X service..."
        sudo systemctl restart cli-proxy-api
        echo "Service restarted. Checking status:"
        systemctl is-active cli-proxy-api
        ;;
    logs)
        echo "CPA-X Service Logs:"
        journalctl -f -u cli-proxy-api
        ;;
    *)
        echo "Usage: $0 {status|restart|logs}"
        exit 1
        ;;
esac

exit 0
