#!/usr/bin/env bash
# Comprehensive .NET 6 installation script for Google Colab
# Fixes libhostfxr.so and kernel directory issues

echo "Installing .NET 6 SDK and interactive tools..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update and install .NET SDK (with error handling)
apt-get update
apt-get install -y apt-transport-https
apt-get update
apt-get install -y dotnet-sdk-6.0

# Verify installation and get actual version
echo "Verifying .NET installation..."
DOTNET_ROOT=$(dirname $(dirname $(which dotnet)))
echo "DOTNET_ROOT: $DOTNET_ROOT"

# Find the actual FXR version
if [ -d "$DOTNET_ROOT/host/fxr" ]; then
  FXR_VERSION=$(find $DOTNET_ROOT/host/fxr -maxdepth 1 -type d | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" | sort -V | tail -n 1)
  echo "Found .NET runtime version: $FXR_VERSION"
else
  echo "Warning: Could not find fxr directory in $DOTNET_ROOT/host/"
  # Install explicit components if not found
  apt-get install -y dotnet-runtime-6.0 dotnet-hostfxr-6.0 aspnetcore-runtime-6.0
  FXR_VERSION=$(find /usr/lib/dotnet/host/fxr -maxdepth 1 -type d 2>/dev/null | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" | sort -V | tail -n 1)
  echo "Installed and found runtime version: $FXR_VERSION"
fi

# Create required directory structure
echo "Setting up directory structure..."
mkdir -p /usr/share/dotnet/host/fxr

# If we found the version, create the symlinks
if [ -n "$FXR_VERSION" ]; then
  echo "Creating symlinks for version $FXR_VERSION"
  # Remove existing symlinks if they exist to avoid errors
  if [ -L "/usr/share/dotnet/dotnet" ]; then
    rm /usr/share/dotnet/dotnet
  fi
  if [ -L "/usr/share/dotnet/host/fxr/$FXR_VERSION" ]; then
    rm /usr/share/dotnet/host/fxr/$FXR_VERSION
  fi
  
  # Create proper symlinks
  ln -sf $DOTNET_ROOT/dotnet /usr/share/dotnet/dotnet
  ln -sf $DOTNET_ROOT/host/fxr/$FXR_VERSION /usr/share/dotnet/host/fxr/$FXR_VERSION
  
  # Also create the specific version directory that's being looked for
  if [ "$FXR_VERSION" != "6.0.136" ]; then
    mkdir -p /usr/share/dotnet/host/fxr/6.0.136
    ln -sf $DOTNET_ROOT/host/fxr/$FXR_VERSION/* /usr/share/dotnet/host/fxr/6.0.136/
  fi
else
  echo "Error: Could not determine .NET runtime version"
  exit 1
fi

# Set environment variables
export DOTNET_ROOT=$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
echo "export DOTNET_ROOT=$DOTNET_ROOT" >> ~/.bashrc
echo "export PATH=\$PATH:$DOTNET_ROOT:\$HOME/.dotnet/tools" >> ~/.bashrc

# Install dotnet interactive
echo "Installing .NET Interactive..."
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307

# Create Jupyter kernel directories with correct names
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create kernel configurations
echo "Setting up Jupyter kernels..."
echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

# Try registering the kernels with Jupyter
echo "Registering kernels with Jupyter..."
~/.dotnet/tools/dotnet-interactive jupyter install

# Verify installation
echo "Verifying final installation:"
echo "dotnet version:"
dotnet --version
echo "dotnet --info:"
dotnet --info
echo "SDK versions:"
dotnet --list-sdks
echo "Runtime versions:"
dotnet --list-runtimes

echo "Done."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"