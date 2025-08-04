#!/bin/bash

set -e

REPO="$1"
ORG="$2"
PROJECT_NAME="mf-dt-azrabc-sampleapp-ghprj"

# Check gh CLI availability
if ! command -v gh &> /dev/null; then
  echo "gh CLI not found. Install it from https://cli.github.com/"
  exit 1
fi

echo "Checking if project '$PROJECT_NAME' exists under organization '$ORG'..."

# Fetch existing projects
EXISTING_PROJECTS=$(gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      projectsV2(first: 100) {
        nodes {
          title
          id
          number
        }
      }
    }
  }' -f org="$ORG")

# Extract the project ID and number if it already exists
read -r PROJECT_ID PROJECT_NUMBER <<< $(echo "$EXISTING_PROJECTS" | jq -r --arg title "$PROJECT_NAME" '
  .data.organization.projectsV2.nodes[]? 
  | select(.title == $title) 
  | "\(.id) \(.number)"')

if [ -z "$PROJECT_ID" ]; then
  echo "Project not found. Creating project '$PROJECT_NAME'..."

  # Fetch the org ID
  ORG_ID=$(gh api graphql -f query='
    query($login: String!) {
      organization(login: $login) {
        id
      }
    }' -f login="$ORG" | jq -r '.data.organization.id')

  if [ -z "$ORG_ID" ] || [ "$ORG_ID" == "null" ]; then
    echo "Failed to retrieve organization ID for '$ORG'"
    exit 1
  fi

  # Create project
  RESPONSE=$(gh api graphql -f query='
    mutation($name: String!, $ownerId: ID!) {
      createProjectV2(input: {title: $name, ownerId: $ownerId}) {
        projectV2 {
          id
          number
        }
      }
    }' -f name="$PROJECT_NAME" -f ownerId="$ORG_ID")

  PROJECT_ID=$(echo "$RESPONSE" | jq -r '.data.createProjectV2.projectV2.id')
  PROJECT_NUMBER=$(echo "$RESPONSE" | jq -r '.data.createProjectV2.projectV2.number')

  echo "Created project with ID: $PROJECT_ID and Number: $PROJECT_NUMBER"
else
  echo "Project already exists with ID: $PROJECT_ID and Number: $PROJECT_NUMBER"
fi

echo "Project URL: https://github.com/orgs/$ORG/projects/$PROJECT_NUMBER"


