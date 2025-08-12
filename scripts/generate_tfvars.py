#!/usr/bin/env python3
import os
import sys
import json
import re
import shutil
from pathlib import Path

# ---------- helpers ----------

def infer_repo_type(full_repo_name):
    """Extract foundation|infra|app from REPO_NAME."""
    repo = full_repo_name.split("/", 1)[1] if "/" in full_repo_name else full_repo_name
    m = re.search(r"-(foundation|infra|app)-repo$", repo, re.IGNORECASE)
    if m:
        return m.group(1).lower()
    parts = repo.split("-")
    return (parts[-2].lower() if len(parts) >= 2 else "unknown")

def normalize_keys(env: dict) -> dict:
    """Make a lookup tolerant to case and common aliases/typos."""
    out = {}
    for k, v in env.items():
        if v is None:
            continue
        s = str(v)
        k1 = str(k)
        out[k1] = s
        out[k1.upper()] = s
        out[k1.lower()] = s

    # common aliases
    if "TFE_ORG" in out and "TFE_ORGANIZATION" not in out:
        out["TFE_ORGANIZATION"] = out["TFE_ORG"]
    if "TFE_WORKSPACE" in out and "TFE_WORKSPACE_NAME" not in out:
        out["TFE_WORKSPACE_NAME"] = out["TFE_WORKSPACE"]

    # tolerate the typo "WORSPACE"
    if "TFE_WORSPACE_NAME" in out and "TFE_WORKSPACE_NAME" not in out:
        out["TFE_WORKSPACE_NAME"] = out["TFE_WORSPACE_NAME"]

    return out

def replace_placeholders(content: str, env: dict) -> str:
    """
    Replace tokens using the merged env:
      - GitHub-style:   ${{ VAR }}
      - Go-template:    {{ VAR }} or {{ . VAR }}
      - Underscore:     __VAR__
    """
    m = normalize_keys(env)

    # ${{ VAR }}
    content = re.sub(r"\$\{\{\s*([A-Za-z0-9_]+)\s*\}\}", lambda g: m.get(g.group(1), g.group(0)), content)

    # {{ VAR }} and {{ . VAR }}
    content = re.sub(r"\{\{\s*\.?\s*([A-Za-z0-9_]+)\s*\}\}", lambda g: m.get(g.group(1), g.group(0)), content)

    # __VAR__
    content = re.sub(r"__([A-Z0-9_]+)__", lambda g: m.get(g.group(1), g.group(0)), content)

    return content

def find_terraform_files(source_dir):
    """Find all .tf and .tfvars files in the source directory (and simple modules)."""
    terraform_files = []
    source_path = Path(source_dir)

    # root .tf / .tfvars
    for pattern in ["*.tf", "*.tfvars"]:
        terraform_files.extend(source_path.glob(pattern))

    # shallow subdirs (exclude env folders and hidden)
    excluded_dirs = {'dev', 'qa', 'qat', 'prod', 'staging', 'uat', 'production', '.git', '.terraform', 'factory'}
    for subdir in source_path.iterdir():
        if subdir.is_dir() and subdir.name not in excluded_dirs and not subdir.name.startswith('.'):
            for pattern in ["*.tf", "*.tfvars"]:
                terraform_files.extend(subdir.glob(pattern))

    return terraform_files

# --- NEW: backend.tf safe replacement helpers ---

def _is_placeholder(val: str) -> bool:
    """Return True if the string still looks like a placeholder."""
    if val is None:
        return False
    return bool(re.search(r'(\{\{.*\}\}|\$\{\{.*\}\}|__.*__)', val)) or val.strip() in {
        "TFE_ORGANIZATION", "TFE_WORKSPACE_NAME", "TFE_WORSPACE_NAME"
    }

