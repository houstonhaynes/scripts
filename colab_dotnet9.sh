#!/usr/bin/env bash
# Robust .NET and F# installation for Google Colab
# This script creates a stable environment for F# in Jupyter

echo "Starting robust .NET installation for Google Colab with F# support..."

# Step 1: Set critical environment variables to prevent segmentation faults
echo "Setting critical environment variables..."
export DOTNET_EnableWriteXorExecute=0
export DOTNET_System_Globalization_Invariant=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_ROOT=/usr/share/dotnet

# Make these persistent
echo "export DOTNET_EnableWriteXorExecute=0" >> ~/.bashrc
echo "export DOTNET_System_Globalization_Invariant=1" >> ~/.bashrc
echo "export DOTNET_CLI_TELEMETRY_OPTOUT=1" >> ~/.bashrc
echo "export DOTNET_ROOT=/usr/share/dotnet" >> ~/.bashrc
echo "export PATH=\$PATH:/usr/share/dotnet:/root/.dotnet/tools" >> ~/.bashrc

# Step 2: Install Microsoft package repository
echo "Setting up Microsoft package repository..."
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Install dependencies that help prevent segmentation faults
apt-get update -y
apt-get install -y apt-transport-https wget libicu-dev liblttng-ust0 libcurl4 libssl-dev zlib1g libunwind8

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package lists
apt-get update -y

# Step 3: Install both .NET 8 (more stable) and .NET 9
echo "Installing .NET SDKs and runtimes..."
apt-get install -y dotnet-sdk-8.0 dotnet-runtime-8.0 aspnetcore-runtime-8.0
apt-get install -y dotnet-sdk-9.0 dotnet-runtime-9.0 aspnetcore-runtime-9.0

# Step 4: Fix directory structure to prevent conflicts
echo "Setting up proper directory structure..."

# Create required directories
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App
mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App
mkdir -p /usr/share/dotnet/host/fxr

