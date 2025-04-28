#!/usr/bin/env bash
# Complete .NET 9 installation for Google Colab
# This script performs a fresh installation with all necessary components

echo "Starting comprehensive .NET 9 installation for Google Colab..."

# Step 1: Install Microsoft package repository
echo "Setting up Microsoft package repository..."
# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package lists
apt-get update
apt-get install -y apt-transport-https
apt-get update

# Step 2: Install .NET 9 SDK and runtime
echo "Installing .NET 9 SDK and runtime components..."
apt-get install -y dotnet-sdk-9.0 aspnetcore-runtime-9.0 dotnet-runtime-9.0

# Step 3: Set up directory structure
echo "Setting up proper directory structure..."

# Create required directories
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App
mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App
mkdir -p /usr/share/dotnet/host/fxr

# Find installed versions
NETCORE_VERSION=$(find /usr -path "*/shared/Microsoft.NETCore.App/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
FXR_VERSION=$(find /usr -path "*/host/fxr/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)

echo "Detected .NET Core App version: $NETCORE_VERSION"
echo "Detected FXR version: $FXR_VERSION"

# If we found version info, set up the directory structure
if [ -n "$NETCORE_VERSION" ]; then
    # Find source locations
    NETCORE_SRC=$(find /usr -path "*/shared/Microsoft.NETCore.App/$NETCORE_VERSION" -type d | head -1)
    ASPNET_SRC=$(find /usr -path "*/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION" -type d | head -1)
    FXR_SRC=$(find /usr -path "*/host/fxr/$FXR_VERSION" -type d | head -1)
    SDK_SRC=$(find /usr -path "*/sdk/9.0*" -type d | head -1)
    
    echo "Found .NET Core source: $NETCORE_SRC"
    echo "Found ASP.NET Core source: $ASPNET_SRC"
    echo "Found FXR source: $FXR_SRC"
    echo "Found SDK source: $SDK_SRC"
    
    # Create target directories
    mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION
    mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION
    mkdir -p /usr/share/dotnet/host/fxr/$FXR_VERSION
    
    # Copy files instead of symlinks for better reliability
    if [ -d "$NETCORE_SRC" ]; then
        echo "Copying .NET Core App framework..."
        cp -r $NETCORE_SRC/* /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION/
    fi
    
    if [ -d "$ASPNET_SRC" ]; then
        echo "Copying ASP.NET Core App framework..."
        cp -r $ASPNET_SRC/* /usr/share/dotnet/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION/
    fi
    
    if [ -d "$FXR_SRC" ]; then
        echo "Copying host/fxr libraries..."
        cp -r $FXR_SRC/* /usr/share/dotnet/host/fxr/$FXR_VERSION/
    fi
    
    # Create specific version symlinks if needed for compatibility
    for DIR in /usr/lib/dotnet/host/fxr/*; do
        if [ -d "$DIR" ]; then
            VERSION=$(basename "$DIR")
            if [[ "$VERSION" == 9.0* ]]; then
                echo "Creating additional symlink for fxr version $VERSION..."
                mkdir -p /usr/share/dotnet/host/fxr/$VERSION
                cp -r $DIR/* /usr/share/dotnet/host/fxr/$VERSION/
            fi
        fi
    done
else
    echo "WARNING: Could not detect .NET 9 version information!"
    # Try to find any .NET 9 components
    echo "Searching for any .NET 9 components..."
    find /usr -path "*/9.0*" -type d 2>/dev/null || echo "No .NET 9 components found"
fi

# Step 4: Set up dotnet command
echo "Setting up dotnet command..."
# Find the actual dotnet executable
DOTNET_BIN=$(find /usr -name dotnet -type f -executable | head -1)
if [ -n "$DOTNET_BIN" ]; then
    echo "Found dotnet binary at: $DOTNET_BIN"
    ln -sf $DOTNET_BIN /usr/local/bin/dotnet
    DOTNET_ROOT=$(dirname "$DOTNET_BIN")
else
    echo "ERROR: Could not find dotnet binary!"
    # Default to standard location
    DOTNET_ROOT="/usr/share/dotnet"
fi

# Step 5: Set environment variables
echo "Setting up environment variables..."
export DOTNET_ROOT=$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
echo "export DOTNET_ROOT=$DOTNET_ROOT" >> ~/.bashrc
echo "export PATH=\$PATH:$DOTNET_ROOT:\$HOME/.dotnet/tools" >> ~/.bashrc

# Step 6: Verify installation
echo "Verifying .NET 9 installation..."
# Check for the dotnet command
if command -v dotnet >/dev/null 2>&1; then
    echo "dotnet command found:"
    which dotnet
    
    # Check version
    echo "Installed version:"
    dotnet --version
    
    # Check installed SDKs and runtimes
    echo "Installed SDKs:"
    dotnet --list-sdks || echo "Failed to list SDKs"
    
    echo "Installed runtimes:"
    dotnet --list-runtimes || echo "Failed to list runtimes"
else
    echo "ERROR: dotnet command not found in PATH"
fi

# Step 7: Install .NET Interactive
echo "Installing .NET Interactive..."
# Make sure PATH is correct for this session
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools

# First check for latest compatible version of .NET Interactive for .NET 9
echo "Looking for latest compatible version of .NET Interactive..."
# Try to install latest version compatible with .NET 9
dotnet tool install -g Microsoft.dotnet-interactive || {
    echo "Error installing latest .NET Interactive, trying specific version..."
    # If latest fails, try a specific version known to work with .NET 9
    # Note: You might need to update this version as .NET 9 matures
    dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.607001
}

# Step 8: Set up Jupyter kernels
echo "Setting up Jupyter kernels..."
# Create kernel directories
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create kernel configurations
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET 9 (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET 9 (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

# Register kernels with Jupyter
if [ -f "/root/.dotnet/tools/dotnet-interactive" ]; then
    echo "Registering kernels with dotnet-interactive..."
    /root/.dotnet/tools/dotnet-interactive jupyter install
else
    echo "WARNING: dotnet-interactive not found at /root/.dotnet/tools/dotnet-interactive"
    find / -name dotnet-interactive -type f 2>/dev/null
fi

# Final check
echo "Final verification of directory structure:"
echo ".NET Core App frameworks:"
ls -la /usr/share/dotnet/shared/Microsoft.NETCore.App/ 
echo "Host FXR directories:"
ls -la /usr/share/dotnet/host/fxr/

# Add diagnostic information if something went wrong
if ! dotnet --list-sdks >/dev/null 2>&1; then
    echo "===== DIAGNOSTICS ====="
    echo "Checking library dependencies:"
    ldd $(which dotnet) || echo "Failed to check dependencies"
    
    echo "Checking for missing directories:"
    for dir in "/usr/share/dotnet" "/usr/share/dotnet/shared" "/usr/share/dotnet/host"; do
        if [ ! -d "$dir" ]; then
            echo "Missing directory: $dir"
        fi
    done
fi

echo "Done! .NET 9 and .NET Interactive should now be ready to use."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
echo "** IMPORTANT: You MUST disconnect and reconnect to the runtime for all changes to take effect **"