#!/usr/bin/env bash
set -e

echo "Installing .NET SDK and dotnet-interactive..."

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https

# Install dependencies
apt-get install -y libc6 libgcc-s1 libgssapi-krb5-2 libicu70 libssl3 libstdc++6 zlib1g

# Install .NET SDK
apt-get install -y dotnet-sdk-9.0

# Give some time for the system to settle
sleep 10

# Export required environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:~/.dotnet/tools
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Verify SDK installation with error handling
echo "Verifying .NET SDK installation..."
if ! dotnet --version; then
    echo "Error: .NET SDK verification failed"
    exit 1
fi

# Create temporary directory for first run experience
mkdir -p /tmp/dotnet-warmup
cd /tmp/dotnet-warmup
if ! dotnet new console --no-restore; then
    echo "Error: Failed to create test project"
    exit 1
fi
cd -

# Install dotnet-interactive with explicit version and error handling
echo "Installing dotnet-interactive..."
if ! dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.440003; then
    echo "Error: Failed to install dotnet-interactive"
    exit 1
fi

# List installed tools
echo "Installed tools:"
dotnet tool list -g

# Install Jupyter kernels
echo "Installing Jupyter kernels..."
if ! ~/.dotnet/tools/dotnet-interactive jupyter install; then
    echo "Error: Failed to install Jupyter kernels"
    exit 1
fi

# List kernelspecs
echo "Installed kernelspecs:"
jupyter kernelspec list

echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

echo "Done!"
echo "Please select .NET (C#) or .NET (F#) from the Runtime -> Change runtime type menu."