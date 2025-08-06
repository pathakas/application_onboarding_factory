#!/usr/bin/env python3
import os
import sys
import re

REQUIRED_VARS = [
    "ORGANIZATION_CODE",
    "LOB_CODE",
    "APP_CODE",
    "APP_NAME",
    "APP_PLATFORM",
    "APP_ENVT",
    "GH_TOKEN_FOUNDATION",
]

def build_context():
    """
    Build a flat context dict from environment variables and derive repo names.
    """
    ctx = {}
    # Populate from environment
    for key in REQUIRED_VARS:
        value = os.environ.get(key)
        if not value:
            sys.stderr.write(f"ERROR: Required environment variable '{key}' not set.\n")
            sys.exit(1)
        ctx[key] = value

    # Derived repo names
    base = f"{ctx['ORGANIZATION_CODE']}-{ctx['LOB_CODE']}-{ctx['APP_CODE']}-{ctx['APP_NAME']}"
    ctx['FOUNDATION_REPO'] = f"{base}-foundation-repo"
    ctx['INFRA_REPO']      = f"{base}-infra-repo"
    ctx['APP_REPO']        = f"{base}-app-repo"
    ctx['REPO_VISIBILITY'] = os.environ.get("REPO_VISIBILITY", "public")
    ctx['GITHUB_ORGANIZATION'] = os.environ.get("GITHUB_ORGANIZATION", "pathakas")

    #Derived secrets
    ctx['GITHUB_ORGANIZATION'] = os.environ.get("GITHUB_ORGANIZATION")
    ctx['AZURE_SUBSCRIPTION_ID_FOUNDATION'] = os.environ.get("AZURE_SUBSCRIPTION_ID_FOUNDATION")
    ctx['TF_API_TOKEN_FOUNDATION'] = os.environ.get("TF_API_TOKEN_FOUNDATION")
    ctx['AAD_CLIENT_ID_FOUNDATION'] = os.environ.get("AAD_CLIENT_ID_FOUNDATION")
    ctx['AAD_CLIENT_SECRET_FOUNDATION'] = os.environ.get("AAD_CLIENT_SECRET_FOUNDATION")
    ctx['AZURE_CREDENTIALS_FOUNDATION'] = os.environ.get("AZURE_CREDENTIALS_FOUNDATION")
    # Add other context/env values as needed

    # Merge in ALL environment variables (for other templated secrets)
    for k, v in os.environ.items():
        ctx[k] = v

    return ctx


def render_template(template_path, output_path, context):
    """
    Renders a .tpl file by replacing ${KEY} with context or environment variables.
    """
    if not os.path.isfile(template_path):
        sys.stderr.write(f"ERROR: template '{template_path}' not found.\n")
        sys.exit(1)

    content = open(template_path).read()

    # Replacement function
    def repl(m):
        key = m.group(1)
        return str(context.get(key, m.group(0)))

    rendered = re.sub(r"\$\{(\w+)\}", repl, content)

    try:
        with open(output_path, 'w') as f:
            f.write(rendered)
    except Exception as e:
        sys.stderr.write(f"ERROR: cannot write '{output_path}': {e}\n")
        sys.exit(1)

    print(f"Rendered '{output_path}' from '{template_path}'")


def main():
    context = build_context()
    tpl = 'terraform.tfvars.tpl'
    out = 'terraform.tfvars'
    render_template(tpl, out, context)


if __name__ == '__main__':
    main()
