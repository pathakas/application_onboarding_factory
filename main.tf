
resource "github_repository" "new_repo" {
  for_each    = var.new_repo_name
  name        = each.key
  description = "This Repository: ${each.key} for Application Platform has been created and managed using Terraform"
  visibility  = var.repo_visibility
  template {
    owner      = var.github_organization
    repository = each.value
  }
  has_issues         = true
  has_wiki           = false
  allow_merge_commit = false
  allow_squash_merge = true
  allow_rebase_merge = false
  # has_projects       = true

  vulnerability_alerts   = true # Enable security alerts for dependencies
  delete_branch_on_merge = true

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

resource "github_branch_protection" "per_branch" {
  for_each = local.branch_protections

  repository_id = each.value.repo_name
  pattern       = each.value.branch

  required_status_checks {
    strict   = each.value.settings.required_status_checks.strict
    contexts = each.value.settings.required_status_checks.contexts
  }

  enforce_admins = each.value.settings.enforce_admins

  required_pull_request_reviews {
    dismiss_stale_reviews      = each.value.settings.dismiss_stale_reviews
    require_code_owner_reviews = each.value.settings.require_code_owner_reviews
  }

  # depends_on = [github_repository_file.backend_tf]

}

resource "github_actions_secret" "repo_wise_secrets" {
  for_each = local.flattened_repo_secrets

  repository      = each.value.repository
  secret_name     = each.value.secret_name
  plaintext_value = each.value.secret

  depends_on = [github_repository.new_repo, github_branch_protection.per_branch]
}

resource "github_repository_collaborator" "user_collaborators" {
  for_each = merge([
    for repo, users in var.repo_user_collaborators : {
      for user in users :
      "${repo}-${user.username}" => {
        repository = repo
        username   = user.username
        permission = user.permission
      }
    }
  ]...)

  repository = each.value.repository
  username   = each.value.username
  permission = each.value.permission
  depends_on = [github_repository.new_repo]
}

data "github_team" "all_teams" {
  for_each = toset(flatten([
    for teams in values(var.repo_team_collaborators) :
    [for team in teams : team.team_slug]
  ]))

  slug = each.key
}

resource "github_team_repository" "team_collaborators" {
  for_each = merge([
    for repo, teams in var.repo_team_collaborators : {
      for team in teams :
      "${repo}-${team.team_slug}" => {
        repository = repo
        team_slug  = team.team_slug
        permission = team.permission
      }
    }
  ]...)

  team_id    = data.github_team.all_teams[each.value.team_slug].id
  repository = each.value.repository
  permission = each.value.permission
  depends_on = [github_repository.new_repo]
}

# resource "null_resource" "link_project" {
#   for_each = var.new_repo_name

#   provisioner "local-exec" {
#     command = "bash gh_project_create.sh ${each.key} ${var.github_organization}"
#   }

#   depends_on = [github_repository.new_repo]
# }

# resource "github_organization_project" "github_project" {
#   name       = var.ghreposproject
#   body       = "This is a Organization Project"
#   depends_on = [github_repository.new_repo]
# }

# resource "github_project_column" "todo_column" {
#   for_each   = var.new_repo_name
#   name       = "ToDo - ${each.key}"
#   project_id = github_organization_project.github_project.id
#   depends_on = [github_organization_project.github_project]
# }

# resource "github_issue" "test" {
#   for_each   = var.new_repo_name
#   repository = each.key #"mf-dt-azrabc-sampleapp-foundation-repo" #github_repository.test.name
#   title      = "Track ${each.key} progress"
#   body       = "Auto-created issue for project tracking."
#   depends_on = [github_project_column.todo_column]
# }

# resource "github_project_card" "issue_card" {
#   for_each     = var.new_repo_name
#   column_id    = github_project_column.todo_column[each.key].id
#   content_id   = github_issue.test[each.key].id
#   content_type = "Issue"
#   depends_on   = [github_issue.test]
# }

# resource "github_repository_file" "backend_tf" {
#   for_each = local.workspace_map

#   repository = each.value.vcs_repo
#   file       = "backend.tf"

#   content = templatefile("${path.module}/templates/backend.tf.tmpl", {
#     org_name       = var.tfc_organization
#     workspace_name = each.value.workspace_name
#   })

#   branch              = "main"
#   commit_message      = "Generate backend.tf for Terraform Cloud"
#   overwrite_on_create = true
# }

################## TFE Provider ####################

resource "tfe_project" "projects" {
  for_each     = var.projects
  name         = each.key
  organization = var.tfc_organization
  depends_on   = [github_repository.new_repo]
}
resource "tfe_workspace" "workspaces" {
  for_each = local.workspace_map

  name         = each.value.workspace_name
  organization = var.tfc_organization
  project_id   = tfe_project.projects[each.value.project_name].id

  # vcs_repo {
  #   identifier                 = each.value.vcs_repo
  #   branch                     = "main"
  #   ingress_submodules         = true
  #   github_app_installation_id = "ghaot-TpZu1FvmCrvdjchE"
  # }
  execution_mode = "remote"
  depends_on     = [tfe_project.projects]
}
resource "tfe_variable" "tfvars" {
  for_each = local.workspace_vars

  key          = each.value.key
  value        = each.value.value
  workspace_id = tfe_workspace.workspaces[each.value.workspace_key].id
  sensitive    = true
  category     = "env"
  depends_on   = [tfe_workspace.workspaces]
}

################ Azure Federated credentials Generation ##################################################

#provider "azuread" {
#  tenant_id = var.tenant_id
#}

#data "azurerm_subscription" "current" {}

# Federated identity credential for plan phase
# resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
#   for_each = local.workspace_map

#   application_object_id = var.application_object_id #data.azuread_application.existing_app.object_id
#   display_name          = "${each.value.workspace_name}-plan"
#   audiences             = [var.tfc_azure_audience]
#   issuer                = "https://${var.tfc_hostname}"
#   subject               = "organization:${var.tfc_organization_name}:project:${each.value.project_name}:workspace:${each.value.workspace_name}:run_phase:plan"
#   depends_on            = [tfe_project.projects, tfe_workspace.workspaces]
# }

# # Federated identity credential for apply phase
# resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
#   for_each = local.workspace_map

#   application_object_id = var.application_object_id #data.azuread_application.existing_app.object_id
#   display_name          = "${each.value.workspace_name}-apply"
#   audiences             = [var.tfc_azure_audience]
#   issuer                = "https://${var.tfc_hostname}"
#   subject               = "organization:${var.tfc_organization_name}:project:${each.value.project_name}:workspace:${each.value.workspace_name}:run_phase:apply"
#   depends_on            = [tfe_project.projects, tfe_workspace.workspaces]
# }

# # Assign Contributor role to the existing service principal
# resource "azurerm_role_assignment" "tfc_role_assignment" {
#   scope                = data.azurerm_subscription.current.id
#   principal_id         = var.principal_id #data.azuread_service_principal.existing_sp.object_id
#   role_definition_name = "Contributor"
# }
