# 🛠️ User Guide: Terraform Cloud Backend Migration

**Target:** Legacy `backend "remote"` → Modern `cloud` block

## 1. Overview

This automation script facilitates the bulk migration of Terraform configurations. By moving to the `cloud` block, you align with modern Terraform standards, enabling better CLI integration and simplified workspace management.

## 2. Prerequisites

* **Terraform CLI:** Version 1.1.0 or higher.
* **Python 3.8+:** Install deps with `pip install -r requirements.txt` (requires `requests` and `python-hcl2`).
* **TFC/TFE Token:** API token with **Manage Workspaces** permissions.
* **Network Access:** Connectivity to your TFC/TFE hostname.

---

## 3. Configuration Hierarchy

The script resolves its settings using the following priority order:

| Setting | Priority 1 (CLI Flag) | Priority 2 (Env Var) | Priority 3 (Script Constant) |
| --- | --- | --- | --- |
| **TFC Token** | `--token <string>` | `TFC_TOKEN` | *None (Required)* |
| **Hostname** | `--hostname <string>` | `TFC_HOSTNAME` | `DEFAULT_HOSTNAME` |

---

## 4. Migration Logic & Idempotency

The script is designed to be safe for production use through several layers of verification:

* **Pre-flight Validation:** Checks that Terraform CLI is installed before attempting migration.
* **HCL2 Parsing:** Uses the `python-hcl2` library for robust configuration parsing that properly handles all comment types (inline and line comments).
* **Idempotency:** It searches for an existing `cloud` block. If found, it skips the directory to avoid redundant changes.
* **Hostname Smart-Mapping:** If your hostname is the default (`app.terraform.io`), the script omits the `hostname` line for cleaner code. If using TFE, it migrates the hostname to the top level of the `cloud` block.
* **Tag Normalization:** Converts legacy `prefix = "networking-"` into modern `tags = ["networking"]` and uses the TFC API to ensure the workspace is tagged before initialization.
* **State Migration:** Automatically runs `terraform init` with interactive prompts to migrate state (Note: `-migrate-state` flag is not compatible with TFC migrations).
* **Error Recovery:** If any step fails (formatting, init, or API calls), the script automatically restores the original configuration from backup and logs the error.

---

## 5. Execution Workflow

### Step 1: Perform a Dry Run

Always run without the execution flag first to see a preview of HCL changes and API actions. By default the script targets the current directory (`.`). Use `-d`/`--directory` to migrate specific dirs (repeatable).

```bash
python3 migrate_tfc.py
python3 migrate_tfc.py -d /path/to/stack1 -d /path/to/stack2
```

### Step 2: Execute Migration

Add `--no-dry-run`. You will be prompted to type `YES` before any file modifications. The script automatically creates temporary backups during migration and restores them on failure. Use `--backup` to retain `.bak` files after successful migration.

```bash
python3 migrate_tfc.py --token "your_token" --no-dry-run
python3 migrate_tfc.py --token "your_token" --no-dry-run --backup -d ./mystack
```

---

## 6. Troubleshooting

| Issue | Likely Cause | Solution |
| --- | --- | --- |
| **"Workspace not found"** | API mismatch with folder name. | Ensure the local directory name matches the TFC workspace name for API tagging. |
| **"403 Forbidden"** | Insufficient Token permissions. | Use an Org or Team token with "Manage Workspaces" rights. |
| **"Init failed"** | Local cache corruption or migration error. | The script automatically restores the original config. Delete the `.terraform/` folder and re-run. Check the `.bak` file for the original configuration. |
| **"Terraform binary not found"** | Terraform not installed or not in PATH. | Install Terraform CLI and ensure it's accessible from your shell. |
| **"HCL2 parsing failed"** | Malformed HCL syntax. | The script falls back to regex parsing. Check your `.tf` file syntax with `terraform validate`. |
