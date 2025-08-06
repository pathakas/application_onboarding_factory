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
    GH_TOKEN              = "${GH_TOKEN_FOUNDATION}"
    AZURE_SUBSCRIPTION_ID = "${AZURE_SUBSCRIPTION_ID_FOUNDATION}"
    TF_API_TOKEN          = "${TF_API_TOKEN_FOUNDATION}"
    AAD_CLIENT_ID         = "${AAD_CLIENT_ID_FOUNDATION}"
    AAD_CLIENT_SECRET     = "${AAD_CLIENT_SECRET_FOUNDATION}"
    AZURE_CREDENTIALS     = <<EOT
${AZURE_CREDENTIALS_FOUNDATION}
EOT
  }

  "${INFRA_REPO}" = {
    GH_TOKEN              = "<secret>"
    AZURE_SUBSCRIPTION_ID = "<secret>"
    TF_API_TOKEN          = "<secret>"
    AAD_CLIENT_ID         = "<secret>"
    AAD_CLIENT_SECRET     = "<secret>"
    AZURE_CREDENTIALS     = <<EOT
{
  "clientId": "<secret>",
  "clientSecret": "<secret>",
  "subscriptionId": "<secret>",
  "tenantId": "<secret>"
}
EOT
  }

  "${APP_REPO}" = {
    GH_TOKEN              = "<secret>"
    AZURE_SUBSCRIPTION_ID = "<secret>"
    TF_API_TOKEN          = "<secret>"
    AAD_CLIENT_ID         = "<secret>"
    AAD_CLIENT_SECRET     = "<secret>"
    AZURE_CREDENTIALS     = <<EOT
{
  "clientId": "<secret>",
  "clientSecret": "<secret>",
  "subscriptionId": "<secret>",
  "tenantId": "<secret>"
}
EOT
  }
}

# ————————————————————————————
# Collaborators (optional placeholders)
# ————————————————————————————
repo_user_collaborators = {
   "${FOUNDATION_REPO}" = []
   "${INFRA_REPO}" = []
   "${APP_REPO}" = []
}

repo_team_collaborators = {
"${FOUNDATION_REPO}" = [

    ],
    "${INFRA_REPO}" = [

    ],
    "${APP_REPO}" = [

    ],    
}

# ————————————————————————————
# Terraform Cloud settings
# ————————————————————————————
tfc_organization = "example-org-feb65b"
#tfe_token        = "${TFE_TOKEN}"

# ————————————————————————————
# Projects & workspaces (injected as a block)
# ————————————————————————————

projects = {
  mf-dt-azrabc-sampleapp-tfcprj = {
    workspaces = {
      mf-dt-azrabc-sampleapp-foundation-tfcws = {
        vcs_repo = "mf-dt-azrabc-sampleapp-foundation-repo"
        tf_vars = {
          ARM_SUBSCRIPTION_ID     = "<secret>"
          ARM_CLIENT_ID           = "<secret>"
          ARM_TENANT_ID           = "<secret>"
          TFC_AZURE_PROVIDER_AUTH = "true"
          GITHUB_TOKEN            = "<secret>"
          ARM_CLIENT_SECRET       = "<secret>"
          AAD_CLIENT_ID           = "<secret>"
          AAD_CLIENT_SECRET       = "<secret>"
          TFC_AZURE_RUN_CLIENT_ID = "<secret>"
        }
      }
      mf-dt-azrabc-sampleapp-dev-tfcws = {
        vcs_repo = "mf-dt-azrabc-sampleapp-infra-repo"
        tf_vars = {
          ARM_SUBSCRIPTION_ID     = "<secret>"
          ARM_CLIENT_ID           = "<secret>"
          ARM_TENANT_ID           = "<secret>"
          TFC_AZURE_PROVIDER_AUTH = "true"
          GITHUB_TOKEN            = "<secret>"
          ARM_CLIENT_SECRET       = "<secret>"
          TFC_AZURE_RUN_CLIENT_ID = "<secret>"
        }
      }
      mf-dt-azrabc-sampleapp-qat-tfcws = {
        vcs_repo = "mf-dt-azrabc-sampleapp-infra-repo"
        tf_vars = {
          ARM_SUBSCRIPTION_ID     = "<secret>"
          ARM_CLIENT_ID           = "<secret>"
          ARM_TENANT_ID           = "<secret>"
          TFC_AZURE_PROVIDER_AUTH = "true"
          GITHUB_TOKEN            = "<secret>"
          ARM_CLIENT_SECRET       = "<secret>"
          TFC_AZURE_RUN_CLIENT_ID = "<secret>"
        }
      }
      mf-dt-azrabc-sampleapp-prd-tfcws = {
        vcs_repo = "mf-dt-azrabc-sampleapp-infra-repo"
        tf_vars = {
          ARM_SUBSCRIPTION_ID     = "<secret>"
          ARM_CLIENT_ID           = "<secret>"
          ARM_TENANT_ID           = "<secret>"
          TFC_AZURE_PROVIDER_AUTH = "true"
          GITHUB_TOKEN            = "<secret>"
          ARM_CLIENT_SECRET       = "<secret>"
          TFC_AZURE_RUN_CLIENT_ID = "<secret>"
        }
      }
      mf-dt-azrabc-sampleapp-drr-tfcws = {
        vcs_repo = "mf-dt-azrabc-sampleapp-infra-repo"
        tf_vars = {
          ARM_SUBSCRIPTION_ID     = "<secret>"
          ARM_CLIENT_ID           = "<secret>"
          ARM_TENANT_ID           = "<secret>"
          TFC_AZURE_PROVIDER_AUTH = "true"
          GITHUB_TOKEN            = "<secret>"
          ARM_CLIENT_SECRET       = "<secret>"
          TFC_AZURE_RUN_CLIENT_ID = "<secret>"
        }
      }
    }
  }
}
existing_aad_app_display_name = "Terraform MF Core Infrastructure Prod"
application_object_id         = "<specific>"
principal_id                  = "<secret>"
tenant_id                     = "<secret>"
ghreposproject                = "mf-dt-azrabc-sampleapp-ghprj"
subscription_id               = "<secret>"
client_id                     = "<secret>"
client_secret                 = "<secret>"
