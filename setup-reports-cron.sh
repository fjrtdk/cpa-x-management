#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/cpa-x-reports.log"
CRON_JOB="0 6 * * * cd ${SCRIPT_DIR} && { echo \"=== Reports started at \$(date) ===\"; ./report-models.sh; ./report-stats.sh; echo \"=== Reports finished at \$(date) ===\"; } >> ${LOG_FILE} 2>&1"

echo "=== CPA-X Reports Cron Setup ==="
echo ""

if ! command -v crontab &> /dev/null; then
    echo "ERROR: crontab command not found. Cron may not be installed."
    echo "Please install cron (e.g., apt-get install cron, yum install cronie, etc.)"
    exit 1
fi

echo "✓ Cron is available (crontab command found)"
echo ""

if [ ! -w "/var/log" ]; then
    echo "WARNING: /var/log directory is not writable."
    echo "You may need sudo to create the log file, or specify a different location."
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "Creating log file: $LOG_FILE"
    if sudo touch "$LOG_FILE" 2>/dev/null; then
        sudo chown raven:raven "$LOG_FILE" 2>/dev/null || true
        sudo chmod 644 "$LOG_FILE" 2>/dev/null || true
    else
        echo "WARNING: Could not create log file. Will attempt when cron runs."
        echo "You may need to run: sudo touch $LOG_FILE && sudo chown raven:raven $LOG_FILE && sudo chmod 644 $LOG_FILE"
    fi
fi

EXISTING_CRON=$(crontab -l 2>/dev/null | grep -F "report-models.sh" || true)

if [ -n "$EXISTING_CRON" ]; then
    echo "Existing cron job found for CPA-X reports:"
    echo "$EXISTING_CRON"
    echo ""
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. No changes made."
        exit 0
    fi
    
    crontab -l 2>/dev/null | grep -v "report-models.sh" | crontab -
    echo "Removed existing cron entries."
fi

echo "Installing cron job:"
echo "  $CRON_JOB"
echo ""

(
    crontab -l 2>/dev/null
    echo "$CRON_JOB"
) | crontab -

echo "✓ Cron job installed successfully."
echo ""

echo "Verifying installation..."
VERIFY=$(crontab -l 2>/dev/null | grep -F "report-models.sh" || true)

if [ -n "$VERIFY" ]; then
    echo "✓ Cron job confirmed in crontab:"
    echo "  $VERIFY"
else
    echo "✗ WARNING: Could not verify cron job in crontab."
    echo "  Please run 'crontab -l' to check manually."
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "What was installed:"
echo "  • Daily cron job at 06:00 (6:00 AM)"
echo "  • Runs both report-models.sh and report-stats.sh"
echo "  • All output (stdout & stderr) logged to: $LOG_FILE"
echo ""
echo "Manual verification steps:"
echo "  1. List your crontab: crontab -l"
echo "  2. Check log file (may be empty until first run): sudo tail -f $LOG_FILE"
echo "  3. Test manually: cd $SCRIPT_DIR && ./report-models.sh && ./report-stats.sh"
echo ""
echo "To customize the schedule, edit your crontab: crontab -e"
echo "The cron job line starts with: '0 6 * * *'"
echo ""
echo "To view recent report logs:"
echo "  sudo tail -n 100 $LOG_FILE"
echo "  sudo less +F $LOG_FILE  (to follow live)"
echo ""
