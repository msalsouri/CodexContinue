#!/bin/bash
# Script to launch Jupyter Lab and open it in the browser

echo "=== CodexContinue Jupyter Lab Launcher ==="
echo

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Navigate to project root directory
cd "$(dirname "$0")/.." || exit

# Check if Jupyter container is running
JUPYTER_CONTAINER=$(docker ps --filter "name=codexcontinue-jupyter" --format "{{.Names}}")

if [ -z "$JUPYTER_CONTAINER" ]; then
    echo "Jupyter container is not running."
    echo "Starting Jupyter container..."
    
    # Start the Jupyter container
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d jupyter
    
    # Wait for container to start
    echo "Waiting for Jupyter container to start..."
    sleep 5
    
    JUPYTER_CONTAINER=$(docker ps --filter "name=codexcontinue-jupyter" --format "{{.Names}}")
    if [ -z "$JUPYTER_CONTAINER" ]; then
        echo "❌ Failed to start Jupyter container. Please check docker-compose logs."
        exit 1
    fi
fi

# Check if Jupyter Lab is accessible
JUPYTER_URL="http://localhost:8888"
if ! (curl -s -L "$JUPYTER_URL/lab" > /dev/null || curl -s --head "$JUPYTER_URL" | grep "405 Method Not Allowed" > /dev/null); then
    echo "❌ Cannot access Jupyter Lab at $JUPYTER_URL"
    echo "Checking container logs..."
    docker logs "$JUPYTER_CONTAINER" | tail -n 20
    echo
    echo "Try restarting the container with: docker compose restart jupyter"
    exit 1
fi

# Open Jupyter Lab in the browser
echo "✅ Jupyter Lab is running!"
echo
echo "Opening Jupyter Lab in your browser..."

# Determine the OS and open the browser accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "$JUPYTER_URL"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux with GUI
    if command -v xdg-open > /dev/null; then
        xdg-open "$JUPYTER_URL"
    else
        echo "Please open a browser and navigate to: $JUPYTER_URL"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    start "$JUPYTER_URL"
else
    echo "Please open a browser and navigate to: $JUPYTER_URL"
fi

echo
echo "Jupyter Lab URL: $JUPYTER_URL"
echo
echo "Available notebooks:"
find "$(pwd)/notebooks" -name "*.ipynb" -not -path "*/\.*" | sed 's|'$(pwd)'/notebooks/|  - |g'
echo
echo "To stop Jupyter Lab, run: docker compose stop jupyter"
