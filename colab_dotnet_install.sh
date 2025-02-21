#!/usr/bin/env bash
set -e

echo "Installing .NET SDK and dotnet-interactive..."

# Install required dependencies first
apt-get install -y procps

# Set up .NET environment variables
export DOTNET_CLI_HOME=~/.dotnet
export NUGET_PACKAGES=~/.nuget/packages
mkdir -p "$DOTNET_CLI_HOME/tools"
mkdir -p "$NUGET_PACKAGES"
chmod 755 "$DOTNET_CLI_HOME"
chmod 755 "$NUGET_PACKAGES"

# Set required environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_CLI_HOME/tools

# Optional settings to improve installation experience
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1

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

# Verify SDK installation with more robust checks
echo "Verifying .NET SDK installation..."
if [ ! -f "$DOTNET_ROOT/dotnet" ]; then
    echo "Error: dotnet executable not found in $DOTNET_ROOT"
    exit 1
fi

echo "Checking .NET installation..."
SDK_VERSION=$($DOTNET_ROOT/dotnet --list-sdks 2>/dev/null | grep -m1 "9.0" || echo "")
if [ -z "$SDK_VERSION" ]; then
    echo "Error: .NET SDK 9.0 not found"
    exit 1
fi

echo "SDK Version found: $SDK_VERSION"

# Clear system and temp spaces
echo "Clearing system caches and temporary space..."
apt-get clean
find /tmp -type f ! -name 'colab_runtime.sock' -delete
find /tmp -type d -empty -delete
rm -rf /var/cache/apt/archives/*

# Install dotnet-interactive
echo "Installing dotnet-interactive..."
dotnet tool install -g Microsoft.dotnet-interactive


# Verify installation
echo "Verifying dotnet-interactive installation..."
if ! dotnet tool list -g | grep -q "microsoft.dotnet-interactive"; then
    echo "Error: dotnet-interactive not found in global tools"
    exit 1
fi

# Install Jupyter kernel
echo "Installing .NET kernel for Jupyter..."
dotnet interactive jupyter install --force

echo "Installation completed successfully!"
echo "Please select '.NET (C#)' from the Jupyter kernel list when creating a new notebook."