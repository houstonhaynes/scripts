#!/usr/bin/env bash
set -e

echo "Installing .NET SDK and dotnet-interactive..."

# Install required dependencies first
apt-get install -y \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    libicu70 \
    libssl3 \
    libstdc++6 \
    zlib1g \
    procps

# Clear package cache and update
rm -rf /var/lib/apt/lists/*
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET SDK
apt-get update
apt-get install -y dotnet-sdk-9.0

# Export required environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:~/.dotnet/tools
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Verify SDK installation with minimal command and better error handling
echo "Verifying .NET SDK installation..."
if ! which dotnet > /dev/null; then
    echo "Error: dotnet command not found"
    exit 1
fi

echo "Checking .NET version..."
if ! dotnet --version; then
    echo "Error: Unable to get .NET version"
    exit 1
fi