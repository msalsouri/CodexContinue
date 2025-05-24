#!/bin/bash
# Cleanup script for CodexContinue docs directory
# This script removes redundant or empty documentation files
# Created: May 24, 2025

echo "Cleaning up redundant files in the docs directory..."

# Function to remove files if they exist
remove_if_exists() {
    if [ -f "$1" ]; then
        echo "Removing: $1"
        rm "$1"
    else
        echo "File not found: $1"
    fi
}

# Remove redundant YouTube transcription files now that we have
# consolidated the information in the main troubleshooting guide
remove_if_exists "/home/msalsouri/Projects/CodexContinue/docs/YOUTUBE_TRANSCRIPTION_API_FIX.md"
remove_if_exists "/home/msalsouri/Projects/CodexContinue/docs/YOUTUBE_TRANSCRIPTION_PR_TEMPLATE.md"
remove_if_exists "/home/msalsouri/Projects/CodexContinue/docs/YOUTUBE_TRANSCRIPTION_UPDATES.md"

# Remove empty files
remove_if_exists "/home/msalsouri/Projects/CodexContinue/docs/WSL_GPU_STATUS.md"

echo "Docs cleanup completed! Redundant documentation files have been removed."
