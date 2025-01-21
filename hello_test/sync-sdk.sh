#!/bin/bash

# Paths to repositories
UPSTREAM_REPO="https://github.com/orz9/repo-test2.git"
TARGET_REPO_PATH="./repo-test1"

# Folders to monitor and sync
FOLDERS_TO_SYNC=("hello_test")  # Replace with the actual folder names

# Temporary feature branch in the target repository for syncing changes
FEATURE_BRANCH_PREFIX="feature/sync-tag-"

# Sync changes for a specific tag
function sync_changes {
    echo "Syncing changes for tag: $1"

    # Checkout the tag in a temporary directory
    TEMP_DIR=$(mktemp -d)
    git clone --branch "$1" --depth 1 "$UPSTREAM_REPO" "$TEMP_DIR"

    # Pull the latest changes in the target repo and create a feature branch
    git -C "$TARGET_REPO_PATH" checkout main
    git -C "$TARGET_REPO_PATH" pull origin main
    FEATURE_BRANCH="${FEATURE_BRANCH_PREFIX}${1}"
    git -C "$TARGET_REPO_PATH" checkout -b "$FEATURE_BRANCH"

    # Copy the specific folders from the upstream tag to the target repo
    for folder in "${FOLDERS_TO_SYNC[@]}"; do
        rsync -a --delete "$TEMP_DIR/$folder/" "$TARGET_REPO_PATH/$folder/"
    done

    # Commit changes to the feature branch
    git -C "$TARGET_REPO_PATH" add .
    git -C "$TARGET_REPO_PATH" commit -m "Sync changes from tag $1 for folders: ${FOLDERS_TO_SYNC[*]}"

    # Push the feature branch to the remote repository
    git -C "$TARGET_REPO_PATH" push origin "$FEATURE_BRANCH"

    # Clean up temporary directory
    rm -rf "$TEMP_DIR"

    echo "Changes for tag $1 have been pushed to the feature branch: $FEATURE_BRANCH"
}

# Monitor for new tags
function monitor_tags {
    echo "Checking for new tags in the upstream repository..."

    # Fetch tags from the upstream repository
    git -C "$TARGET_REPO_PATH" fetch --tags "$UPSTREAM_REPO"

    # Get the latest tag in the upstream repository
    LATEST_TAG=$(git -C "$TARGET_REPO_PATH" tag | sort -V | tail -n 1)

    # Check if the tag already exists in the target repository
    git -C "$TARGET_REPO_PATH" fetch origin
    if git -C "$TARGET_REPO_PATH" ls-remote --tags origin | grep -q "refs/tags/$LATEST_TAG"; then
        echo "No new tags detected."
    else
        echo "New tag detected: $LATEST_TAG"
        sync_changes "$LATEST_TAG"
    fi
}

# Run the tag monitoring function
monitor_tags
