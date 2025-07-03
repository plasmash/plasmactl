#!/bin/bash

# Define an array of GitHub repositories
repos=(
    "launchrctl/launchr"
    "launchrctl/compose"
    "launchrctl/keyring"
    "launchrctl/scaffold"
    "launchrctl/update"
    "launchrctl/web"
    "skilld-labs/plasmactl-bump"
    "skilld-labs/plasmactl-meta"
    "skilld-labs/plasmactl-release"
)
#   Not used anymore:
#   "skilld-labs/plasmactl-package"
#   "skilld-labs/plasmactl-publish"

# Sort the array alphabetically
IFS=$'\n' sorted_repos=($(sort <<<"${repos[*]}"))
unset IFS

# Create associative arrays to store remote tags, local tags, and commit hashes
declare -A remote_tags
declare -A local_tags
declare -A latest_release_commits
declare -A main_branch_commits

# Global variable to hold the rate limit reset timestamp
RATE_LIMIT_RESET=""

# Function to fetch the latest tag from GitHub API
fetch_latest_tag() {
    local repo=$1
    # Use -i to include headers in the response
    response=$(curl --silent -i "https://api.github.com/repos/$repo/releases/latest")
    
    # Capture the rate limit reset header (only once)
    if [[ -z "$RATE_LIMIT_RESET" ]]; then
        RATE_LIMIT_RESET=$(echo "$response" | grep -Fi x-ratelimit-reset | awk -F': ' '{print $2}' | tr -d '\r')
    fi
    
    # Remove headers from the response to extract the JSON body
    body=$(echo "$response" | sed -e '1,/^\r*$/d')
    
    # Check if the API rate limit has been exceeded
    if echo "$body" | grep -q "API rate limit exceeded"; then
        echo "Error: GitHub API rate limit exceeded. Consider authenticating or waiting before retrying."
        exit 1
    fi
    
    # Extract and return the tag name
    echo "$body" | jq --raw-output .tag_name
}

# Function to fetch the commit hash of a specific tag
fetch_commit_hash_for_tag() {
    local repo=$1
    local tag=$2
    response=$(curl --silent "https://api.github.com/repos/$repo/git/refs/tags/$tag")
    echo "$response" | jq --raw-output .object.sha
}

# Function to fetch the latest commit hash from the main branch
fetch_main_branch_commit() {
    local repo=$1
    response=$(curl --silent "https://api.github.com/repos/$repo/commits/main")
    echo "$response" | jq --raw-output .sha
}

# Fetch the latest tag and commit hashes from GitHub for each repository
echo "Fetching latest remote tags and commit hashes..."
for repo in "${sorted_repos[@]}"; do
    latest_release=$(fetch_latest_tag "$repo")
    latest_release_commit=$(fetch_commit_hash_for_tag "$repo" "$latest_release")
    main_branch_commit=$(fetch_main_branch_commit "$repo")

    remote_tags["$repo"]=$latest_release
    latest_release_commits["$repo"]=$latest_release_commit
    main_branch_commits["$repo"]=$main_branch_commit
done

# Extract local tags from the plugins.mk file
PLUGINS_FILE="$HOME/Sources/pla-plasmactl/plugins.mk"
echo "Extracting local tags from ${PLUGINS_FILE}..."
while read -r line; do
    # Skip empty lines and lines that don't contain @
    [[ -z "$line" || "$line" != *"@"* ]] && continue

    # Remove backslashes and trim spaces
    line=$(echo "$line" | sed 's/\\//g' | xargs)

    # Remove any version subdirectory (like /v2) before the @ symbol for comparison
    repo=$(echo "$line" | sed -E 's|/v[0-9]+||g' | sed 's|@| |g' | awk '{print $1}')
    tag=$(echo "$line" | sed 's|@| |g' | awk '{print $2}')
    local_tags["$repo"]=$tag
done < "$PLUGINS_FILE"

# Display results with remote and local tags, and release status
printf "%-40s\t%-20s\t%-10s\t%-10s\t%s\n" "Repository" "Release Status" "Remote" "Local" "Makefile state"
for repo in "${sorted_repos[@]}"; do
    remote_tag=${remote_tags["$repo"]}
    local_tag=${local_tags["github.com/$repo"]}
    latest_release_commit=${latest_release_commits["$repo"]}
    main_branch_commit=${main_branch_commits["$repo"]}

    # Determine release status based on commit hash comparison
    if [[ "$latest_release_commit" == "$main_branch_commit" ]]; then
        release_status="Release OK"
    else
        release_status="Release to create"
    fi

    # If there's a mismatch between remote and local tags, indicate that the Makefile needs updating
    if [[ "$remote_tag" != "$local_tag" ]]; then
        makefile_state="Makefile to update"
    else
        makefile_state="OK"
    fi

    printf "%-40s\t%-20s\t%-10s\t%-10s\t%s\n" "github.com/$repo" "$release_status" "$remote_tag" "$local_tag" "$makefile_state"
done

echo
if [[ -n "$RATE_LIMIT_RESET" ]]; then
    echo "Rate limit reset: $(date -d @"$RATE_LIMIT_RESET")"
fi
echo

