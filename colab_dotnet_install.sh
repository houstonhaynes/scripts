#!/usr/bin/env bash
set -e

echo "Installing .NET SDK and dotnet-interactive..."

# Give more time for the system to settle and clear memory cache
sync
echo 3 > /proc/sys/vm/drop_caches
sleep 15

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

# Update package list and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install .NET SDK
apt-get install -y dotnet-sdk-9.0

# Export required environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:~/.dotnet/tools
export DOTNET_NOLOGO=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Verify SDK installation with minimal command
echo "Verifying .NET SDK installation..."
if ! $DOTNET_ROOT/dotnet --list-runtimes; then
    echo "Error: .NET SDK verification failed"
    exit 1
fi

# Rest of script remains the same...