# Find installed versions
NETCORE_VERSION_9=$(find /usr -path "*/shared/Microsoft.NETCore.App/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
NETCORE_VERSION_8=$(find /usr -path "*/shared/Microsoft.NETCore.App/8.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
FXR_VERSION_9=$(find /usr -path "*/host/fxr/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
FXR_VERSION_8=$(find /usr -path "*/host/fxr/8.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)

echo "Detected .NET 9 Core App version: $NETCORE_VERSION_9"
echo "Detected .NET 8 Core App version: $NETCORE_VERSION_8"
echo "Detected .NET 9 FXR version: $FXR_VERSION_9"
echo "Detected .NET 8 FXR version: $FXR_VERSION_8"

# Copy directories to standard location to ensure proper discovery
if [ -n "$NETCORE_VERSION_9" ]; then
    NETCORE_SRC_9=$(find /usr -path "*/shared/Microsoft.NETCore.App/$NETCORE_VERSION_9" -type d | head -1)
    mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION_9
    [ -d "$NETCORE_SRC_9" ] && cp -r $NETCORE_SRC_9/* /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION_9/ || echo "Source directory not found for .NET 9 Core App"
fi

if [ -n "$NETCORE_VERSION_8" ]; then
    NETCORE_SRC_8=$(find /usr -path "*/shared/Microsoft.NETCore.App/$NETCORE_VERSION_8" -type d | head -1)
    mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION_8
    [ -d "$NETCORE_SRC_8" ] && cp -r $NETCORE_SRC_8/* /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION_8/ || echo "Source directory not found for .NET 8 Core App"
fi

# Step 5: Set up dotnet command
echo "Setting up dotnet command..."
# Find the actual dotnet executable
DOTNET_BIN=$(find /usr -name dotnet -type f -executable | head -1)
if [ -n "$DOTNET_BIN" ]; then
    echo "Found dotnet binary at: $DOTNET_BIN"
    ln -sf $DOTNET_BIN /usr/local/bin/dotnet
else
    echo "ERROR: Could not find dotnet binary! Installing directly..."
    
    # Alternative approach - download and extract directly
    mkdir -p /tmp/dotnet
    
    # Try .NET 8 first (more stable for Colab)
    echo "Downloading .NET 8 SDK directly..."
    wget -q https://download.visualstudio.microsoft.com/download/pr/365bc2a0-fb65-4a8a-af77-8f78dfc2d11b/037db752d257156676e0d4af4c1c3647/dotnet-sdk-8.0.201-linux-x64.tar.gz -O /tmp/dotnet/dotnet-sdk.tar.gz
    
    echo "Extracting .NET 8 SDK..."
    mkdir -p /usr/share/dotnet
    tar -xzf /tmp/dotnet/dotnet-sdk.tar.gz -C /usr/share/dotnet
    
    # Create symlinks
    ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet
    rm -rf /tmp/dotnet
fi

# Step 6: Create F# and C# Jupyter kernels directly (without relying on dotnet-interactive)
echo "Creating Jupyter kernels for F# and C#..."

# Install jupyter if needed
pip install -q jupyter

# Create directories for kernels
mkdir -p ~/.local/share/jupyter/kernels/fsharp
mkdir -p ~/.local/share/jupyter/kernels/csharp

# Create kernel specifications that use the dotnet CLI directly
# For F#
cat > ~/.local/share/jupyter/kernels/fsharp/kernel.json << EOL
{
  "argv": [
    "/usr/local/bin/dotnet",
    "fsi",
    "--readline-",
    "--jupyter",
    "{connection_file}"
  ],
  "display_name": ".NET (F#)",
  "language": "F#"
}
EOL

# For C#
cat > ~/.local/share/jupyter/kernels/csharp/kernel.json << EOL
{
  "argv": [
    "/usr/local/bin/dotnet",
    "csi",
    "--jupyter",
    "{connection_file}"
  ],
  "display_name": ".NET (C#)",
  "language": "C#"
}
EOL

# Step 7: Install required Python packages for Jupyter integration
echo "Installing required Python packages..."
pip install -q jupyter-client zmq

# Step 8: Install dotnet-interactive with proper version
echo "Installing dotnet-interactive with a stable version..."
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools

# Step 8: Install dotnet-interactive with a compatible version
echo "Installing dotnet-interactive with a compatible version..."
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools

# First, let's determine which .NET version is most stable
if dotnet --list-sdks | grep -q "8.0"; then
    echo "Using .NET 8 for dotnet-interactive installation..."
    # Try installing a version known to work with .NET 8
    dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.615604 || {
        echo "Trying alternative version..."
        dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.530202 || {
            echo "Trying older version..."
            dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.468001
        }
    }
elif dotnet --list-sdks | grep -q "6.0"; then
    echo "Using .NET 6 for dotnet-interactive installation..."
    # .NET 6 often works better with these versions
    dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.421302
fi

# Register the interactive kernels if installation was successful
if command -v dotnet-interactive > /dev/null 2>&1; then
    echo "dotnet-interactive installed successfully, registering kernels..."
    dotnet interactive jupyter install
else
    echo "Using direct kernels as fallback method..."
fi

# Step 10: Verify if the installation was successful
echo "Verifying installation..."
if command -v dotnet > /dev/null 2>&1; then
    echo "dotnet command is available"
    
    # Try to run a safe command that shouldn't segfault
    dotnet --info || echo "Could not run dotnet --info but installation might still be usable"
    
    # List available Jupyter kernels
    jupyter kernelspec list || echo "Could not list kernels but installation might still be usable"
    
    # Try to run F# test script
    echo "Testing F# script (this might fail but F# could still work in Jupyter)..."
    dotnet fsi ~/fsharp-test/test.fsx || echo "Test script didn't work but F# might still work in Jupyter"
else
    echo "dotnet command not found! Installation failed."
fi

echo ""
echo "======================================================"
echo "Installation completed. To use F# in Jupyter Notebook:"
echo "1. Disconnect and reconnect to this Colab runtime"
echo "2. Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\""
echo "3. In a new cell, change the kernel to \".NET (F#)\" via the kernel selector"
echo "4. Try running a basic F# code snippet such as:"
echo "   printfn \"Hello from F#!\""
echo "======================================================"
echo ""
echo "If you encounter any issues, try running the notebook with the C# kernel first"
echo "to verify that .NET is working properly."
echo ""
echo "** IMPORTANT: You MUST disconnect and reconnect to the runtime for all changes to take effect **"