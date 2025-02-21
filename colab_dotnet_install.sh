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
sleep 5

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

# Initialize .NET before installing tools
echo "Initializing .NET environment..."
mkdir -p /tmp/dotnet-warmup
cd /tmp/dotnet-warmup
if ! $DOTNET_ROOT/dotnet new console --no-restore > /dev/null 2>&1; then
    echo "Warning: Initial .NET warmup failed, continuing anyway..."
fi
cd - > /dev/null

# Install dotnet-interactive with newer version
echo "Installing dotnet-interactive..."
DOTNET_INTERACTIVE_VERSION="1.0.611002"  # Latest version compatible with .NET 9

# Create tools directory if it doesn't exist
mkdir -p ~/.dotnet/tools

# Try installation with retry logic
MAX_RETRIES=3
RETRY_COUNT=0
INSTALL_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$INSTALL_SUCCESS" = false ]; do
    echo "Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES to install dotnet-interactive..."
    sleep 5  # Wait between attempts
    
    if $DOTNET_ROOT/dotnet tool install -g Microsoft.dotnet-interactive --version $DOTNET_INTERACTIVE_VERSION > /dev/null 2>&1; then
        INSTALL_SUCCESS=true
        break
    fi
    
    if $DOTNET_ROOT/dotnet tool update -g Microsoft.dotnet-interactive --version $DOTNET_INTERACTIVE_VERSION > /dev/null 2>&1; then
        INSTALL_SUCCESS=true
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$INSTALL_SUCCESS" = false ]; then
    echo "Error: Failed to install dotnet-interactive after $MAX_RETRIES attempts"
    exit 1
fi

# Verify installation
echo "Verifying dotnet-interactive installation..."
if ! $DOTNET_ROOT/dotnet tool list -g | grep -q "microsoft.dotnet-interactive"; then
    echo "Error: dotnet-interactive not found in global tools"
    exit 1
fi

# Install Jupyter kernel
echo "Installing .NET kernel for Jupyter..."
if ! $DOTNET_ROOT/dotnet interactive jupyter install --force; then
    echo "Error: Failed to install Jupyter kernel"
    exit 1
fi

echo "Installation completed successfully!"
echo "Please select '.NET (C#)' from the Jupyter kernel list when creating a new notebook."