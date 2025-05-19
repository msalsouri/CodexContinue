#!/bin/bash
# setup-git-remote.sh - Script to set up git remote repository

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if git is initialized
if [ ! -d ".git" ]; then
    error "Git repository not initialized. Run 'git init' first."
fi

# Instructions
echo "==============================================================="
echo "           CodexContinue Remote Repository Setup"
echo "==============================================================="
echo 
info "Use this script after you've created a remote repository on"
info "GitHub, GitLab, or another git hosting service."
echo
info "You'll need the repository URL in this format:"
info "  - HTTPS: https://github.com/username/CodexContinue.git"
info "  - SSH:   git@github.com:username/CodexContinue.git"
echo

# Get remote URL from user
read -p "Enter the remote repository URL: " REMOTE_URL

if [ -z "$REMOTE_URL" ]; then
    error "No URL provided. Exiting."
fi

# Add the remote repository
log "Adding remote repository 'origin'..."
git remote add origin "$REMOTE_URL"

if [ $? -ne 0 ]; then
    warn "Failed to add remote. If 'origin' already exists, try:"
    echo -e "  ${YELLOW}git remote set-url origin $REMOTE_URL${NC}"
    exit 1
fi

# Initial commit if needed
if ! git log -1 &> /dev/null; then
    log "Creating initial commit..."
    git commit -m "Initial commit: CodexContinue project setup"
fi

# Push to the remote repository
log "Pushing to remote repository..."
echo "git push -u origin main || git push -u origin master"

echo
log "Setup complete! You can now push your code with:"
echo -e "  ${GREEN}git push -u origin main${NC} (for main branch)"
echo -e "  ${GREEN}git push -u origin master${NC} (for master branch)"
echo
info "After pushing, you can clone this repository on your Windows system with:"
echo -e "  ${BLUE}git clone $REMOTE_URL${NC}"
echo
info "To update after making changes on either system:"
echo -e "  ${BLUE}git pull${NC} (to get changes from remote)"
echo -e "  ${BLUE}git push${NC} (to send local changes to remote)"
