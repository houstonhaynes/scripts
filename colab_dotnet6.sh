#!/usr/bin/env bash
# Complete .NET 6 installation for Google Colab with framework path fixes
# This script does a complete cold-start installation with fixes for all known issues

echo "Starting comprehensive .NET 6 installation for Google Colab..."

# Step 1: Install .NET packages
echo "Installing .NET 6 SDK and dependencies..."
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

# Install .NET components
apt-get install -y dotnet-sdk-6.0 dotnet-runtime-6.0 aspnetcore-runtime-6.0

# Step 2: Fix directory structure
echo "Setting up proper directory structure..."

# Create all required directories
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App
mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App
mkdir -p /usr/share/dotnet/host/fxr

# Find installed versions
NETCORE_VERSION=$(find /usr -path "*/shared/Microsoft.NETCore.App/*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
FXR_VERSION=$(find /usr -path "*/host/fxr/*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)

echo "Detected .NET Core App version: $NETCORE_VERSION"
echo "Detected FXR version: $FXR_VERSION"

# If we found version info, set up the directory structure
if [ -n "$NETCORE_VERSION" ]; then
    # Find source locations
    NETCORE_SRC=$(find /usr -path "*/shared/Microsoft.NETCore.App/$NETCORE_VERSION" -type d | head -1)
    ASPNET_SRC=$(find /usr -path "*/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION" -type d | head -1)
    FXR_SRC=$(find /usr -path "*/host/fxr/$FXR_VERSION" -type d | head -1)
    SDK_SRC=$(find /usr -path "*/sdk/6.0.*" -type d | head -1)
    
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
    
    # If we need a specific version (6.0.36) and it's different
    if [ "$NETCORE_VERSION" != "6.0.36" ]; then
        echo "Creating additional link for version 6.0.36..."
        mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36
        if [ -d "$NETCORE_SRC" ]; then
            cp -r $NETCORE_SRC/* /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36/
        fi
    fi
    
    # Same for host/fxr
    if [ "$FXR_VERSION" != "6.0.36" ]; then
        echo "Creating additional fxr link for version 6.0.36..."
        mkdir -p /usr/share/dotnet/host/fxr/6.0.36
        if [ -d "$FXR_SRC" ]; then
            cp -r $FXR_SRC/* /usr/share/dotnet/host/fxr/6.0.36/
        fi
    fi
    
    # For the error about 6.0.136, create that structure too
    echo "Creating additional structure for version 6.0.136..."
    mkdir -p /usr/share/dotnet/host/fxr/6.0.136
    if [ -d "$FXR_SRC" ]; then
        cp -r $FXR_SRC/* /usr/share/dotnet/host/fxr/6.0.136/
    fi
else
    echo "ERROR: Could not detect .NET Core App version!"
fi

# Step 3: Set up dotnet command
echo "Setting up dotnet command..."
# Find the actual dotnet executable
DOTNET_BIN=$(find /usr -name dotnet -type f -executable | head -1)
if [ -n "$DOTNET_BIN" ]; then
    echo "Found dotnet binary at: $DOTNET_BIN"
    ln -sf $DOTNET_BIN /usr/local/bin/dotnet
else
    echo "ERROR: Could not find dotnet binary!"
fi

# Step 4: Set environment variables
echo "Setting up environment variables..."
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:/usr/share/dotnet:$HOME/.dotnet/tools
echo "export DOTNET_ROOT=/usr/share/dotnet" >> ~/.bashrc
echo "export PATH=\$PATH:/usr/share/dotnet:\$HOME/.dotnet/tools" >> ~/.bashrc

# Step 5: Verify installation
echo "Verifying .NET installation..."
# Check for the dotnet command
if command -v dotnet >/dev/null 2>&1; then
    echo "dotnet command found:"
    which dotnet
    
    # Check installed SDKs and runtimes
    echo "Installed SDKs:"
    dotnet --list-sdks || echo "Failed to list SDKs"
    
    echo "Installed runtimes:"
    dotnet --list-runtimes || echo "Failed to list runtimes"
else
    echo "ERROR: dotnet command not found in PATH"
fi

# Step 6: Install .NET Interactive
echo "Installing .NET Interactive..."
# Make sure PATH is correct for this session
export PATH=$PATH:/usr/share/dotnet:$HOME/.dotnet/tools

# Install dotnet-interactive tool
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307 || {
    echo "Error installing .NET Interactive, trying to uninstall first..."
    dotnet tool uninstall -g Microsoft.dotnet-interactive
    dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307
}

# Step 7: Set up Jupyter kernels
echo "Setting up Jupyter kernels..."
# Create kernel directories
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create kernel configurations
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

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

echo "Done! .NET 6 and .NET Interactive should now be ready to use."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
echo "** You MUST restart the Colab runtime for all changes to take effect **"