#!/bin/bash
set -e  # Exit on error

REPO_URL="https://github.com/langgenius/dify.git"
REPO_DIR="./repo"
TARGET_DIR="./code"

echo "Starting update process..."

# Function to clean up in case of errors
cleanup() {
    if [ -d "$REPO_DIR" ]; then
        echo "Cleaning up temporary repository..."
        rm -rf "$REPO_DIR"
    fi
}

# Set up error trap
trap cleanup ERR

# Create or update the temporary repo
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning fresh repository..."
    git clone --depth 1 --branch main --single-branch "$REPO_URL" "$REPO_DIR"
else
    echo "Updating existing repository..."
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard origin/main
    cd ..
fi

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Backup existing code directory
if [ -d "$TARGET_DIR" ]; then
    BACKUP_DIR="${TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup of existing code at $BACKUP_DIR"
    cp -r "$TARGET_DIR" "$BACKUP_DIR"
fi

# Copy new files
echo "Copying new files from docker directory..."
rm -rf "$TARGET_DIR"/*
cp -r "$REPO_DIR/docker/." "$TARGET_DIR"

echo "Update completed successfully!"
