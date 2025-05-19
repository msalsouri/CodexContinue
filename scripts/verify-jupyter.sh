#!/bin/bash
# Script to verify and debug Jupyter notebook configuration

echo "=== CodexContinue Jupyter Notebook Verification Tool ==="
echo

# Check if Jupyter container is running
echo "Checking Jupyter container status..."
JUPYTER_CONTAINER=$(docker ps --filter "name=codexcontinue-jupyter" --format "{{.Names}}")

if [ -z "$JUPYTER_CONTAINER" ]; then
    echo "❌ Jupyter container is not running."
    echo "Starting it now..."
    
    # Navigate to project root directory
    cd "$(dirname "$0")/.." || exit
    
    # Start the Jupyter container
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d jupyter
    
    # Wait for container to start
    echo "Waiting for Jupyter container to start..."
    sleep 5
    
    JUPYTER_CONTAINER=$(docker ps --filter "name=codexcontinue-jupyter" --format "{{.Names}}")
    if [ -z "$JUPYTER_CONTAINER" ]; then
        echo "❌ Failed to start Jupyter container. Please check docker-compose logs."
        exit 1
    else
        echo "✅ Jupyter container is now running."
    fi
else
    echo "✅ Jupyter container is running: $JUPYTER_CONTAINER"
fi

# Check Jupyter notebook server
echo
echo "Checking Jupyter notebook server..."
JUPYTER_URL="http://localhost:8888"

if curl -s -L "$JUPYTER_URL/lab" > /dev/null || curl -s --head "$JUPYTER_URL" | grep "405 Method Not Allowed" > /dev/null; then
    echo "✅ Jupyter notebook server is accessible at $JUPYTER_URL"
else
    echo "❌ Cannot access Jupyter notebook server at $JUPYTER_URL"
    echo "Checking container logs..."
    docker logs "$JUPYTER_CONTAINER" | tail -n 20
fi

# Verify notebooks directory
echo
echo "Verifying notebooks directory..."
echo "Contents of /notebooks directory in Jupyter container:"
docker exec "$JUPYTER_CONTAINER" ls -la /notebooks

# Verify Python environment and packages
echo
echo "Verifying Python environment..."
echo "Python packages installed in Jupyter container:"
docker exec "$JUPYTER_CONTAINER" pip list | grep -E "jupyter|pandas|matplotlib|numpy|scikit-learn|plotly"

# Test executing a simple Python script
echo
echo "Testing Python execution..."
TEST_RESULT=$(docker exec "$JUPYTER_CONTAINER" python -c "import numpy as np; import pandas as pd; import matplotlib.pyplot as plt; print('Imports successful'); print(f'NumPy version: {np.__version__}'); print(f'Pandas version: {pd.__version__}')")
echo "$TEST_RESULT"

echo
echo "=== Verification Complete ==="
echo "If all checks passed, you should be able to access Jupyter Lab at: http://localhost:8888"
echo "If you encounter issues, try restarting with: docker compose restart jupyter"
