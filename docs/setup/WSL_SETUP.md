# Windows WSL Setup for CodexContinue

This guide explains how to configure CodexContinue in Windows Subsystem for Linux (WSL) with GPU passthrough for optimal performance.

## Prerequisites

### WSL Setup

1. **Enable WSL 2**

   ```powershell
   # Run in PowerShell as Administrator
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **Install a Linux Distribution**
   - Open Microsoft Store
   - Search for and install Ubuntu 20.04 LTS or later
   - Launch Ubuntu and complete the initial setup

3. **Set WSL 2 as Default**

   ```powershell
   # Run in PowerShell as Administrator
   wsl --set-default-version 2
   ```

4. **Verify WSL Version**

   ```powershell
   wsl -l -v
   ```

   Ensure your distribution shows "VERSION: 2"

### GPU Passthrough Setup

NVIDIA GPU support in WSL 2 requires:

1. **Windows 11** or **Windows 10 version 21H2** or later
2. **NVIDIA GPU Driver version 470.76 or higher**
   - Download from [NVIDIA's WSL-compatible driver page](https://developer.nvidia.com/cuda/wsl)

3. **Install CUDA in WSL**

   ```bash
   # Inside your WSL Ubuntu environment
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
   sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
   wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda-repo-ubuntu2004-11-7-local_11.7.0-515.43.04-1_amd64.deb
   sudo dpkg -i cuda-repo-ubuntu2004-11-7-local_11.7.0-515.43.04-1_amd64.deb
   sudo cp /var/cuda-repo-ubuntu2004-11-7-local/cuda-*-keyring.gpg /usr/share/keyrings/
   sudo apt-get update
   sudo apt-get -y install cuda
   ```

4. **Verify GPU Access in WSL**

   ```bash
   nvidia-smi
   ```

   You should see your GPU listed with driver information.

## Docker Setup in WSL

1. **Install Docker in WSL**

   ```bash
   # Update package information
   sudo apt-get update
   
   # Install prerequisites
   sudo apt-get install -y \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
   
   # Add Docker's official GPG key
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   
   # Set up the stable repository
   echo \
     "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   
   # Install Docker Engine
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io
   
   # Add your user to the docker group
   sudo usermod -aG docker $USER
   
   # Apply the change
   newgrp docker
   ```

2. **Install Docker Compose**

   ```bash
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   
   # Verify installation
   docker-compose --version
   ```

3. **Install NVIDIA Container Toolkit**

   ```bash
   # Setup the NVIDIA Container Toolkit repository
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
   
   # Install NVIDIA Container Toolkit
   sudo apt-get update
   sudo apt-get install -y nvidia-docker2
   
   # Restart Docker
   sudo systemctl restart docker
   ```

## Setting Up CodexContinue in WSL

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/CodexContinue.git
   cd CodexContinue
   ```

2. **Start the Development Environment**

   ```bash
   # Start all services with GPU support
   docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

3. **Verify GPU Support**

   ```bash
   # Check the GPU support script
   ./scripts/check-gpu-support.sh
   ```

4. **Build the Ollama Model**

   ```bash
   # Check if the model exists
   ./scripts/check_ollama_model.sh
   
   # If needed, build the model
   docker exec codexcontinue-ml-service-1 bash -c "cd /app && ./ml/scripts/build_codexcontinue_model.sh"
   ```

## Accessing Services from Windows

WSL services can be accessed from Windows using localhost:

- Frontend: <http://localhost:8501>
- Backend API: <http://localhost:8000>
- ML Service: <http://localhost:5000>
- Jupyter Lab: <http://localhost:8888>
- Ollama API: <http://localhost:11434>

## WSL-Specific Considerations

### File Performance

For best performance:

- Keep project files in the WSL filesystem, not in Windows-mounted directories
- Clone and work with the repository directly in your WSL environment

### GPU Memory Management

WSL may not release GPU memory properly when containers are stopped. If you experience issues:

```bash
# Check for processes using GPU
nvidia-smi

# Kill any lingering processes if needed
sudo kill -9 <PID>

# Restart Docker
sudo systemctl restart docker
```

### WSL Resource Limits

You can configure WSL memory and CPU limits in a `.wslconfig` file:

1. Create/edit the file in Windows:

   ```
   C:\Users\<YourUsername>\.wslconfig
   ```

2. Add resource limits:

   ```
   [wsl2]
   memory=8GB
   processors=4
   swap=2GB
   ```

3. Restart WSL:

   ```powershell
   wsl --shutdown
   ```

## Troubleshooting WSL-Specific Issues

### Cannot Access GPU in WSL

1. Check Windows NVIDIA driver version:

   ```powershell
   # Run in PowerShell
   nvidia-smi
   ```

   Ensure it's version 470.76 or higher.

2. Make sure you're using WSL 2:

   ```powershell
   wsl -l -v
   ```

3. Update WSL kernel:

   ```powershell
   wsl --update
   ```

### Docker Doesn't Start in WSL

```bash
# Check Docker status
sudo systemctl status docker

# Try starting Docker manually
sudo systemctl start docker

# Check Docker logs for issues
sudo journalctl -u docker
```

### Performance Issues in WSL

If you experience slow performance:

1. Move the project directory to the WSL filesystem if it's on a Windows-mounted path
2. Increase memory allocation in `.wslconfig`
3. Check if other WSL instances are running and consuming resources

## Advanced: Using VS Code with WSL

For the best development experience:

1. Install the "Remote - WSL" extension in VS Code
2. Open VS Code and click on the green "><" icon in the bottom-left corner
3. Select "Remote-WSL: New Window"
4. Open your CodexContinue directory in this WSL window
5. Install the "Remote - Containers" extension in this WSL VS Code window
6. You can now work with VS Code directly in WSL

This setup gives you the best of both worlds: WSL's GPU passthrough capabilities and VS Code's development features.
