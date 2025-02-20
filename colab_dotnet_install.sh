#!/usr/bin/env bash
set -ex  # Exit on error and print each command

echo "Installing dotnet-sdk-6.0 and dotnet interactive..."

# Clean up any previous installation
rm -rf /usr/share/dotnet
rm -rf /usr/lib/dotnet
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

# Install packages in correct order
apt-get install -y dotnet-runtime-6.0
apt-get install -y aspnetcore-runtime-6.0
apt-get install -y dotnet-host
apt-get install -y dotnet-hostfxr-6.0
apt-get install -y dotnet-sdk-6.0

# Create directory structure (using the correct version from the package)
mkdir -p /usr/share/dotnet/host/fxr/6.0.36

# Create symlinks with correct version
if [ -f "/usr/lib/dotnet/host/fxr/6.0.36/libhostfxr.so" ]; then
    ln -sf /usr/lib/dotnet/host/fxr/6.0.36/libhostfxr.so /usr/share/dotnet/host/fxr/6.0.36/
fi

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Force ldconfig to update library cache
ldconfig

# Debug information
echo "Debug information:"
ls -la /usr/share/dotnet/host/fxr/6.0.36/ || true
ls -la /usr/lib/dotnet/host/fxr/6.0.36/ || true
find /usr -name "libhostfxr.so" || true
ldd /usr/share/dotnet/dotnet || true

# Final test
dotnet --version

echo "Installation completed. Please check the debug output above."