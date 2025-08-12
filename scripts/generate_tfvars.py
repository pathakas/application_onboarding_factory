name: CI

permissions:
  contents: read
  id-token: write
  pull-requests: read

on:
  workflow_dispatch:
    inputs:
      organization_code:
        description: 'Organization Code'
        required: true
        default: 'mf'
      lob_code:
        description: 'LOB Code'
        required: true
        default: 'daia'
      app_code:
        description: 'Application Code'
        required: true
        default: 'azraaa'
      application_name:
        description: 'Infra repo name'
        required: true
        default: 'sampleapp'
      application_platform:
        description: 'Application Platform'
        required: true
        default: 'reactjs'
      environments:
        description: "Environments JSON"
        required: true
        default: '[{"name":"Development","code":"dev","subscription_id":""},{"name":"QA","code":"qat","subscription_id":""}]'

env:
  TF_VERSION: "1.11.4"
  PYTHON_VERSION: "3.11"

jobs:
  terraform-validation:
    name: Terraform Validation & Security
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Cache Terraform providers
        uses: actions/cache@v4
        with:
          path: .terraform
          key: terraform-${{ runner.os }}-${{ hashFiles('**/.terraform.lock.hcl') }}
          restore-keys: |
            terraform-${{ runner.os }}-

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Validate
        run: terraform validate

      - name: Run TfSec Security Scan
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          soft_fail: true

      # Uncomment when ready to use Checkov
      # - name: Run Checkov Security Scan
      #   uses: bridgecrewio/checkov-action@v12
      #   with:
      #     directory: .
      #     framework: terraform
      #     soft_fail: true

  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    needs: terraform-validation
    outputs:
      cache-key: ${{ steps.cache.outputs.cache-hit }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Cache Terraform providers
        id: cache
        uses: actions/cache@v4
        with:
          path: .terraform
          key: terraform-${{ runner.os }}-${{ hashFiles('**/.terraform.lock.hcl') }}
          restore-keys: |
            terraform-${{ runner.os }}-

      - name: Generate terraform.tfvars
        run: python scripts/templatize.py
        env:
          ORGANIZATION_CODE: ${{ github.event.inputs.organization_code }}
          LOB_CODE: ${{ github.event.inputs.lob_code }}
          APP_CODE: ${{ github.event.inputs.app_code }}
          APP_NAME: ${{ github.event.inputs.application_name }}
          APP_PLATFORM: ${{ github.event.inputs.application_platform }}
          APP_ENVT: ${{ github.event.inputs.environments }}
          # Foundation secrets
          GH_TOKEN_FOUNDATION: ${{ secrets.GH_TOKEN_FOUNDATION }}
          AZURE_SUBSCRIPTION_ID_FOUNDATION: ${{ secrets.AZURE_SUBSCRIPTION_ID_FOUNDATION }}
          TF_API_TOKEN_FOUNDATION: ${{ secrets.TF_API_TOKEN_FOUNDATION }}
          AAD_CLIENT_ID_FOUNDATION: ${{ secrets.AAD_CLIENT_ID_FOUNDATION }}
          AAD_CLIENT_SECRET_FOUNDATION: ${{ secrets.AAD_CLIENT_SECRET_FOUNDATION }}
          AZURE_CREDENTIALS_FOUNDATION: ${{ secrets.AZURE_CREDENTIALS_FOUNDATION }}
          # Infra secrets
          GH_TOKEN_INFRA: ${{ secrets.GH_TOKEN_INFRA }}
          AZURE_SUBSCRIPTION_ID_INFRA: ${{ secrets.AZURE_SUBSCRIPTION_ID_INFRA }}
          TF_API_TOKEN_INFRA: ${{ secrets.TF_API_TOKEN_INFRA }}
          AAD_CLIENT_ID_INFRA: ${{ secrets.AAD_CLIENT_ID_INFRA }}
          AAD_CLIENT_SECRET_INFRA: ${{ secrets.AAD_CLIENT_SECRET_INFRA }}
          AZURE_CREDENTIALS_INFRA: ${{ secrets.AZURE_CREDENTIALS_INFRA }}
          # App secrets
          GH_TOKEN_APP: ${{ secrets.GH_TOKEN_APP }}
          AZURE_SUBSCRIPTION_ID_APP: ${{ secrets.AZURE_SUBSCRIPTION_ID_APP }}
          TF_API_TOKEN_APP: ${{ secrets.TF_API_TOKEN_APP }}
          AAD_CLIENT_ID_APP: ${{ secrets.AAD_CLIENT_ID_APP }}
          AAD_CLIENT_SECRET_APP: ${{ secrets.AAD_CLIENT_SECRET_APP }}
          AZURE_CREDENTIALS_APP: ${{ secrets.AZURE_CREDENTIALS_APP }}

      - name: Terraform Init
        if: steps.cache.outputs.cache-hit != 'true'
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        env:
          TF_VAR_github_token: ${{ secrets.GH_TOKEN }}
          TF_VAR_tfe_token: ${{ secrets.TF_API_TOKEN }}

      - name: Upload Terraform Plan
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: |
            tfplan
            terraform.tfvars
          retention-days: 5

      - name: Upload Plan JSON for Security Scans
        run: |
          terraform show -json tfplan > tfplan.json
          
      - name: Upload Plan JSON
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan-json
          path: tfplan.json
          retention-days: 5

  security-scans:
    name: Security Scans
    runs-on: ubuntu-latest
    needs: terraform-plan
    strategy:
      matrix:
        scanner: [checkov, compliance]
      fail-fast: false
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download Plan JSON
        uses: actions/download-artifact@v4
        with:
          name: terraform-plan-json

      - name: Run Checkov Scan
        if: matrix.scanner == 'checkov'
        run: |
          pip install checkov
          # checkov -f tfplan.json --soft-fail
          echo "Checkov scan completed (currently disabled)"

      - name: Run Terraform Compliance
        if: matrix.scanner == 'compliance'
        run: |
          pip install terraform-compliance
          # terraform-compliance -p tfplan.json -f features/
          echo "Terraform compliance check completed (currently disabled)"

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: [terraform-plan, security-scans]
    outputs:
      repos: ${{ steps.capture-repos.outputs.repos }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Download Terraform Plan
        uses: actions/download-artifact@v4
        with:
          name: terraform-plan

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        env:
          TF_VAR_github_token: ${{ secrets.GH_TOKEN }}
          TF_VAR_tfe_token: ${{ secrets.TF_API_TOKEN }}

      - name: Capture Repository Names
        id: capture-repos
        run: |
          repos=$(terraform output -json repository_names 2>/dev/null || echo '[]')
          if [ "$repos" = "null" ] || [ -z "$repos" ]; then
            repos='[]'
          fi
          echo "repos=$repos" >> "$GITHUB_OUTPUT"
          echo "Captured repositories: $repos"

  repository-operations:
    name: Repository Operations
    runs-on: ubuntu-latest
    needs: terraform-apply
    if: ${{ needs.terraform-apply.outputs.repos != '[]' && needs.terraform-apply.outputs.repos != 'null' }}
    strategy:
      fail-fast: false
      max-parallel: 5
      matrix:
        repo: ${{ fromJSON(needs.terraform-apply.outputs.repos) }}
    steps:
      - name: Checkout Factory Repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GH_TOKEN }}
          path: factory

      - name: Checkout Target Repository
        uses: actions/checkout@v4
        with:
          repository: ${{ github.repository_owner }}/${{ matrix.repo }}
          token: ${{ secrets.GH_TOKEN }}
          path: target
          fetch-depth: 1

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Generate Repository Infrastructure Files
        run: python3 factory/scripts/generate_tfvars.py target
        env:
          REPO_NAME: ${{ github.repository_owner }}/${{ matrix.repo }}
          APP_ENVT: ${{ github.event.inputs.environments }}
          ORGANIZATION_CODE: ${{ github.event.inputs.organization_code }}
          LOB_CODE: ${{ github.event.inputs.lob_code }}
          APP_CODE: ${{ github.event.inputs.app_code }}
          APP_NAME: ${{ github.event.inputs.application_name }}
          APP_PLATFORM: ${{ github.event.inputs.application_platform }}
          # Additional computed variables
          CURRENT_TIMESTAMP: ${{ github.run_number }}
          WORKFLOW_RUN_ID: ${{ github.run_id }}

      - name: Verify Generated Files
        run: |
          echo "Generated files in target repository:"
          find target/ -name "*.tf" -o -name "*.tfvars" | head -20
          echo ""
          echo "Directory structure:"
          tree target/ -I '.git' || ls -la target/
          echo ""
          echo "Sample generated content (first .tfvars file):"
          find target/ -name "*.tfvars" | head -1 | xargs head -10 || echo "No .tfvars files found"

      - name: Commit and Push Changes  
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          repository: ./target
          commit_message: "chore: automated infrastructure files generation from factory [skip ci]"
          file_pattern: "*.tf *.tfvars *.json *.yml *.yaml"
        env:
          GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}