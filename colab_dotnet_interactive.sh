#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Installing .NET SDK and dotnet interactive 1.0.355307..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb

# Update package list and install .NET SDK packages
apt-get update
apt-get install -y dotnet-sdk-6.0 aspnetcore-runtime-6.0 dotnet-runtime-6.0 dotnet-hostfxr-6.0
sudo mkdir -p /usr/share/dotnet/host

# Only create the symlink if it doesn't already exist
if [ ! -L "/usr/share/dotnet/host/fxr" ]; then
    echo "Creating symlink for /usr/share/dotnet/host/fxr..."
    sudo ln -s /usr/share/dotnet/shared/Microsoft.NETCore.App /usr/share/dotnet/host/fxr
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create symlink for /usr/share/dotnet/host/fxr"
        exit 1
    fi
else
    echo "Symlink /usr/share/dotnet/host/fxr already exists."
fi

# After installing .NET SDK
if [ ! -d "/usr/share/dotnet" ]; then
    echo "Error: .NET installation failed"
    exit 1
fi

# Verify the framework setup
echo "Verifying .NET setup..."
dotnet --list-runtimes
if [ $? -ne 0 ]; then
    echo "Error: .NET setup verification failed"
    exit 1
fi

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools