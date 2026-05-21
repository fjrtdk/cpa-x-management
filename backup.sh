#!/bin/bash
# Automated backup script for CPA-X management repository
# Commits any local changes and pushes to GitHub

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOME}/.sisyphus/evidence/step-5-github/backup.log"
TIMESTAMP=$(date -Iseconds)

# Ensure log directory exists

cd "$SCRIPT_DIR"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Pull latest to reduce conflict risk
if git rev-parse --verify origin/master >/dev/null 2>&1; then
    git fetch origin 2>/dev/null || true
fi

# Stage all changes
git add -A

if git diff-index --quiet HEAD --; then
    echo "${TIMESTAMP}: No changes to backup." >> "$LOG_FILE"
    exit 0
fi

COMMIT_MSG="Automated backup ${TIMESTAMP}"
git commit -m "${COMMIT_MSG}"

# Try current branch first, fallback to master
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if push_out=$(git push origin "${BRANCH}" 2>&1); then
    echo "${TIMESTAMP}: Backup successful (${BRANCH}). ${COMMIT_MSG}" >> "$LOG_FILE"
else
    echo "${TIMESTAMP}: Push to ${BRANCH} failed: ${push_out}" >> "$LOG_FILE"
    if [ "${BRANCH}" != "master" ] && push_out2=$(git push origin master 2>&1); then
        echo "${TIMESTAMP}: Backup successful (master fallback). ${COMMIT_MSG}" >> "$LOG_FILE"
    else
        echo "${TIMESTAMP}: ERROR: Push to master also failed: ${push_out2:-}" >> "$LOG_FILE"
        exit 1
    fi
fi

exit 0
