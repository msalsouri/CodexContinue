#!/bin/bash

# Script to verify GPU access in the ML service container

set -e

echo "======================================================"
echo "      Verifying GPU Support in ML Service         "
echo "======================================================"

# Check if the ML service container is running
if ! docker-compose ps | grep -q ml-service; then
    echo "Error: ML service container is not running."
    echo "Please run ./scripts/start-ml-service-gpu.sh first."
    exit 1
fi

# Check GPU in ML service container
echo "Checking GPU in ML service container:"
docker-compose exec ml-service nvidia-smi || {
    echo "ERROR: GPU not detected in ML service container!"
    exit 1
}

# Try running a simple PyTorch GPU check
echo -e "\nRunning PyTorch GPU check in ML service container:"
docker-compose exec ml-service python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count()); print('CUDA device name:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')" || {
    echo "ERROR: PyTorch GPU check failed!"
    exit 1
}

echo -e "\n✅ GPU verification complete! The ML service has GPU access."
