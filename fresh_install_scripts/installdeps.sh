#!/bin/bash

# Script to prepare a fresh Ubuntu installation for building the Dockerfile

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting setup for TensorRT Dockerfile requirements..."

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install necessary packages
echo "Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    libboost-all-dev \
    libeigen3-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libpcl-dev \
    ninja-build \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o 
/usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] 
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee 
/etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add the current user to the Docker group to avoid using sudo with Docker
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit
echo "Installing NVIDIA Container Toolkit..."
distribution=$(lsb_release -cs)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o 
/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/ubuntu${distribution}/nvidia-container-toolkit.list | 
sed 's#deb https://#deb [arch=$(dpkg --print-architecture) 
signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee 
/etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify NVIDIA Container Toolkit installation
echo "Verifying NVIDIA Container Toolkit..."
if ! nvidia-smi > /dev/null 2>&1; then
    echo "NVIDIA drivers are not properly installed. Please install compatible drivers."
    exit 1
fi

# Print successful installation message
echo "Setup complete! Please log out and log back in to apply Docker group changes."
echo "You can verify the setup by running: nvidia-smi and docker run --rm --gpus all nvidia/cuda:11.8-base 
nvidia-smi"