def safe_replace_backend(content: str, env: dict) -> str:
    """
    In backend.tf, replace organization/name only if they are placeholders.
    Otherwise keep existing literal values.
    Supports both 'organization = "..."' and 'name = "..."'.
    """
    org_pat = re.compile(r'(organization\s*=\s*)"([^"]*)"')
    name_pat = re.compile(r'(\bname\s*=\s*)"([^"]*)"')

    def repl_org(m):
        existing = m.group(2)
        if _is_placeholder(existing):
            return f'{m.group(1)}"{env.get("TFE_ORGANIZATION", "")}"'
        return m.group(0)

    def repl_name(m):
        existing = m.group(2)
        if _is_placeholder(existing):
            ws = env.get("TFE_WORKSPACE_NAME") or env.get("TFE_WORSPACE_NAME") or ""
            return f'{m.group(1)}"{ws}"'
        return m.group(0)

    content = org_pat.sub(repl_org, content)
    content = name_pat.sub(repl_name, content)
    return content

def copy_and_process_files(source_files, target_dir, env, source_path):
    """Copy and process all Terraform files with token replacement."""
    processed_files = []

    for source_file in source_files:
        try:
            content = source_file.read_text(encoding='utf-8')
            processed_content = replace_placeholders(content, env)

            # If it's backend.tf, only replace org/workspace when placeholders remain
            if source_file.name == "backend.tf":
                processed_content = safe_replace_backend(processed_content, env)

            # preserve relative structure for shallow modules
            if source_file.parent == source_path:
                target_file = target_dir / source_file.name
            else:
                relative_path = source_file.relative_to(source_path)
                target_file = target_dir / relative_path.parent / source_file.name

            target_file.parent.mkdir(parents=True, exist_ok=True)
            target_file.write_text(processed_content, encoding='utf-8')
            processed_files.append(target_file)
            print(f"Processed: {source_file} -> {target_file}")
        except Exception as e:
            print(f"[ERROR] Failed to process {source_file}: {e}")
            continue

    return processed_files

def copy_additional_files(source_dir, target_dir):
    """Copy additional non-Terraform files that might be needed."""
    additional_patterns = [
        "*.json", "*.yml", "*.yaml", "*.md", "*.sh", ".terraform.lock.hcl"
    ]
    source_path = Path(source_dir)
    copied_files = []
    for pattern in additional_patterns:
        for source_file in source_path.glob(pattern):
            if source_file.is_file():
                target_file = target_dir / source_file.name
                try:
                    shutil.copy2(source_file, target_file)
                    copied_files.append(target_file)
                    print(f"Copied: {source_file} -> {target_file}")
                except Exception as e:
                    print(f"[WARNING] Failed to copy {source_file}: {e}")
    return copied_files

def validate_processed_files(files):
    """Validate that all placeholders (${...}, {{...}}, __...__) have been resolved."""
    unresolved = []
    pat1 = re.compile(r"\$\{\{\s*[A-Za-z0-9_]+\s*\}\}")     # ${{ VAR }}
    pat2 = re.compile(r"\{\{\s*\.?\s*[A-Za-z0-9_]+\s*\}\}") # {{ VAR }} / {{ . VAR }}
    pat3 = re.compile(r"__([A-Z0-9_]+)__")                  # __VAR__

    for file_path in files:
        try:
            content = file_path.read_text(encoding='utf-8')
            hits = []
            hits += pat1.findall(content)
            hits += pat2.findall(content)
            hits += pat3.findall(content)
            if hits:
                unresolved.append((file_path, hits))
                print(f"[WARNING] Unresolved placeholders in {file_path}: {hits}")
        except Exception as e:
            print(f"[ERROR] Failed to validate {file_path}: {e}")

    return unresolved

# ---------- main ----------

