#!/usr/bin/env python3
import os, sys, json, re
from pathlib import Path

def infer_repo_type(full_repo_name):
    """Extract foundation|infra|app from REPO_NAME."""
    repo = full_repo_name.split("/", 1)[1] if "/" in full_repo_name else full_repo_name
    m = re.search(r"-(foundation|infra|app)-repo$", repo)
    if m:
        return m.group(1)
    parts = repo.split("-")
    return parts[-2] if len(parts) >= 2 else "unknown"

def replace_placeholders(content, env):
    """Replace placeholders ${{VAR}} with env values."""
    return re.sub(r"\$\{\{(\w+)\}\}", lambda m: env.get(m.group(1), m.group(0)), content)

def main():
    # Path to terraform.tfvars (default: current dir)
    tfvars_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("terraform.tfvars")

    if not tfvars_path.exists():
        print(f"[INFO] No terraform.tfvars found at: {tfvars_path}")
        sys.exit(f"ERROR: terraform.tfvars not found at {tfvars_path}")

    repo_type = infer_repo_type(os.environ.get("REPO_NAME", ""))
    print(f"[INFO] Detected repo type: {repo_type}")

    template = tfvars_path.read_text()

    # Parse environments JSON
    try:
        envs = json.loads(os.environ.get("APP_ENVT", "[]"))
    except Exception as e:
        sys.exit(f"Invalid APP_ENVT JSON: {e}")

    base_env = dict(os.environ)

    for env_obj in envs:
        code = env_obj.get("code", "env").lower()
        out_dir = tfvars_path.parent / code
        out_dir.mkdir(parents=True, exist_ok=True)

        out_file = out_dir / f"{repo_type}-{code}.tfvars"
        merged_env = {**base_env, **env_obj}
        rendered = replace_placeholders(template, merged_env)

        if re.search(r"\$\{\{(\w+)\}\}", rendered):
            sys.exit(f"Unresolved placeholders in {out_file}")

        out_file.write_text(rendered)
        print(f"Generated: {out_file}")

if __name__ == "__main__":
    main()
