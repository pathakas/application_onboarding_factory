output "repository_names" {
  description = "List of created GitHub repository names"
  value       = [for repo in github_repository.new_repo : repo.name]
}

output "repository_https_urls" {
  description = "List of GitHub repository web URLs"
  value       = [for repo in github_repository.new_repo : repo.html_url]
}


output "repository_ssh_urls" {
  description = "List of GitHub repository SSH clone URLs"
  value       = [for repo in github_repository.new_repo : repo.ssh_clone_url]
}

output "repositories" {
  description = "Map of repo names to full repository objects"
  value = {
    for name, repo in github_repository.new_repo :
    name => {
      https_url   = repo.html_url
      ssh_url     = repo.ssh_clone_url
      visibility  = repo.visibility
      description = repo.description
    }
  }
}

# Output all project names and their IDs
output "project_ids" {
  description = "Map of project names to their TFE project IDs"
  value = {
    for project_name, project in tfe_project.projects :
    project_name => project.id
  }
}

# Output all workspaces with full details
output "workspace_details" {
  description = "Detailed map of all workspaces"
  value = {
    for key, ws in tfe_workspace.workspaces :
    key => {
      name       = ws.name
      id         = ws.id
      project_id = ws.project_id
      # vcs_repo   = ws.vcs_repo[0].identifier
    }
  }
}

# Output all List of workspace names
output "workspace_names" {
  description = "List of all workspace names"
  value       = [for ws in tfe_workspace.workspaces : ws.name]
}

# Output all Map of workspace name to ID
output "workspace_ids" {
  description = "Map of workspace names to their TFE IDs"
  value = {
    for key, ws in tfe_workspace.workspaces :
    ws.name => ws.id
  }
}

# output "tfc_federated_credential_plan_ids" {
#   value = {
#     for k, v in azuread_application_federated_identity_credential.tfc_federated_credential_plan :
#     k => v.id
#   }
# }
# output "tfc_federated_credential_apply_ids" {
#   value = {
#     for k, v in azuread_application_federated_identity_credential.tfc_federated_credential_apply :
#     k => v.id
#   }
# }


# output "role_assignment_scope" {
#   value       = azurerm_role_assignment.tfc_role_assignment.scope
#   description = "The scope at which the Contributor role is assigned."
# }

# output "role_assignment_id" {
#   value       = azurerm_role_assignment.tfc_role_assignment.id
#   description = "The ID of the Contributor role assignment."
# }

output "resolved_template_path" {
  value = "${path.module}/templates/backend.tf.tmpl"
}

# output "project_columns" {
#   value = {
#     for repo, column in github_project_column.todo_column :
#     repo => column.name
#   }
# }


# output "created_issues" {
#   value = {
#     for repo, issue in github_issue.test :
#     repo => "https://github.com/McCainFoods/${repo}/issues/${issue.number}"
#   }
# }




