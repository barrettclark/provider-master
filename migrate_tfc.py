import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional

import requests

# --- Constants & Defaults ---
DEFAULT_HOSTNAME = "app.terraform.io"
DEFAULT_TARGET_DIRECTORIES = ["."]

# Regex for targeted HCL replacement
REMOTE_BACKEND_RE = re.compile(
    r'(terraform\s+\{.*?)backend\s+"remote"\s+\{(?P<backend_content>.*?)\}(.*?\})',
    re.MULTILINE | re.DOTALL,
)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Migrate TFC Remote Backend to Cloud Block.",
    )
    parser.add_argument(
        "--token",
        help="TFC/TFE API Token (overrides TFC_TOKEN env var)",
    )
    parser.add_argument(
        "--hostname",
        help=f"TFC/TFE hostname (overrides TFC_HOSTNAME env var, default: {DEFAULT_HOSTNAME})",
    )
    parser.add_argument(
        "--no-dry-run",
        action="store_true",
        help="Actually apply changes to files and TFC",
    )
    parser.add_argument(
        "-d",
        "--directory",
        action="append",
        dest="directories",
        default=None,
        metavar="DIR",
        help="Directory to migrate (repeatable). Default: current directory.",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Write .bak backup of modified files before changing them",
    )
    return parser.parse_args()


def get_config(args):
    """Resolve configuration from CLI args, env vars, or constants."""
    token = args.token or os.getenv("TFC_TOKEN")
    hostname = args.hostname or os.getenv("TFC_HOSTNAME") or DEFAULT_HOSTNAME
    directories = args.directories or DEFAULT_TARGET_DIRECTORIES
    directories = [os.path.abspath(d) for d in directories]

    if not args.no_dry_run:
        print("💡 MODE: DRY RUN (no changes will be saved)")
    elif not token:
        print("❌ ERROR: No TFC token. Use --token or set TFC_TOKEN env var.")
        sys.exit(1)

    print(f"🌐 TARGET HOST: {hostname}")
    return token, hostname, directories


def check_terraform_installed() -> None:
    """Check if terraform binary is available in PATH."""
    try:
        subprocess.run(
            ["terraform", "version"],
            capture_output=True,
            check=True,
            timeout=10,
        )
    except FileNotFoundError:
        print("❌ ERROR: terraform binary not found. Please install Terraform.")
        sys.exit(1)
    except subprocess.CalledProcessError:
        print("❌ ERROR: terraform binary exists but failed to run.")
        sys.exit(1)


