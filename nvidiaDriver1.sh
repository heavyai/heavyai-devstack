# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# !/bin/bash
#  This script simply configurs Nvidia drivers in a typical Linux environment.  


install_nvidia_drivers(){

sudo apt install linux-headers-$(uname -r) 
sudo apt install pciutils 
sudo apt install libvulkan1

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-4

sudo apt-get install -y cuda-drivers

}
install_package() {
    local package_name=$1

    read -p "If you are running on A100 you should install $package_name? (y/n): " response
    if [[ $response == "y" || $response == "Y" ]]; then
        sudo apt update
        sudo apt install -y $package_name
    else
        echo "$package_name installation skipped."
    fi
}

install_nvidia_drivers
install_package "nvidia-fabricmanager-555"


