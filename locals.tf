locals {
  flattened_repo_secrets = merge([
    for repo, secrets in var.repo_secrets : {
      for secret_name, secret_value in secrets :
      "${repo}-${secret_name}" => {
        repository  = repo
        secret_name = secret_name
        secret      = secret_value
      }
    }
  ]...)
  branches_to_protect = {
    main = {
      required_status_checks = {
        strict   = true
        contexts = ["Lint", "Security Scan", "Build & Test"]
      }
      enforce_admins             = true
      dismiss_stale_reviews      = true
      require_code_owner_reviews = true
    }
    dev = {
      required_status_checks = {
        strict   = false
        contexts = []
      }
      enforce_admins             = false
      dismiss_stale_reviews      = true
      require_code_owner_reviews = false
    }
    release = {
      required_status_checks = {
        strict   = true
        contexts = ["Build"]
      }
      enforce_admins             = false
      dismiss_stale_reviews      = true
      require_code_owner_reviews = false
    }
  }

  branch_protections = merge([
    for repo_key, repo in github_repository.new_repo : {
      for branch, settings in local.branches_to_protect :
      "${repo_key}-${branch}" => {
        repo_name = repo.name
        branch    = branch
        settings  = settings
      }
    }
  ]...)

  # Create a flattened map of workspaces using merge and for expressions
  workspace_map = merge([
    for project_name, project_data in var.projects : {
      for workspace_name, ws_data in project_data.workspaces :
      "${project_name}-${workspace_name}" => {
        project_name   = project_name
        workspace_name = workspace_name
        vcs_repo       = ws_data.vcs_repo
      }
    }
  ]...)

  # Flatten workspace variables with merge
  workspace_vars = merge([
    for project_name, project_data in var.projects : merge([
      for workspace_name, ws_data in project_data.workspaces : {
        for var_key, var_val in ws_data.tf_vars :
        "${project_name}-${workspace_name}-${var_key}" => {
          workspace_key = "${project_name}-${workspace_name}"
          key           = var_key
          value         = var_val
        }
      }
    ]...)
  ]...)
}