def ensure_tfc_tag(
    hostname: str,
    org: str,
    workspace_name: str,
    tag: str,
    token: str,
) -> None:
    """Ensure the workspace has the given tag; add it via TFC API if missing."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/vnd.api+json",
    }
    base_url = f"https://{hostname}/api/v2"

    try:
        url = f"{base_url}/organizations/{org}/workspaces/{workspace_name}"
        resp = requests.get(url, headers=headers, timeout=30)
        if resp.status_code != 200:
            print(
                f"  └─ API: GET workspace failed ({resp.status_code}): {resp.text[:200]}"
            )
            return
        ws_data = resp.json()["data"]
        ws_id = ws_data["id"]
        # Workspace show returns tag-names (list of strings), not tags.
        existing = ws_data.get("attributes", {}).get("tag-names") or []

        if tag in existing:
            return
        tag_url = f"{base_url}/workspaces/{ws_id}/relationships/tags"
        post = requests.post(
            tag_url,
            headers=headers,
            json={"data": [{"type": "tags", "attributes": {"name": tag}}]},
            timeout=30,
        )
        if post.status_code in (200, 204):
            print(
                f"  └─ API: Added tag '{tag}' to workspace '{workspace_name}' on {hostname}"
            )
        else:
            print(
                f"  └─ API: Add tag failed ({post.status_code}): {post.text[:200]}"
            )
    except requests.RequestException as e:
        print(f"  └─ API Error: {hostname}: {e}")


def discover_tf_files(directory: str) -> List[str]:
    """
    Discover all Terraform configuration files (.tf) in the given directory.
    Excludes .tfvars, .tfstate, and backup files.
    Returns a sorted list of filenames (not full paths).
    """
    excluded_patterns = ('.tfvars', '.tfstate', '.backup', '.bak')
    tf_files = []

    try:
        for entry in os.listdir(directory):
            # Check if it's a file and ends with .tf
            full_path = os.path.join(directory, entry)
            if os.path.isfile(full_path) and entry.endswith('.tf'):
                # Exclude files matching excluded patterns
                if not any(pattern in entry for pattern in excluded_patterns):
                    tf_files.append(entry)
    except (OSError, PermissionError) as e:
        print(f"  └─ Warning: Could not read directory {directory}: {e}")
        return []

    return sorted(tf_files)


def migrate_directory(
    folder: str,
    token: Optional[str],
    hostname: str,
    dry_run: bool,
    backup: bool,
) -> bool:
    """
    Migrate remote backend to cloud block in discovered .tf files.
    Scans all .tf files in the directory and processes the first one containing a remote backend.
    Returns True if migrated.
    """
    tf_files = discover_tf_files(folder)

    if not tf_files:
        print("  └─ No .tf files found in directory")
        return False

    files_with_backends = []
    for filename in tf_files:
        path = os.path.join(folder, filename)

        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
        except (OSError, PermissionError) as e:
            print(f"  └─ Warning: Could not read {filename}: {e}")
            continue
        match = REMOTE_BACKEND_RE.search(content)

        if not match:
            continue

        files_with_backends.append(filename)

    # Warn if multiple files contain remote backends
    if len(files_with_backends) > 1:
        print(f"  └─ Warning: Found {len(files_with_backends)} files with remote backends: {', '.join(files_with_backends)}")
        print(f"  └─ Warning: Only the first file ({files_with_backends[0]}) will be migrated")

    # Process the first file with a remote backend
    for filename in files_with_backends[:1]:
        path = os.path.join(folder, filename)

        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        match = REMOTE_BACKEND_RE.search(content)
        ws_info = match.group("backend_content")

        # Match patterns but exclude commented lines (lines starting with optional whitespace + #)
        # Note: This regex won't catch inline comments like: organization = "foo" # comment
        # For more robust parsing, consider using python-hcl2 library
        org_m = re.search(r'(?m)^(?![\s]*#).*?\borganization\s+=\s+"(?P<val>[^"]+)"', ws_info)
        name_m = re.search(r'(?m)^(?![\s]*#).*?\bname\s+=\s+"(?P<val>[^"]+)"', ws_info)
        pref_m = re.search(r'(?m)^(?![\s]*#).*?\bprefix\s+=\s+"(?P<val>[^"]+)"', ws_info)

        if not org_m:
            continue

        org = org_m.group("val")
        host_line = (
            f'    hostname = "{hostname}"\n'
            if hostname != DEFAULT_HOSTNAME
            else ""
        )

        if name_m:
            ws_config = f'name = "{name_m.group("val")}"'
            ws_name_api = None
            clean_tag = None
        elif pref_m:
            clean_tag = pref_m.group("val").strip("-")
            ws_config = f'tags = ["{clean_tag}"]'
            ws_name_api = Path(folder).resolve().name
        else:
            continue

        cloud_block = (
            f'cloud {{\n{host_line}    organization = "{org}"\n'
            f"    workspaces {{\n      {ws_config}\n    }}\n  }}"
        )
        new_content = REMOTE_BACKEND_RE.sub(rf"\1{cloud_block}", content)

        if dry_run:
            tag_msg = f" and add tag to '{ws_name_api}'" if ws_name_api else ""
            print(
                f"  └─ [DRY RUN] Would update {filename} with host '{hostname}'"
                f", {ws_config}{tag_msg}"
            )
            return True
        if backup:
            shutil.copy2(path, f"{path}.bak")
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"  └─ HCL: Migrated {filename}")

        # Format the file with terraform fmt
        try:
            subprocess.run(
                ["terraform", "fmt", path],
                cwd=folder,
                check=True,
                capture_output=True,
            )
            print(f"  └─ HCL: Formatted {filename}")
        except subprocess.CalledProcessError as e:
            print(f"  └─ Warning: Could not format {filename}: {e}")

        # Run terraform init and automatically answer "yes" to migrate state
        # Note: -migrate-state flag is NOT compatible with Terraform Cloud migrations
        # TFC requires interactive prompts, so we pipe "yes" to stdin instead
        process = subprocess.Popen(
            ["terraform", "init"],
            cwd=folder,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        output, _ = process.communicate(input="yes\n")
        print(output)
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, "terraform init")
        print(f"  └─ Terraform: Initialized workspace and migrated state")

        # Add tag to workspace after init (for prefix-based workspaces)
        if ws_name_api and clean_tag and token:
            ensure_tfc_tag(hostname, org, ws_name_api, clean_tag, token)

        return True
    return False


def main() -> None:
    args = parse_args()
    check_terraform_installed()
    token, hostname, directories = get_config(args)
    dry_run = not args.no_dry_run

    if not dry_run:
        confirm = input(
            f"\n⚠️ Proceed with {len(directories)} migration(s)? Type 'YES': "
        )
        if confirm != "YES":
            sys.exit(0)

    for d in directories:
        print(f"\n--- {d} ---")
        if not migrate_directory(
            d, token, hostname, dry_run, backup=bool(args.backup)
        ):
            print("  └─ No remote backend found. Skipping.")


if __name__ == "__main__":
    main()

# Made with Bob
