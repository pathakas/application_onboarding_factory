github_token = "<secret>"

github_organization = "McCainFoods"
# template_repo       = "mf-mdm-landing-zone"
# new_repo_name       = ["mf-mdm-landing-zone1", "mf-mdm-landing-zone2"]
new_repo_name = {
  "mf-dt-azrabc-sampleapp-foundation-repo" = "mf-platform-azure-foundation-template"
  "mf-dt-azrabc-sampleapp-infra-repo"      = "mf-platform-azure-infra-template"
  "mf-dt-azrabc-sampleapp-app-repo"        = "mf-platform-azure-app-reactjs-template"
}
repo_visibility = "private"

repo_secrets = {
  "mf-dt-azrabc-sampleapp-foundation-repo" = {
    "GH_TOKEN"              = "<secret>"
    "AZURE_SUBSCRIPTION_ID" = "<secret>"
    "TF_API_TOKEN"          = "<secret>"
    "AAD_CLIENT_ID"         = "<secret>"
    "AAD_CLIENT_SECRET"     = "<secret>"
    "AZURE_CREDENTIALS"     = <<EOT
{
  "clientId": "<secret>",
  "clientSecret": "<secret>",
  "subscriptionId": "<secret>",
  "tenantId": "<secret>"
}
EOT
  }

  "mf-dt-azrabc-sampleapp-infra-repo" = {
    "GH_TOKEN"              = "<secret>"
    "AZURE_SUBSCRIPTION_ID" = "<secret>"
    "TF_API_TOKEN"          = "<secret>"
    "AZURE_CREDENTIALS"     = <<EOT
{
  "clientId": "<secret>",
  "clientSecret": "<secret>",
  "subscriptionId": "<secret>",
  "tenantId": "<secret>"
}
EOT
  }
  "mf-dt-azrabc-sampleapp-app-repo" = {
    "GH_TOKEN"              = "<secret>"
    "AZURE_SUBSCRIPTION_ID" = "<secret>"
    "TF_API_TOKEN"          = "<secret>"
    "AZURE_CREDENTIALS"     = <<EOT
{
  "clientId": "<secret>",
  "clientSecret": "<secret>",
  "subscriptionId": "<secret>",
  "tenantId": "<secret>"
}
EOT
  }
}

repo_user_collaborators = {
  #   "mf-mdm-landing-zone1" = [
  #     {
  #       username   = "raavisivaji12"
  #       permission = "admin"
  #     },
  #     {
  #       username   = "siddarth"
  #       permission = "push"
  #     }
  #   ],
  #   "mf-mdm-landing-zone2" = [
  #     {
  #       username   = "maxim"
  #       permission = "pull"
  #     }
  #   ]
}

repo_team_collaborators = {
  "mf-dt-azrabc-sampleapp-infra-repo" = [
    {
      team_slug  = "Platform-Vendor-TechM-Admin"
      permission = "admin"
    },
    {
      team_slug  = "DevOps"
      permission = "admin"
    }
  ],
  "mf-dt-azrabc-sampleapp-foundation-repo" = [
    {
      team_slug  = "Platform-Vendor-TechM-Admin"
      permission = "admin"
    },
    {
      team_slug  = "DevOps"
      permission = "admin"
    }
    # {
    #   team_slug  = "sap-platform-vendor-techm"
    #   permission = "read"
    # }
  ]
  "mf-dt-azrabc-sampleapp-app-repo" = [
    {
      team_slug  = "Platform-Vendor-TechM-Admin"
      permission = "admin"
    },
    {
      team_slug  = "DevOps"
      permission = "admin"
    }
    # {
    #   team_slug  = "sap-platform-vendor-techm"
    #   permission = "push"
    # }
  ]
}

tfc_organization = "Mccain_Foods"
tfe_token        = "<secret>"

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
