#!/usr/bin/env python3
import os
import sys
import json
import re
import shutil
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


def find_terraform_files(source_dir):
    """Find all .tf and .tfvars files in the source directory (repo root)."""
    terraform_files = []
    source_path = Path(source_dir)
    
    # Find all .tf and .tfvars files in the root directory
    for pattern in ["*.tf", "*.tfvars"]:
        terraform_files.extend(source_path.glob(pattern))
    
    # Also check subdirectories for modules (but exclude environment dirs like dev/, qa/, prod/)
    excluded_dirs = {'dev', 'qa', 'qat', 'prod', 'staging', 'uat', 'production', '.git', '.terraform', 'factory'}
    for subdir in source_path.iterdir():
        if subdir.is_dir() and subdir.name not in excluded_dirs and not subdir.name.startswith('.'):
            for pattern in ["*.tf", "*.tfvars"]:
                terraform_files.extend(subdir.glob(pattern))
    
    return terraform_files


def copy_and_process_files(source_files, target_dir, env, repo_type, env_code, source_path):
    """Copy and process all Terraform files with token replacement."""
    processed_files = []
    
    for source_file in source_files:
        try:
            content = source_file.read_text(encoding='utf-8')
            
            # Replace placeholders in the content
            processed_content = replace_placeholders(content, env)
            
            # Determine target filename - keep terraform.tfvars as terraform.tfvars
            target_filename = source_file.name
            
            # Create target file path, preserving directory structure for modules
            # but placing everything under the environment directory
            if source_file.parent == source_path:
                # File is in root directory, place directly in env directory
                target_file = target_dir / target_filename
            else:
                # File is in a subdirectory (like modules/), preserve that structure
                relative_path = source_file.relative_to(source_path)
                target_file = target_dir / relative_path.parent / target_filename
            
            # Ensure target directory exists
            target_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Write processed content
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
        "*.json",
        "*.yml", 
        "*.yaml",
        "*.md",
        "*.sh",
        ".terraform.lock.hcl"
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


def validate_processed_files(files, env_code):
    """Validate that all placeholders have been resolved."""
    unresolved_files = []
    
    for file_path in files:
        try:
            content = file_path.read_text(encoding='utf-8')
            unresolved_matches = re.findall(r"\$\{\{(\w+)\}\}", content)
            
            if unresolved_matches:
                unresolved_files.append((file_path, unresolved_matches))
                print(f"[WARNING] Unresolved placeholders in {file_path}: {unresolved_matches}")
                
        except Exception as e:
            print(f"[ERROR] Failed to validate {file_path}: {e}")
    
    return unresolved_files


def main():
    # Work in current directory (the target repo directory)
    current_dir = Path(".")
    
    print(f"[INFO] Working directory: {current_dir.absolute()}")
    
    # Source files are the .tf files in current directory
    print(f"[INFO] Will process .tf files from current directory and create environment subdirectories")
    
    # Get repository information
    repo_name = os.environ.get("REPO_NAME", "")
    repo_type = infer_repo_type(repo_name)
    print(f"[INFO] Repository: {repo_name}")
    print(f"[INFO] Detected repo type: {repo_type}")
    
    # Parse environments JSON
    try:
        envs = json.loads(os.environ.get("APP_ENVT", "[]"))
        if not envs:
            envs = [{"name": "default", "code": "default"}]  # fallback
    except Exception as e:
        sys.exit(f"ERROR: Invalid APP_ENVT JSON: {e}")
    
    # Find all Terraform files in current directory
    terraform_files = find_terraform_files(current_dir)
    print(f"[INFO] Found {len(terraform_files)} Terraform files to process")
    
    if not terraform_files:
        print("[WARNING] No Terraform files found in current directory")
        return
    
    # Base environment variables
    base_env = dict(os.environ)
    
    # Process files for each environment
    all_processed_files = []
    for env_obj in envs:
        env_code = env_obj.get("code", "default").lower()
        env_name = env_obj.get("name", env_code)
        
        print(f"\n[INFO] Processing environment: {env_name} ({env_code})")
        
        # Create environment-specific directory
        env_target_dir = current_dir / env_code
        env_target_dir.mkdir(parents=True, exist_ok=True)
        
        # Merge environment-specific variables
        merged_env = {**base_env, **env_obj}
        
        # Add some computed variables
        merged_env.update({
            'ENVIRONMENT_CODE': env_code,
            'ENVIRONMENT_NAME': env_name,
            'REPO_TYPE': repo_type,
            'REPO_NAME_CLEAN': repo_name.split('/')[-1] if '/' in repo_name else repo_name
        })
        
        # Process and copy Terraform files
        processed_files = copy_and_process_files(
            terraform_files, 
            env_target_dir, 
            merged_env, 
            repo_type, 
            env_code,
            current_dir  # Pass current_dir for relative path calculation
        )
        
        # Copy additional files
        additional_files = copy_additional_files(current_dir, env_target_dir)
        
        all_processed_files.extend(processed_files)
        
        print(f"[INFO] Environment {env_code}: {len(processed_files)} files processed, {len(additional_files)} additional files copied")
    
    # Validate all processed files
    print(f"\n[INFO] Validating {len(all_processed_files)} processed files...")
    unresolved_files = validate_processed_files(all_processed_files, "all")
    
    if unresolved_files:
        print(f"\n[ERROR] Found unresolved placeholders in {len(unresolved_files)} files:")
        for file_path, placeholders in unresolved_files:
            print(f"  {file_path}: {placeholders}")
        sys.exit(1)
    
    print(f"\n[SUCCESS] Successfully processed {len(all_processed_files)} files across {len(envs)} environments")


if __name__ == "__main__":
    main()