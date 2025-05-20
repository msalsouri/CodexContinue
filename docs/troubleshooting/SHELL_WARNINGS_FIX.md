# Shell Warnings Troubleshooting Guide

This document provides solutions for common shell warnings that may appear in the top-left corner of your terminal when working with CodexContinue in WSL.

## Quick Fix Script

For convenience, we've provided a script that can automatically check for and fix common shell warnings:

```bash
./scripts/check-shell-warnings.sh
```

This script will:
- Check for duplicate NVM entries in `.bashrc`
- Fix broken Docker feedback plugin symlinks
- Verify NVIDIA driver status
- Check Ollama port usage
- Provide a summary of findings

## Common Issues and Solutions

### 1. Docker Feedback Plugin Warning

**Symptom:**
```
WARNING: Plugin "/usr/local/lib/docker/cli-plugins/docker-feedback" is not valid: failed to fetch metadata
```

**Solution:**
```bash
# Remove the broken symlink
sudo rm -f /usr/local/lib/docker/cli-plugins/docker-feedback
```

**Explanation:**
Docker Desktop creates symlinks to CLI plugins, but sometimes the feedback plugin target doesn't exist, causing this warning.

### 2. Duplicate NVM Entries in .bashrc

**Symptom:**
Potential shell initialization slowdowns or warnings due to duplicate NVM environment setup.

**Solution:**
Edit your `~/.bashrc` file and remove any duplicate NVM initialization blocks:

```bash
# Keep only one of these blocks:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

### 3. Docker Container Throttle Warnings

**Symptom:**
```
WARNING: No blkio throttle.read_bps_device support
WARNING: No blkio throttle.write_bps_device support
```

**Explanation:**
These are informational warnings from Docker about missing kernel features for I/O throttling in WSL. They don't affect functionality and can be safely ignored.

### 4. NVIDIA Container Toolkit Warnings

**Symptom:**
Various warnings related to NVIDIA drivers or containers.

**Solution:**
Run our verification and fix scripts:

```bash
cd ~/Projects/CodexContinue
./scripts/verify-nvidia-wsl.sh
sudo ./scripts/fix-nvidia-wsl-libs.sh
```

## General Troubleshooting Steps

If you encounter other shell warnings:

1. **Check shell startup files** for errors:
   ```bash
   bash -x -c "echo Test" 2>&1 | grep -E "warning|error"
   ```

2. **Check Docker status**:
   ```bash
   docker info
   ```

3. **Verify NVIDIA driver status**:
   ```bash
   nvidia-smi
   ```

4. **Check for processes using specific ports**:
   ```bash
   lsof -i :11434  # For Ollama's port
   ```

## Contact

If you encounter persistent shell warnings not covered in this guide, please open an issue in the CodexContinue repository.
