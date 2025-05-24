#!/bin/bash
# Cleanup script for CodexContinue project
# This script removes unnecessary files from the root directory
# Created: May 24, 2025

echo "Cleaning up unnecessary files from the CodexContinue project..."

# Function to remove files if they exist
remove_if_exists() {
    if [ -f "$1" ]; then
        echo "Removing: $1"
        rm "$1"
    else
        echo "File not found: $1"
    fi
}

# Remove log files
remove_if_exists "/home/msalsouri/Projects/CodexContinue/frontend.log"
remove_if_exists "/home/msalsouri/Projects/CodexContinue/ml_service.log"

# Remove PID files
remove_if_exists "/home/msalsouri/Projects/CodexContinue/.ml_service.pid"
remove_if_exists "/home/msalsouri/Projects/CodexContinue/.streamlit.pid"

# Remove any docker-compose override files that might exist
remove_if_exists "/home/msalsouri/Projects/CodexContinue/docker-compose.override.yml"

echo "Cleanup completed! All temporary and log files have been removed."
