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

# Update package list and install dependencies
apt-get update
apt-get install -y apt-transport-https

# Install .NET packages
apt-get install -y dotnet-runtime-6.0
apt-get install -y dotnet-hostfxr-6.0
apt-get install -y dotnet-sdk-6.0

# Print debug information
echo "Checking .NET installation structure:"
ls -la /usr/share/dotnet || true
find /usr/share/dotnet -type f -name "libhostfxr.so" || true
find /usr/share/dotnet -type d || true

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Try a simpler dotnet command first
dotnet --info || true

# Rest of the script will be added once we confirm basic .NET functionality

echo "Basic installation completed. Please check the debug output above."