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
apt-get install -y libc6 libgcc1 libgssapi-krb5-2 libicu70 libssl1.1 libstdc++6 zlib1g

# Install .NET SDK
apt-get install -y dotnet-sdk-9.0

# Install dotnet-interactive
dotnet tool install -g Microsoft.dotnet-interactive

# List installed tools
echo "Installed tools:"
dotnet tool list -g

# Install Jupyter kernels
dotnet interactive jupyter install

# List kernelspecs
echo "Installed kernelspecs:"
jupyter kernelspec list

echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

echo "Done!"
echo "Please select .NET (C#) or .NET (F#) from the Runtime -> Change runtime type menu."