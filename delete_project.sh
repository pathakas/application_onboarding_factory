#!/bin/bash

set -e

ORG="$1"
PROJECT_TITLE="$2"

if [[ -z "$ORG" || -z "$PROJECT_TITLE" ]]; then
  echo "Usage: $0 <org> <project-title>"
  exit 1
fi

# Get the project ID
PROJECT_ID=$(gh api graphql -f query='
  query($org: String!) {
    organization(login: $org) {
      projectsV2(first: 100) {
        nodes {
          id
          title
        }
      }
    }
  }' -f org="$ORG" | jq -r --arg title "$PROJECT_TITLE" '
    .data.organization.projectsV2.nodes[] | select(.title == $title) | .id')

if [[ -z "$PROJECT_ID" ]]; then
  echo "Project '$PROJECT_TITLE' not found in org '$ORG'"
  exit 1
fi

echo "Deleting project '$PROJECT_TITLE' with ID: $PROJECT_ID"

# Perform the delete mutation
gh api graphql -f query='
  mutation($id: ID!) {
    deleteProjectV2(input: { projectId: $id }) {
      clientMutationId
    }
  }' -f id="$PROJECT_ID"

echo "Project deleted."
