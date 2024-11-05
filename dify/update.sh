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

# Function to modify docker-compose files for Easypanel compatibility
modify_for_easypanel() {
    local file="$1"
    echo "Modifying $file for Easypanel compatibility..."
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Process the file line by line
    awk '
    BEGIN { in_ports = 0; skip_line = 0; }
    {
        # Skip container_name lines
        if ($1 == "container_name:") {
            next
        }
        
        # Handle ports sections
        if ($1 == "ports:") {
            print "    # ports:"
            in_ports = 1
            next
        }
        
        # If we are in a ports section, comment out the lines
        if (in_ports && $1 ~ /^[[:space:]]*-/) {
            print "    #" $0
            next
        }
        
        # If we hit a line that is not indented more than ports, we are out of the ports section
        if (in_ports && $1 !~ /^[[:space:]]*-/) {
            in_ports = 0
        }
        
        # Print all other lines normally
        print $0
    }' "$file" > "$temp_file"
    
    # Replace original file with modified version
    mv "$temp_file" "$file"
}

# Find and modify all docker-compose files
echo "Modifying docker-compose files for Easypanel..."
find "$TARGET_DIR" -type f -name "docker-compose*.yml" -exec bash -c 'modify_for_easypanel "$0"' {} \;

echo "Update completed successfully!"
