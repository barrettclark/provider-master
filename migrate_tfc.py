import argparse
import os
import re
import json
import subprocess
import requests
import sys

# --- Constants & Defaults ---
DEFAULT_HOSTNAME = "app.terraform.io"
# Update this list for your run
TARGET_DIRECTORIES = ["/Users/barrett.clark/Projects/terraform-minimum"]

# Regex for targeted HCL replacement
REMOTE_BACKEND_RE = re.compile(
    r'(terraform\s+\{.*?)backend\s+"remote"\s+\{(?P<backend_content>.*?)\}(.*?\})',
    re.MULTILINE | re.DOTALL)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Migrate TFC Remote Backend to Cloud Block.")
    parser.add_argument("--token",
                        help="TFC/TFE API Token (Overrides TFC_TOKEN env var)")
    parser.add_argument(
        "--hostname",
        help=
        f"TFC/TFE Hostname (Overrides TFC_HOSTNAME env var, default: {DEFAULT_HOSTNAME})"
    )
    parser.add_argument("--no-dry-run",
                        action="store_true",
                        help="Actually apply changes to files and TFC")
    return parser.parse_args()


def get_config(args):
    """Resolves configuration from CLI args, Env Vars, or Constants."""
    token = args.token or os.getenv("TFC_TOKEN")
    hostname = args.hostname or os.getenv("TFC_HOSTNAME") or DEFAULT_HOSTNAME

    if not args.no_dry_run:
        print(f"💡 MODE: DRY RUN (No changes will be saved)")
    elif not token:
        print(
            "❌ ERROR: No TFC Token found. Use --token or set TFC_TOKEN env var."
        )
        sys.exit(1)

    print(f"🌐 TARGET HOST: {hostname}")
    return token, hostname


def ensure_tfc_tag(hostname, org, workspace_name, tag, token):
    """Uses the resolved hostname for the API call."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/vnd.api+json"
    }
    base_url = f"https://{hostname}/api/v2"

    try:
        url = f"{base_url}/organizations/{org}/workspaces/{workspace_name}"
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            ws_data = resp.json()['data']
            ws_id = ws_data['id']
            existing_tags = [
                t['attributes']['name']
                for t in ws_data['attributes'].get('tags', [])
            ]

            if tag not in existing_tags:
                tag_url = f"{base_url}/workspaces/{ws_id}/relationships/tags"
                requests.post(tag_url,
                              headers=headers,
                              json={
                                  "data": [{
                                      "type": "tags",
                                      "attributes": {
                                          "name": tag
                                      }
                                  }]
                              })
                print(
                    f"  └─ API: Added tag '{tag}' to workspace '{workspace_name}' on {hostname}"
                )
    except Exception as e:
        print(f"  └─ API Error: Failed to contact {hostname}: {e}")


def migrate_directory(folder, token, hostname, dry_run):
    target_files = ["main.tf", "backend.tf", "versions.tf", "terraform.tf", "remote.tf"]
    for filename in target_files:
        path = os.path.join(folder, filename)
        if not os.path.exists(path):
            continue

        with open(path, 'r') as f:
            content = f.read()
        match = REMOTE_BACKEND_RE.search(content)

        if match:
            ws_info = match.group('backend_content')

            # Use word boundaries to extract specific attributes
            org_m = re.search(r'\borganization\s+=\s+"(?P<val>[^"]+)"',
                              ws_info)
            name_m = re.search(r'\bname\s+=\s+"(?P<val>[^"]+)"', ws_info)
            pref_m = re.search(r'\bprefix\s+=\s+"(?P<val>[^"]+)"', ws_info)

            if not org_m:
                continue

            org = org_m.group('val')
            # Hostline logic: only include hostname in cloud block if it's not the default
            host_line = f'    hostname = "{hostname}"\n' if hostname != "app.terraform.io" else ""

            if name_m:
                ws_config = f'name = "{name_m.group("val")}"'
            elif pref_m:
                clean_tag = pref_m.group("val").strip('-')
                ws_config = f'tags = ["{clean_tag}"]'
                if not dry_run:
                    # In this flow, we assume the directory name is the workspace name for API tagging
                    ws_name_api = os.path.basename(os.path.abspath(folder))
                    ensure_tfc_tag(hostname, org, ws_name_api, clean_tag,
                                   token)
            else:
                continue

            cloud_block = f'cloud {{\n{host_line}    organization = "{org}"\n    workspaces {{\n      {ws_config}\n    }}\n  }}'
            new_content = REMOTE_BACKEND_RE.sub(rf'\1{cloud_block}\3', content)

            if not dry_run:
                with open(path, 'w') as f:
                    f.write(new_content)
                print(f"  └─ HCL: Successfully migrated {filename}")
                subprocess.run(
                    ["terraform", "init", "-migrate-state", "-input=false"],
                    cwd=folder,
                    check=True)
            else:
                print(
                    f"  └─ [DRY RUN] Would update {filename} with host '{hostname}' and {ws_config}"
                )
            return True
    return False


def main():
    args = parse_args()
    token, hostname = get_config(args)
    dry_run = not args.no_dry_run

    if not dry_run:
        confirm = input(
            f"\n⚠️ Proceed with {len(TARGET_DIRECTORIES)} migrations? Type 'YES': "
        )
        if confirm != "YES":
            sys.exit(0)

    for d in TARGET_DIRECTORIES:
        print(f"\n--- Processing Folder: {d} ---")
        if not migrate_directory(d, token, hostname, dry_run):
            print("  └─ No remote backend found. Skipping.")


if __name__ == "__main__":
    main()