def main():
    current_dir = Path(".")
    print(f"[INFO] Working directory: {current_dir.absolute()}")
    print(f"[INFO] Will process .tf files from current directory and create environment subdirectories")

    repo_name = os.environ.get("REPO_NAME", "")
    repo_type = infer_repo_type(repo_name)  # foundation|infra|app|unknown
    print(f"[INFO] Repository: {repo_name}")
    print(f"[INFO] Detected repo type: {repo_type}")

    # Environments JSON
    try:
        envs = json.loads(os.environ.get("APP_ENVT", "[]"))
        if not envs:
            envs = [{"name": "default", "code": "default"}]
    except Exception as e:
        sys.exit(f"ERROR: Invalid APP_ENVT JSON: {e}")

    terraform_files = find_terraform_files(current_dir)
    print(f"[INFO] Found {len(terraform_files)} Terraform files to process")
    if not terraform_files:
        print("[WARNING] No Terraform files found in current directory")
        return

    base_env = dict(os.environ)

    # defaults for naming
    org_code = base_env.get("ORGANIZATION_CODE", "mf")
    lob_code = base_env.get("LOB_CODE", "dt")
    app_code = base_env.get("APP_CODE", "azrabc")
    app_name = base_env.get("APP_NAME", "sampleapp")

    # workspace template (override via env WORKSPACE_TEMPLATE if needed)
    ws_tmpl = os.environ.get(
        "WORKSPACE_TEMPLATE",
        "{ORGANIZATION_CODE}-{LOB_CODE}-{APP_CODE}-{APP_NAME}-{REPO_TYPE}-{ENVIRONMENT_CODE}-tfcws"
    )

    all_processed_files = []

    for env_obj in envs:
        env_code = (env_obj.get("code") or "default").lower()
        env_name = env_obj.get("name", env_code)

        print(f"\n[INFO] Processing environment: {env_name} ({env_code})")

        env_target_dir = current_dir / env_code
        env_target_dir.mkdir(parents=True, exist_ok=True)

        merged_env = {**base_env, **env_obj}
        merged_env.update({
            "ENVIRONMENT_CODE": env_code,
            "ENVIRONMENT_NAME": env_name,
            "REPO_TYPE": repo_type,  # we’ll use this in workspace template
            "REPO_NAME_CLEAN": repo_name.split('/')[-1] if '/' in repo_name else repo_name
        })

        # ---- Compute organization and workspace names (can be overridden by env) ----
        tfe_org = (merged_env.get("TFE_ORGANIZATION")
                   or merged_env.get("TFE_ORG")
                   or f"{org_code}-{lob_code}-{app_code}-{app_name}")

        fmt = {
            **merged_env,
            "ORGANIZATION_CODE": org_code,
            "LOB_CODE": lob_code,
            "APP_CODE": app_code,
            "APP_NAME": app_name,
            "REPO_TYPE": repo_type,           # foundation|infra|app
            "ENVIRONMENT_CODE": env_code,     # dev|prd|qat...
        }

        tfe_ws = (merged_env.get("TFE_WORKSPACE_NAME")
                  or merged_env.get("TFE_WORKSPACE")
                  or ws_tmpl.format(**fmt))

        # expose to replacement (support typos/aliases)
        merged_env.update({
            "TFE_ORGANIZATION": tfe_org,
            "TFE_WORKSPACE_NAME": tfe_ws,
            "TFE_WORKSPACE": tfe_ws,
            "TFE_WORSPACE_NAME": tfe_ws,  # common typo tolerated
        })

        # ---- Copy & process all .tf and .tfvars (includes backend.tf) ----
        processed_files = copy_and_process_files(
            terraform_files,
            env_target_dir,
            merged_env,
            current_dir
        )

        # Copy some helpful non-TF files (readme, cfg, etc.)
        additional_files = copy_additional_files(current_dir, env_target_dir)

        all_processed_files.extend(processed_files)
        print(f"[INFO] Environment {env_code}: {len(processed_files)} files processed, {len(additional_files)} additional files copied")

    # Validate everything
    print(f"\n[INFO] Validating {len(all_processed_files)} processed files...")
    unresolved_files = validate_processed_files(all_processed_files)
    if unresolved_files:
        print(f"\n[ERROR] Found unresolved placeholders in {len(unresolved_files)} files:")
        for file_path, placeholders in unresolved_files:
            print(f"  {file_path}: {placeholders}")
        sys.exit(1)

    print(f"\n[SUCCESS] Successfully processed {len(all_processed_files)} files across {len(envs)} environments")

if __name__ == "__main__":
    main()
