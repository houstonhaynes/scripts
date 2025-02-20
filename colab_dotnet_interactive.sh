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
apt-get install -y dotnet-sdk-6.0 aspnetcore-runtime-6.0 dotnet-runtime-6.0

# Create the shared runtime directory structures
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36
mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App/6.0.36

# Link both runtime files where the SDK expects them
echo "Linking runtime files..."
ln -sf /usr/lib/dotnet/shared/Microsoft.NETCore.App/6.0.36/* /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36/
ln -sf /usr/lib/dotnet/shared/Microsoft.AspNetCore.App/6.0.36/* /usr/share/dotnet/shared/Microsoft.AspNetCore.App/6.0.36/

# Create a symlink from 6.0.36 to 6.0.0 for AspNetCore
ln -sf /usr/share/dotnet/shared/Microsoft.AspNetCore.App/6.0.36 /usr/share/dotnet/shared/Microsoft.AspNetCore.App/6.0.0

# Verify the framework is properly linked
echo "Verifying .NET setup..."
dotnet --list-runtimes

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools

# Install dotnet interactive
echo "Installing dotnet interactive..."
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307

# Install Jupyter kernels
echo "Installing Jupyter kernels..."
dotnet interactive jupyter install

# Verify installation
echo "Verifying installation..."
dotnet tool list -g
jupyter kernelspec list

echo "Done."
echo "After running this script:"
echo "1. Select \"Runtime\" -> \"Change Runtime Type\""
echo "2. Choose \".NET (C#)\" or \".NET (F#)\" from the dropdown"
echo "3. Click \"Save\""