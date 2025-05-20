#!/bin/bash

echo "=== CodexContinue WSL NVIDIA Driver Verification Script ==="
echo "This script helps diagnose NVIDIA driver issues in WSL for GPU acceleration"
echo

# Step 1: Check if WSL detects any NVIDIA driver
echo "Step 1: Checking for NVIDIA libraries..."
if [ -f /usr/lib/wsl/lib/libnvidia-ml.so ]; then
    echo "✅ Found NVIDIA libraries in WSL driver location"
else
    echo "❌ Missing NVIDIA libraries in standard WSL location"
    echo "  → Expected: /usr/lib/wsl/lib/libnvidia-ml.so"
fi

# Step 2: Check LD_LIBRARY_PATH
echo
echo "Step 2: Checking library paths..."
echo "Current LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# Step 3: Check nvidia-smi
echo
echo "Step 3: Testing nvidia-smi..."
if command -v nvidia-smi &> /dev/null; then
    echo "Found nvidia-smi command, trying to run it:"
    nvidia-smi
else
    echo "❌ nvidia-smi command not found"
fi

# Step 4: Find potential NVIDIA libraries
echo
echo "Step 4: Searching for NVIDIA libraries..."
echo "Looking for libnvidia-ml.so..."
find /usr -name "libnvidia-ml.so" 2>/dev/null
find /lib -name "libnvidia-ml.so" 2>/dev/null

# Step 5: Check NVIDIA Container Toolkit configuration
echo
echo "Step 5: Checking NVIDIA Container Toolkit configuration..."
if [ -f /etc/docker/daemon.json ]; then
    echo "Docker daemon configuration:"
    cat /etc/docker/daemon.json
else
    echo "❌ Docker daemon configuration not found"
fi

# Step 6: Check Docker GPU capability
echo
echo "Step 6: Checking Docker GPU capability..."
docker info | grep -i nvidia
docker info | grep -i gpu

echo
echo "=== Verification Complete ==="
echo "For WSL GPU support, you need:"
echo "1. NVIDIA driver for WSL installed on Windows (not in WSL)"
echo "2. Windows system restarted after driver installation"
echo "3. NVIDIA Container Toolkit installed and configured in WSL"
echo
echo "If problems persist, consider running the CPU-only configuration:"
echo "docker compose -f docker-compose.yml -f docker-compose.macos.yml up"
