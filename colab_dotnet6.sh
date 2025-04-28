#!/usr/bin/env bash
# Complete .NET 6 and .NET Interactive installation for Google Colab
# This script handles a fresh installation with proper directory structure setup

echo "Starting fresh .NET 6 and .NET Interactive installation for Google Colab..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# 1. Install .NET SDK and runtime
echo "Setting up Microsoft package repository..."
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package lists
apt-get update
apt-get install -y apt-transport-https
apt-get update

# Install .NET components
echo "Installing .NET 6 SDK and runtime components..."
apt-get install -y dotnet-sdk-6.0 aspnetcore-runtime-6.0 dotnet-runtime-6.0

# 2. Ensure proper directory structure
echo "Setting up directory structure..."
mkdir -p /usr/share/dotnet/host/fxr/6.0.136

# Verify actual .NET installation paths
DOTNET_PATH=$(which dotnet)
DOTNET_ROOT=$(dirname "$DOTNET_PATH")
echo "Found dotnet at: $DOTNET_PATH"
echo "DOTNET_ROOT: $DOTNET_ROOT"

# Look for actual hostfxr library location
echo "Locating hostfxr libraries..."
FXR_SEARCH=$(find /usr -path "*/dotnet/host/fxr/*" -type d 2>/dev/null)
if [ -n "$FXR_SEARCH" ]; then
  echo "Found host/fxr directories:"
  echo "$FXR_SEARCH"
  
  # Extract version information
  INSTALLED_VERSION=$(echo "$FXR_SEARCH" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
  echo "Detected version: $INSTALLED_VERSION"
  
  # Create links from found location to expected location
  SOURCE_FXR_DIR=$(echo "$FXR_SEARCH" | head -1)
  if [ -n "$INSTALLED_VERSION" ] && [ -n "$SOURCE_FXR_DIR" ]; then
    echo "Linking from $SOURCE_FXR_DIR to /usr/share/dotnet/host/fxr/$INSTALLED_VERSION"
    # Create the target directory if it doesn't exist
    mkdir -p /usr/share/dotnet/host/fxr/$INSTALLED_VERSION
    # Link all files from source to target
    cp -r $SOURCE_FXR_DIR/* /usr/share/dotnet/host/fxr/$INSTALLED_VERSION/
    
    # Also link to the specific version mentioned in error message
    if [ "$INSTALLED_VERSION" != "6.0.136" ]; then
      echo "Creating additional link for version 6.0.136"
      rm -rf /usr/share/dotnet/host/fxr/6.0.136
      cp -r $SOURCE_FXR_DIR/* /usr/share/dotnet/host/fxr/6.0.136/
    fi
  fi
else
  echo "Could not find existing fxr directories. Searching for libhostfxr.so..."
  HOSTFXR_LIB=$(find /usr -name libhostfxr.so 2>/dev/null)
  
  if [ -n "$HOSTFXR_LIB" ]; then
    echo "Found libhostfxr.so at: $HOSTFXR_LIB"
    cp "$HOSTFXR_LIB" /usr/share/dotnet/host/fxr/6.0.136/
  else
    echo "WARNING: Could not find libhostfxr.so"
  fi
fi

# 3. Create necessary symlinks
echo "Creating symlinks..."
ln -sf $DOTNET_ROOT/dotnet /usr/local/bin/dotnet
ln -sf $DOTNET_ROOT /usr/share/dotnet

# 4. Set environment variables
echo "Setting environment variables..."
export DOTNET_ROOT=$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
echo "export DOTNET_ROOT=$DOTNET_ROOT" >> ~/.bashrc
echo "export PATH=\$PATH:$DOTNET_ROOT:\$HOME/.dotnet/tools" >> ~/.bashrc

# 5. Verify .NET installation
echo "Verifying .NET installation..."
dotnet --info
dotnet --version
dotnet --list-sdks
dotnet --list-runtimes

# 6. Install .NET Interactive
echo "Installing .NET Interactive..."
# Remove any existing installation
dotnet tool uninstall -g Microsoft.dotnet-interactive
# Install the specified version
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307

# 7. Set up Jupyter kernels
echo "Setting up Jupyter kernels..."
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create kernel configurations
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

# 8. Install Jupyter kernels
echo "Installing Jupyter kernels with dotnet-interactive..."
export PATH=$PATH:$HOME/.dotnet/tools
~/.dotnet/tools/dotnet-interactive jupyter install

# 9. Final verification
echo "Final verification of installation:"
ls -la /usr/share/dotnet/host/fxr
ls -la $HOME/.dotnet/tools
which dotnet
dotnet --version

echo "Done! .NET 6 and .NET Interactive should now be ready to use."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
echo "You may need to restart the Colab runtime for all changes to take effect."