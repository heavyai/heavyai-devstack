#!/bin/bash
# Script to configure Nvidia drivers and set up Nvidia container toolkit

nvidia_docker_toolkit() {
  # Add Nvidia GPG key for container toolkit using the recommended method
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg

  # Determine the correct distribution version for the Nvidia repository
  distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
  sudo curl -fsSL https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

  # Update package lists and install Nvidia container toolkit
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit

  # Configure Docker to use Nvidia container runtime
  sudo nvidia-ctk runtime configure --runtime=docker --set-as-default

  # Create or update Docker daemon.json
  sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
    "default-runtime": "nvidia",
    "exec-opts": ["native.cgroupdriver=cgroupfs"], 
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF'

  # Restart Docker to apply changes
  sudo systemctl restart docker

  # Test the Nvidia container toolkit with a Docker container
  sudo docker run --rm --gpus all ubuntu nvidia-smi
}

# Call the function
nvidia_docker_toolkit
