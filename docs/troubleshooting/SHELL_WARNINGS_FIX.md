# Shell Warnings Troubleshooting Guide

This document provides solutions for common shell warnings that may appear in the top-left corner of your terminal when working with CodexContinue in WSL.

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

## Automatic Diagnosis and Fixes

We've provided a script that can automatically detect and fix these issues:

```bash
cd ~/Projects/CodexContinue
./scripts/check-shell-warnings.sh
```

The script will:
1. Check for duplicate NVM entries in .bashrc
2. Check for broken Docker feedback plugin symlinks
3. Identify Docker throttle warnings and explain them
4. Check NVIDIA driver status
5. Offer to fix identified issues

## Verifying Fixes

To verify that the fixes have taken effect, restart your shell:

```bash
exec bash -l
```

Then run a Docker command and check for warnings:

```bash
docker info | grep -i warning
```

The Docker feedback plugin warning should be gone. The throttle warnings are normal in WSL and can be safely ignored.

## Contact

If you encounter persistent shell warnings not covered in this guide, please open an issue in the CodexContinue repository.
