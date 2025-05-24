# System Check Scripts

This directory contains various scripts used to check the system configuration and environment
for CodexContinue components.

## Usage

These scripts can be used to verify that your system is properly configured for running
CodexContinue:

```bash
# Check if ffmpeg is installed and properly configured
./checks/check-ffmpeg.sh

# Check if GPU support is available for machine learning tasks
./checks/check-gpu-support.sh

# Check the overall platform compatibility
./checks/check-platform.sh
```

## Creating New Check Scripts

If you need to create new check scripts, place them in this directory following this naming convention:

- `check-<component>-<functionality>.sh` - For Bash check scripts
