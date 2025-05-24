#!/bin/bash
# check-shell-warnings.sh - Diagnose and fix common shell warnings
# For CodexContinue project

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
}

section() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Make sure we're in the project root
cd "$(dirname "$0")/.."

echo "==============================================="
echo "CodexContinue Shell Warnings Checker and Fixer"
echo "==============================================="
echo "This script diagnoses and fixes common shell warnings"
echo

section "Checking Shell Environment"
log "Current shell: $SHELL"
log "Shell version: $(bash --version | head -n 1)"
log "Terminal: $TERM"

# Check for duplicate NVM entries in .bashrc
section "Checking for duplicate NVM entries in .bashrc"
if grep -c "export NVM_DIR=" ~/.bashrc | grep -q "2"; then
    warn "Found duplicate NVM entries in .bashrc"
    read -p "Fix duplicates? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create a backup
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d%H%M%S)
        log "Created backup of .bashrc"
        
        # Remove duplicates - keep only the first occurrence
        awk '!seen[/export NVM_DIR=/]++' ~/.bashrc > ~/.bashrc.tmp
        mv ~/.bashrc.tmp ~/.bashrc
        log "✅ Fixed duplicate NVM entries in .bashrc"
    fi
else
    log "✅ No duplicate NVM entries found in .bashrc"
fi

# Check for broken Docker feedback plugin
section "Checking for Docker feedback plugin issues"
if [ -L "/usr/local/lib/docker/cli-plugins/docker-feedback" ] && [ ! -e "/usr/local/lib/docker/cli-plugins/docker-feedback" ]; then
    warn "Found broken docker-feedback plugin symlink"
    read -p "Fix Docker feedback plugin issue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -f /usr/local/lib/docker/cli-plugins/docker-feedback
        log "✅ Removed broken Docker feedback plugin symlink"
    fi
else
    log "✅ No Docker feedback plugin issues found"
fi

# Check for Docker throttle warnings
section "Checking for Docker throttle warnings"
if docker info 2>&1 | grep -q "No blkio throttle"; then
    warn "Docker throttle warnings detected"
    log "These are normal in WSL and can be safely ignored"
    log "These warnings don't impact functionality"
else
    log "✅ No Docker throttle warnings detected"
fi

# Check for NVIDIA driver issues
section "Checking NVIDIA driver status"
if nvidia-smi &>/dev/null; then
    log "✅ NVIDIA drivers are working correctly"
else
    warn "NVIDIA drivers may not be properly installed or accessible"
    log "Consider running: ./scripts/verify-nvidia-wsl.sh"
    log "And if needed: sudo ./scripts/fix-nvidia-wsl-libs.sh"
fi

# Check port usage for Ollama
section "Checking Ollama port usage"
if lsof -i :11434 &>/dev/null; then
    log "Port 11434 is in use - probably by Ollama"
    log "If you need to manage Ollama processes, run: ./scripts/manage-ollama-process.sh"
else
    log "Port 11434 is free - no Ollama instance running"
fi

# Final summary
section "Summary"
echo "If you still see shell warnings, please refer to:"
echo "docs/troubleshooting/SHELL_WARNINGS_FIX.md"
echo
log "View full documentation with: cat docs/troubleshooting/SHELL_WARNINGS_FIX.md"
echo
echo "To verify all fixes take effect, you may need to restart your shell:"
echo "exec bash -l"
