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

# Allow system to settle
sleep 10

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

# Install dotnet-interactive
echo "Installing dotnet-interactive..."
DOTNET_INTERACTIVE_VERSION="1.0.522904"  # Version compatible with .NET 9

# Create tools directory if it doesn't exist
mkdir -p ~/.dotnet/tools

# Install dotnet-interactive with specific version
if ! $DOTNET_ROOT/dotnet tool install -g Microsoft.dotnet-interactive --version $DOTNET_INTERACTIVE_VERSION; then
    echo "First install attempt failed, trying to update if already installed..."
    if ! $DOTNET_ROOT/dotnet tool update -g Microsoft.dotnet-interactive --version $DOTNET_INTERACTIVE_VERSION; then
        echo "Error: Failed to install/update dotnet-interactive"
        exit 1
    fi
fi

# Verify dotnet-interactive installation
echo "Verifying dotnet-interactive installation..."
if ! $DOTNET_ROOT/dotnet interactive --version; then
    echo "Error: dotnet-interactive verification failed"
    exit 1
fi

# Install Jupyter kernel
echo "Installing .NET kernel for Jupyter..."
if ! $DOTNET_ROOT/dotnet interactive jupyter install; then
    echo "Error: Failed to install Jupyter kernel"
    exit 1
fi

echo "Installation completed successfully!"
echo "Please select '.NET (C#)' from the Jupyter kernel list when creating a new notebook."