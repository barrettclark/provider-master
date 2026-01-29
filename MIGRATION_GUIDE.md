# 🛠️ User Guide: Terraform Cloud Backend Migration

**Target:** Legacy `backend "remote"` → Modern `cloud` block

## 1. Overview

This automation script facilitates the bulk migration of Terraform configurations. By moving to the `cloud` block, you align with modern Terraform standards, enabling better CLI integration and simplified workspace management.

## 2. Prerequisites

* **Terraform CLI:** Version 1.1.0 or higher.
* **Python 3.x:** Required library: `requests` (`pip install requests`).
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

* **Idempotency:** It searches for an existing `cloud` block. If found, it skips the directory to avoid redundant changes.
* **Hostname Smart-Mapping:** If your hostname is the default (`app.terraform.io`), the script omits the `hostname` line for cleaner code. If using TFE, it migrates the hostname to the top level of the `cloud` block.
* **Tag Normalization:** Converts legacy `prefix = "networking-"` into modern `tags = ["networking"]` and uses the TFC API to ensure the workspace is tagged before initialization.
* **State Migration:** Automatically runs `terraform init -migrate-state` to finalize the backend transition.

---

## 5. Execution Workflow

### Step 1: Initialize the Script

Edit the `TARGET_DIRECTORIES` and `DEFAULT_HOSTNAME` constants at the top of `migrate_tfc.py`.

### Step 2: Perform a Dry Run

Always run without the execution flag first to see a preview of HCL changes and API actions.

```bash
python3 migrate_tfc.py --token "your_token"

```

### Step 3: Execute Migration

Add the `--no-dry-run` flag. You will be prompted to type `YES` before any file modifications begin.

```bash
python3 migrate_tfc.py --token "your_token" --no-dry-run

```

---

## 6. Troubleshooting

| Issue | Likely Cause | Solution |
| --- | --- | --- |
| **"Workspace not found"** | API mismatch with folder name. | Ensure the local directory name matches the TFC workspace name for API tagging. |
| **"403 Forbidden"** | Insufficient Token permissions. | Use an Org or Team token with "Manage Workspaces" rights. |
| **"Init failed"** | Local cache corruption. | Delete the `.terraform/` folder in that directory and re-run. |
| **"Hostname Conflict"** | Regex collision. | The script uses word boundaries (`\b`) to ensure `hostname` is not confused with `name`. |
