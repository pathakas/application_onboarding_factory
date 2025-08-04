variable "github_token" {
  type        = string
  description = "GitHub token for for accessing and provision repos using automation"
  nullable    = false
}

variable "github_organization" {
  description = "GitHub Organization Name"
  type        = string
  default     = "McCainFoods"
}
# variable "template_repo" {
#   description = "GitHub Repository Template Name"
#   type        = string
#   default     = "mf-mdm-landing-zone"
# }
variable "new_repo_name" {
  description = "Name of the new repository mapped with a template repository"
  type        = map(string)
  default     = {}
}
variable "repo_visibility" {
  description = "Visibility of the repository (private/public)"
  type        = string
  default     = "private"
}

variable "repo_secrets" {
  description = "Map of repositories and their secrets"
  type        = map(map(string))
}

variable "repo_user_collaborators" {
  description = "Map of users to be added to specific repos"
  type = map(list(object({
    username   = string
    permission = string
  })))
}

variable "repo_team_collaborators" {
  description = "Map of teams to repos and permissions"
  type = map(list(object({
    team_slug  = string
    permission = string
  })))
}

variable "ghreposproject" {
  description = "Name of the project mapped with the list of repos"
  type        = string
}

##### TFE Provider ############################

variable "tfc_organization" {
  type    = string
  default = "Mccain_Foods"
}

variable "projects" {
  type = map(object({
    workspaces = map(object({
      vcs_repo = string
      tf_vars  = map(string)
    }))
  }))
}
variable "tfe_token" {
  description = "Terraform Personal Access Token"
  type        = string
  sensitive   = true
}

variable "tfc_azure_audience" {
  type        = string
  default     = "api://AzureADTokenExchange"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with Azure"
}

variable "tfc_organization_name" {
  type        = string
  default     = "Mccain_Foods"
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  default     = "TFC-MDIxAI-OIDC-Integration"
  description = "The project under which a workspace will be created"
}

variable "tfc_workspace_name" {
  type        = string
  default     = "Development"
  description = "The name of the workspace that you'd like to create and connect to Azure"
}

variable "existing_aad_app_display_name" {
  description = "The display name of the existing Azure AD Application"
  type        = string
}

variable "principal_id" {
  description = "Service Principal object ID"
  type        = string
}

variable "application_object_id" {
  description = "application_object_id of Azure AD application"
  type        = string
}

variable "tenant_id" {
  description = "Azure Subscription Tenant ID"
  type        = string
}
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}
variable "client_id" {
  description = "AAD Client ID"
  type        = string
}
variable "client_secret" {
  description = "AAD Client secret"
}
