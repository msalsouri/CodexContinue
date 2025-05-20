#!/bin/bash

echo "=== CodexContinue Ollama Process Manager ==="
echo "This script handles Ollama process conflicts"
echo

function stop_ollama() {
    echo "Stopping any running Ollama processes..."
    
    # Check for standalone Ollama processes
    if pgrep -f ollama > /dev/null; then
        echo "Found standalone Ollama process, stopping it..."
        
        # Try systemctl first
        if systemctl is-active --quiet ollama; then
            sudo systemctl stop ollama
            echo "✅ Stopped Ollama systemd service"
        else
            echo "Stopping Ollama process..."
            sudo pkill -f ollama || true
            echo "✅ Stopped Ollama process"
        fi
    else
        echo "No standalone Ollama process found."
    fi
    
    # Check for Docker containers using Ollama's port
    if docker ps -q --filter publish=11434 | grep -q .; then
        echo "Found Docker container using port 11434, stopping it..."
        docker stop $(docker ps -q --filter publish=11434) || true
    else
        echo "No Docker containers using port 11434."
    fi
    
    # Check for Docker containers with Ollama in the name
    if docker ps -q --filter name=ollama | grep -q .; then
        echo "Found Ollama Docker container, stopping it..."
        docker stop $(docker ps -q --filter name=ollama) || true
    else
        echo "No Ollama-named containers running."
    fi
    
    # Final check to ensure port is free
    sleep 2 # Give system time to free resources
    if lsof -i :11434 > /dev/null 2>&1; then
        echo "⚠️ Port 11434 is still in use. Attempting force stop..."
        # Find what's using the port
        lsof -i :11434
        # Try to kill with extreme prejudice
        sudo fuser -k 11434/tcp || true
        sleep 1
    fi
    
    echo "Done stopping Ollama processes."
}

function check_port() {
    echo "Checking if port 11434 is in use..."
    if lsof -i :11434 > /dev/null 2>&1; then
        echo "⚠️ Port 11434 is still in use."
        lsof -i :11434
        return 1
    else
        echo "✅ Port 11434 is free."
        return 0
    fi
}

function start_ollama() {
    echo "Starting Ollama with GPU support..."
    
    # Always stop existing Ollama processes first
    stop_ollama
    
    # Double-check port availability
    if check_port; then
        echo "Starting Ollama using docker-compose..."
        ./scripts/start-ollama-wsl.sh
    else
        echo "ERROR: Cannot start Ollama until port 11434 is free."
        exit 1
    fi
}

function show_status() {
    echo "Checking Ollama status..."
    
    # Check if any Ollama process is running
    echo "Processes using port 11434:"
    lsof -i :11434 2>/dev/null || echo "None"
    
    echo "Docker containers:"
    docker ps --filter name=ollama 2>/dev/null || echo "None"
    
    echo "Standalone Ollama processes:"
    pgrep -fa ollama 2>/dev/null || echo "None"
}

# Check if running interactively or via command
if [[ $# -eq 0 ]]; then
    # Interactive mode
    if lsof -i :11434 > /dev/null 2>&1; then
        echo "⚠️ Found existing Ollama process running on port 11434:"
        lsof -i :11434
        
        echo
        read -p "Do you want to stop the existing Ollama process? (y/n): " stop_command
        
        if [[ "$stop_command" == "y" || "$stop_command" == "Y" ]]; then
            stop_ollama
        else
            echo "⚠️ Existing Ollama process not stopped"
            echo "Docker will fail to start Ollama due to port 11434 being in use"
            exit 1
        fi
    else
        echo "✅ No existing Ollama process found on port 11434"
    fi

    echo
    echo "=== Ready to start Ollama with GPU support ==="
    echo "You can now run:"
    echo "./scripts/start-ollama-wsl.sh"
    echo
    echo "Or use Docker Compose directly:"
    echo "docker compose -f docker-compose.yml up ollama"
else
    # Command mode
    case "$1" in
        stop)
            stop_ollama
            ;;
        start)
            start_ollama
            ;;
        check)
            check_port
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {start|stop|check|status}"
            echo "  start  - Stop any running Ollama processes and start with GPU"
            echo "  stop   - Stop all Ollama processes"
            echo "  check  - Check if port 11434 is available"
            echo "  status - Show status of all Ollama processes"
            exit 1
    esac
fi

exit 0
