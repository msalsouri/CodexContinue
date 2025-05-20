#!/bin/bash

echo "=== CodexContinue WSL NVIDIA Library Fix ==="
echo "This script sets up the NVIDIA libraries for WSL"
echo

# Create symbolic links for missing libraries
echo "Step 1: Creating symbolic links for NVIDIA libraries..."
if [ -f /usr/lib/wsl/lib/libnvidia-ml.so.1 ] && [ ! -f /usr/lib/wsl/lib/libnvidia-ml.so ]; then
    echo "Creating symbolic link for libnvidia-ml.so..."
    sudo ln -sf /usr/lib/wsl/lib/libnvidia-ml.so.1 /usr/lib/wsl/lib/libnvidia-ml.so
    echo "✅ Created symbolic link"
else
    if [ -f /usr/lib/wsl/lib/libnvidia-ml.so ]; then
        echo "✅ libnvidia-ml.so already exists"
    else
        echo "❌ libnvidia-ml.so.1 not found in /usr/lib/wsl/lib/"
    fi
fi

# Update library path
echo
echo "Step 2: Updating library path..."
LIBRARY_PATH_ENTRY="/usr/lib/wsl/lib"

# Check if the path is already in LD_LIBRARY_PATH
if [[ ":$LD_LIBRARY_PATH:" == *":$LIBRARY_PATH_ENTRY:"* ]]; then
    echo "✅ $LIBRARY_PATH_ENTRY is already in LD_LIBRARY_PATH"
else
    export LD_LIBRARY_PATH=$LIBRARY_PATH_ENTRY:$LD_LIBRARY_PATH
    echo "✅ Added $LIBRARY_PATH_ENTRY to LD_LIBRARY_PATH"
    
    # Add to bashrc if it exists
    if [ -f ~/.bashrc ]; then
        if ! grep -q "LD_LIBRARY_PATH.*$LIBRARY_PATH_ENTRY" ~/.bashrc; then
            echo "export LD_LIBRARY_PATH=$LIBRARY_PATH_ENTRY:\$LD_LIBRARY_PATH" >> ~/.bashrc
            echo "✅ Added library path to ~/.bashrc for persistence"
        else
            echo "✅ Library path already in ~/.bashrc"
        fi
    fi
    
    # Add to zshrc if it exists
    if [ -f ~/.zshrc ]; then
        if ! grep -q "LD_LIBRARY_PATH.*$LIBRARY_PATH_ENTRY" ~/.zshrc; then
            echo "export LD_LIBRARY_PATH=$LIBRARY_PATH_ENTRY:\$LD_LIBRARY_PATH" >> ~/.zshrc
            echo "✅ Added library path to ~/.zshrc for persistence"
        else
            echo "✅ Library path already in ~/.zshrc"
        fi
    fi
fi

# Add the nvidia-container runtime configuration if needed
echo
echo "Step 3: Checking NVIDIA Container Runtime configuration..."
if [ ! -f /etc/docker/daemon.json ] || ! grep -q "nvidia-container-runtime" /etc/docker/daemon.json; then
    echo "Configuring NVIDIA Container Runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker
    echo "✅ Updated Docker configuration"
else
    echo "✅ NVIDIA Container Runtime already configured"
fi

echo
echo "=== Fix Completed ==="
echo "Please verify NVIDIA support by running:"
echo "nvidia-smi"
echo
echo "If the above command works, try Docker with GPU support:"
echo "docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi"
echo
echo "You may need to restart your shell for the changes to take effect."
