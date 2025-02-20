#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
# Atilim Gunes Baydin (gunes@robots.ox.ac.uk), February 2022
# Houston Haynes (h3@ad4s.co), February 2025

echo "Installing dotnet-sdk-6.0 and dotnet interactive 1.0.355307..."

# Remove any existing Microsoft repository configuration
rm -f packages-microsoft-prod.deb

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb

# Create necessary directories
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create required directories
sudo mkdir -p /usr/share/dotnet/host/fxr
sudo mkdir -p /usr/share/dotnet/sdk
sudo mkdir -p /usr/share/dotnet/shared

# Reinstall the SDK to ensure proper setup
sudo apt-get remove -y dotnet-sdk-6.0
sudo apt-get install -y dotnet-sdk-6.0

# Install dotnet interactive
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools
dotnet interactive jupyter install

# Create kernel configurations
echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

echo "Done."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"