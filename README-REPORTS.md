# CPA-X Reports

Automated markdown reports generated from the CPA-X service via cron jobs.

## Reports

### `report-models.sh`

Generates a list of all available models.

**Output:** `report-models.md` with a table of model IDs, providers, and creation dates.

**Usage:**
```bash
./report-models.sh
```

**Sample Output:**
```markdown
# CPA-X Models Report
Generated: 2026-05-20T11:00:00+00:00

**Total Models:** 273

## Model List

| ID | Provider | Created |
|----|----------|---------|
| ibm/granite-34b-code-instruct | nvidia-nim | 2026-05-20 11:00:14 |
| ... |
```

### `report-stats.sh`

Generates service statistics including status, resource usage, and model distribution.

**Output:** `report-stats.md`

**Usage:**
```bash
./report-stats.sh
```

**Sample Output:**
```markdown
# CPA-X Statistics Report
Generated: 2026-05-20T11:00:00+00:00

## Service Status
- **Status:** Active
- **Uptime:** 2d 05h 12m 34s
- **Main PID:** 12345
- **Memory:** 13.8 MB
- **CPU Time:** 5.23s

## Models
- **Total Models:** 273
- **Models by Provider:** (table)
```

## Automation (Cron)

Both scripts run automatically via cron:

- **Schedule:** Daily at 06:00 (6:00 AM)
- **Location:** Cron job installed in your user crontab
- **Logs:** All output (stdout + stderr) appended to `/var/log/cpa-x-reports.log`

The cron job executes:
```bash
0 6 * * * cd /home/raven/cpa-x-management && ./report-models.sh && ./report-stats.sh >> /var/log/cpa-x-reports.log 2>&1
```

### Setup

To install or reinstall the cron job, run:

```bash
./setup-reports-cron.sh
```

The setup script will:
- Verify `crontab` is available
- Create the log file (`/var/log/cpa-x-reports.log`) if needed
- Install the daily 06:00 cron job
- Show verification instructions

### Customization

**Change the schedule:**

```bash
crontab -e
```

Edit the line that starts with `0 6 * * *` to your preferred schedule using standard cron syntax.

**Change log file location:**

Edit `setup-reports-cron.sh` and modify the `LOG_FILE` variable, then re-run the setup script.

**Change output directory:**

Each script has an `OUTPUT_DIR` or `SCRIPT_DIR` variable. Edit the scripts directly if you want reports in a different location.

## Requirements

- `curl` for API access
- `jq` for JSON processing
- `date`, `awk`, `grep`, `sed` for formatting

The scripts read API keys from `/home/raven/.cli-proxy-api/config.yaml`. Ensure this config file exists and contains valid `api-keys`.

## Troubleshooting

**"Permission denied" on cron**

Cron runs with a minimal environment. The scripts use absolute paths for the working directory. Ensure your crontab entry uses `cd /home/raven/cpa-x-management` before running the scripts.

**API returns "Invalid API key"**

The `report-models.sh` script extracts the first OpenAI-compatible client key from the config. Ensure the `api-keys` section is present and contains valid keys.

**Empty model list**

The service may not have loaded models yet. Check service status with `./manage-cpa-x.sh status` and logs with `./manage-cpa-x.sh logs`.

**Missing jq**

Install jq: `apt-get install jq` or `yum install jq` depending on your system.

**Log file not created**

Cron may not have permission to write to `/var/log`. Create it manually:

```bash
sudo touch /var/log/cpa-x-reports.log
sudo chmod 644 /var/log/cpa-x-reports.log
```

## Viewing Logs

Check the cron execution log:

```bash
sudo tail -f /var/log/cpa-x-reports.log
```

View recent entries:

```bash
sudo tail -n 100 /var/log/cpa-x-reports.log
```

Follow log in real-time:

```bash
sudo less +F /var/log/cpa-x-reports.log
```

## Manual Execution

Test reports immediately without waiting for cron:

```bash
cd /home/raven/cpa-x-management
./report-models.sh
./report-stats.sh
```

The generated markdown files (`report-models.md`, `report-stats.md`) will be overwritten each run.
