# CPA-X Reports

Automated markdown reports generated from the CPA-X service.

## Scripts

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

Both scripts are scheduled via cron:

- `report-models.sh` runs daily at 2:00 AM
- `report-stats.sh` runs daily at 3:00 AM

Output files are overwritten on each run. You can change the schedule by editing your crontab (`crontab -e`).

## Requirements

- `curl` for API access
- `jq` for JSON processing
- `systemctl` for service status
- `date`, `awk` for formatting

The scripts read the API key from `/home/raven/.cli-proxy-api/config.yaml`. Ensure the config file exists and contains a valid `api-keys` entry.

## Troubleshooting

**"Permission denied" on cron**
- Cron runs with a minimal environment. Ensure full paths or use absolute paths to executables. The scripts assume standard utilities are in PATH; adjust if needed.

**API returns "Invalid API key"**
- The scripts extract the first API key from the config. Ensure the `api-keys` section is present and contains valid keys.

**Empty model list**
- The service may not have loaded models yet. Check service logs with `./manage-cpa-x.sh logs`.

**Missing jq**
- Install jq: `apt-get install jq` or equivalent.

## Customization

To change output location, edit the `OUTPUT_DIR` variable at the top of each script.
