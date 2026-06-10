#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0


# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

os_packages=("docker-compose" "awscli" "xmlstarlet")
docker_packages=("docker.io" "docker-ce")
missing_packages=()
UPDATE_DONE=0

echo -e "${BLUE}Checking for required packages...${NC}"

# Function to check if any of the docker packages are installed
check_docker_installed() {
    for package in "${docker_packages[@]}"; do
        if dpkg -l | grep -q "^ii\s\+$package\s"; then
            echo -e "Docker Package ($package):   [${GREEN}Installed${NC}]"
            return 0
        fi
    done
    echo -e "Docker Package:   [${RED}Not Installed${NC}]"
    return 1
}

# Check for docker packages
if check_docker_installed; then
    echo -e "Docker:   [${GREEN}Installed${NC}]"
else
    echo -e "Docker:   [${RED}Not Installed${NC}]"
    missing_packages+=("docker.io")  # Default to docker.io if neither is installed
fi

# Check for other required packages
for package in "${os_packages[@]}"; do
    if dpkg -l | grep -q "^ii\s\+$package\s"; then
        echo -e "$package:   [${GREEN}Installed${NC}]"
    else
        echo -e "$package:   [${RED}Not Installed${NC}]"
        missing_packages+=("$package")
    fi
done

installPackage(){
    PACKAGE_NAME=$1
    echo "Would you like to install $PACKAGE_NAME [y/n]"
    read answer

    case $answer in
        [Yy]* )
            echo "Installing $PACKAGE_NAME";
            if [ $UPDATE_DONE -eq 0 ]; then
                echo "Updating APT repository"
                sudo apt-get update
                UPDATE_DONE=1
            fi
            sudo apt-get install -y $PACKAGE_NAME
            ;;
        [Nn]* )
            echo "Skipping $PACKAGE_NAME"
            ;;
        * )
            echo "Invalid choice."
            ;;
    esac
}

for package in "${missing_packages[@]}"; do
    installPackage $package
done

# Configuring Docker
USER_NAME=$(whoami)

group_exists() {
    getent group docker > /dev/null 2>&1
}

if ! group_exists; then
    echo "The docker group does not exist. Creating docker group..."
    sudo groupadd docker
    if [ $? -eq 0 ]; then
        echo -e "Docker Group:   [${GREEN}Installed${NC}]"
    else
        echo -e "Docker Group:   [${RED}Failed${NC}]"
        exit 1
    fi
else
    echo -e "Docker Group:   [${GREEN}Installed${NC}]"
fi

if groups $USER_NAME | grep -qw docker; then
    echo -e "$USER_NAME:   [${GREEN}Installed${NC}]"
else
    echo "$USER_NAME is not in the docker group. Adding $USER_NAME to the docker group..."
    sudo usermod -aG docker $USER_NAME
    if [ $? -eq 0 ]; then
        echo -e "$USER_NAME:   [${GREEN}Installed${NC}]"
    else
        echo -e "$USER_NAME:   [${RED}Failed${NC}]"
    fi
fi

echo -e "${BLUE}Checking NVIDIA GPU ...${NC}"

if command -v nvidia-smi &> /dev/null; then
    echo -e "Nvidia Driver:   [${GREEN}Installed${NC}]"
 #   nvidia-smi
else
    echo -e "Nvidia Driver:   [${RED}Failed${NC}]"
    echo -e "Run nvidiaDriver1.sh to install Nvidia drivers"
    echo -e "IMPORTANT:  It is generally required to reboot the server after the Nvidia driver install and before installing the Nvidia Docker runtime."
fi

echo -e "${BLUE}Checking NVIDIA Docker configuration...${NC}"

if command -v nvidia-container-runtime &> /dev/null; then
    echo -e "Nvidia Docker:   [${GREEN}Installed${NC}]"
#    nvidia-container-runtime --version:q
else
    echo -e "Nvidia Docker:   [${RED}Failed${NC}]"
    echo -e "Run nvidiaRuntime2.sh to install Nvidia Docker"
fi
