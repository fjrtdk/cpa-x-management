#!/bin/bash
# Automated backup script for CPA-X management repository
# Commits any local changes and pushes to GitHub

set -euo pipefail

REPO_DIR="/home/raven/cpa-x-management"
LOG_FILE="/home/raven/.sisyphus/evidence/step-5-github/backup.log"

# Ensure we're in the repo directory
cd "$REPO_DIR"

# Optional: Pull latest changes to avoid conflicts
if git rev-parse --verify origin >/dev/null 2>&1; then
    git fetch origin
    # Try to reapply local commits on top of remote, but don't rebase uncommitted changes
    # We'll just commit first, then push; if push fails due to non-fast-forward, we abort.
fi

# Stage all changes
git add -A

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
    echo "$(date -Iseconds): No changes to backup." >> "$LOG_FILE"
    exit 0
fi

# Commit with timestamped message
COMMIT_MSG="Automated backup $(date -Iseconds)"
git commit -m "$COMMIT_MSG"

# Attempt to push
if git push origin master 2>/dev/null; then
    echo "$(date -Iseconds): Backup successful. $COMMIT_MSG" >> "$LOG_FILE"
else
    echo "$(date -Iseconds): ERROR: Push failed. Manual intervention required." >> "$LOG_FILE"
    exit 1
fi

exit 0
