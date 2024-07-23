#!/bin/sh

# Update package list and upgrade installed packages
echo "Updating package list..."
sudo apt-get update

echo "Upgrading installed packages..."
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    curl \
    tar \
    make \
    tree \
    wget \
    gcc \
    python3.12 \
    python3-pip \
    python3.12-venv \
    build-essential \
    git \
    vim \
    unzip

# Install Python requirements
echo "Installing required packages..."
sudo pip3 install requests bs4 --break-system-packages

# Call the Python script
echo "Running the Python script..."
python3.12 oss_cad_suite_setup.py

echo "Setup complete!"
