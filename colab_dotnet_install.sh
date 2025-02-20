#!/usr/bin/env bash
set -ex  # Exit on error and print each command

echo "Installing dotnet-sdk-6.0 and dotnet interactive..."

# Clean up any previous installation
rm -rf /usr/share/dotnet
rm -f /etc/apt/sources.list.d/microsoft-prod.list
rm -f /etc/apt/sources.list.d/microsoft-prod.list.save

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list
apt-get update

# Install dependencies
apt-get install -y apt-transport-https

# Install .NET Core Runtime (this will create the base directory structure)
apt-get install -y dotnet-runtime-6.0

# Create required directories
mkdir -p /usr/share/dotnet/host/fxr

# Install the host and SDK
apt-get install -y dotnet-host
apt-get install -y dotnet-hostfxr-6.0
apt-get install -y aspnetcore-runtime-6.0
apt-get install -y dotnet-sdk-6.0

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Create symlinks if needed
if [ -d "/usr/lib64/dotnet" ]; then
    ln -sf /usr/lib64/dotnet/host/fxr/* /usr/share/dotnet/host/fxr/
elif [ -d "/usr/lib/dotnet" ]; then
    ln -sf /usr/lib/dotnet/host/fxr/* /usr/share/dotnet/host/fxr/
fi

# Print directory contents for debugging
ls -la /usr/share/dotnet/host/fxr/ || true
ls -la /usr/lib/dotnet/host/fxr/ || true
ls -la /usr/lib64/dotnet/host/fxr/ || true

# Verify installation
dotnet --version || {
    echo "Failed to verify dotnet installation"
    echo "Debug information:"
    find /usr -name "libhostfxr.so" || true
    ldconfig -p | grep hostfxr || true
    exit 1
}

echo "Basic installation completed. Please check the debug output above."