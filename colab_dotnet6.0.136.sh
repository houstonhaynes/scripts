#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Installing dotnet-sdk-6.0 and dotnet interactive 1.0.355307..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb

# Update and install .NET SDK
apt-get update
apt-get install -y dotnet-host dotnet-hostfxr-6.0 dotnet-runtime-6.0 aspnetcore-runtime-6.0
apt-get install -y dotnet-sdk-6.0

# Create version directory structure and copy necessary files
mkdir -p /usr/share/dotnet/host/fxr/6.0.428
cp -r /usr/lib/dotnet/host/fxr/6.0.36/* /usr/share/dotnet/host/fxr/6.0.428/

# Set up symlinks (only if they don't exist)
[ ! -e /usr/share/dotnet/dotnet ] && ln -s /usr/lib/dotnet/dotnet /usr/share/dotnet/dotnet

# Create directories for kernels
mkdir -p /root/.local/share/jupyter/kernels/{fsharp,csharp}

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