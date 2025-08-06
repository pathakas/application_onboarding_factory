# terraform.tfvars.tpl

# ————————————————————————————
# Core settings
# ————————————————————————————
github_organization = "${GITHUB_ORGANIZATION}"
repo_visibility     = "${REPO_VISIBILITY}"

# ————————————————————————————
# Repository creation mapping
# ————————————————————————————
new_repo_name = {
  "${FOUNDATION_REPO}" = "mf-platform-azure-foundation-template-main"
  "${INFRA_REPO}"      = "mf-platform-azure-infra-template-main"
  "${APP_REPO}"        = "mf-platform-azure-app-reactjs-template-main"
}

# ————————————————————————————
# Repository-specific secrets (DIFFERENTIATED)
# ————————————————————————————
repo_secrets = {
  "${FOUNDATION_REPO}" = {
    GH_TOKEN              = "${GHE_FOUNDATION_TOKEN}"
    AZURE_SUBSCRIPTION_ID = "${AZURE_SUBSCRIPTION_ID_FOUNDATION}"
    TF_API_TOKEN          = "${TF_API_TOKEN_FOUNDATION}"
    AAD_CLIENT_ID         = "${AAD_CLIENT_ID_FOUNDATION}"
    AAD_CLIENT_SECRET     = "${AAD_CLIENT_SECRET_FOUNDATION}"
    AZURE_CREDENTIALS     = <<EOT
${AZURE_CREDENTIALS_FOUNDATION}
EOT
  }

  "${INFRA_REPO}" = {
    GH_TOKEN              = "${GHE_INFRA_TOKEN}"
    AZURE_SUBSCRIPTION_ID = "${AZURE_SUBSCRIPTION_ID_INFRA}"
    TF_API_TOKEN          = "${TF_API_TOKEN_INFRA}"
    AAD_CLIENT_ID         = "${AAD_CLIENT_ID_INFRA}"
    AAD_CLIENT_SECRET     = "${AAD_CLIENT_SECRET_INFRA}"
    AZURE_CREDENTIALS     = <<EOT
${AZURE_CREDENTIALS_INFRA}
EOT
  }

  "${APP_REPO}" = {
    GH_TOKEN              = "${GHE_APP_TOKEN}"
    AZURE_SUBSCRIPTION_ID = "${AZURE_SUBSCRIPTION_ID_APP}"
    TF_API_TOKEN          = "${TF_API_TOKEN_APP}"
    AAD_CLIENT_ID         = "${AAD_CLIENT_ID_APP}"
    AAD_CLIENT_SECRET     = "${AAD_CLIENT_SECRET_APP}"
    AZURE_CREDENTIALS     = <<EOT
${AZURE_CREDENTIALS_APP}
EOT
  }
}

# ————————————————————————————
# Collaborators (optional placeholders)
# ————————————————————————————
repo_user_collaborators = {
  # "REPO_NAME" = [
  #   { username = "${USER1}", permission = "${PERMISSION1}" },
  # ]
}

repo_team_collaborators = {
  # "REPO_NAME" = [
  #   { team_slug = "${TEAM1}", permission = "${PERMISSION1}" },
  # ]
}

# ————————————————————————————
# Terraform Cloud settings
# ————————————————————————————
tfc_organization = "${TFC_ORGANIZATION}"
tfe_token        = "${TFE_TOKEN}"

# ————————————————————————————
# Projects & workspaces (injected as a block)
# ————————————————————————————
projects = ${PROJECTS_BLOCK}

# ————————————————————————————
# Azure AD & other identifiers
# ————————————————————————————
existing_aad_app_display_name = "${EXISTING_AAD_APP_DISPLAY_NAME}"
application_object_id         = "${APPLICATION_OBJECT_ID}"
principal_id                  = "${PRINCIPAL_ID}"
tenant_id                     = "${TENANT_ID}"

# ————————————————————————————
# GitHub Projects and SP creds
# ————————————————————————————
ghreposproject  = "${GHREPOSPROJECT}"
subscription_id = "${SUBSCRIPTION_ID}"
client_id       = "${CLIENT_ID}"
client_secret   = "${CLIENT_SECRET}"
