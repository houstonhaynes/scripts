#!/usr/bin/env bash
set -e

echo "Installing .NET Runtime and dotnet-interactive..."

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list and install dependencies
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https

# Install .NET Runtime
apt-get install -y dotnet-runtime-9.0 aspnetcore-runtime-9.0

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export NUGET_PACKAGES=/tmp/nuget

# Limit NuGet package cache size
export NUGET_GLOBAL_PACKAGES_FOLDER=/tmp/NuGetScratch
mkdir -p /tmp/NuGetScratch

# Install dotnet-interactive (specific older version)
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.607001

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