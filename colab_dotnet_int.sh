#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Installing .NET SDK and dotnet interactive 1.0.355307..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

# Update package list and install .NET SDK packages
sudo apt-get update
sudo apt-get install -y dotnet-sdk-6.0 aspnetcore-runtime-6.0 dotnet-runtime-6.0 dotnet-hostfxr-6.0

# After installing .NET SDK
if [ ! -d "/usr/share/dotnet" ]; then
    echo "Error: .NET installation failed"
    exit 1
fi

# Find the correct hostfxr directory
HOSTFXR_DIR=$(find /usr/lib/dotnet/shared/Microsoft.NETCore.App -type d -name "[0-9]*\.[0-9]*" 2>/dev/null | head -n 1)

if [ -z "$HOSTFXR_DIR" ]; then
    echo "Error: No versioned hostfxr directory found."
    echo "Contents of /usr/lib/dotnet/shared/Microsoft.NETCore.App:"
    ls -l /usr/lib/dotnet/shared/Microsoft.NETCore.App
    exit 1
fi

# Create /usr/share/dotnet/host/fxr directory
sudo mkdir -p /usr/share/dotnet/host/fxr

# Copy files from the versioned directory to /usr/share/dotnet/host/fxr
echo "Copying files from $HOSTFXR_DIR to /usr/share/dotnet/host/fxr..."
sudo cp -r "$HOSTFXR_DIR"/* /usr/share/dotnet/host/fxr/

# Verify the framework setup
echo "Verifying .NET setup..."
dotnet --list-runtimes
if [ $? -ne 0 ]; then
    echo "Error: .NET setup verification failed"
    exit 1
fi

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools

# Install dotnet interactive
echo "Installing dotnet interactive..."
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307
if [ $? -ne 0 ]; then
    echo "Error: dotnet interactive installation failed"
    exit 1
fi

# Install Jupyter kernels
echo "Installing Jupyter kernels..."
dotnet interactive jupyter install
if [ $? -ne 0 ]; then
    echo "Error: Jupyter kernels installation failed"
    exit 1
fi

# Create kernel configurations
echo "Creating kernel configurations..."
mkdir -p /root/.local/share/jupyter/kernels/.net-csharp
mkdir -p /root/.local/share/jupyter/kernels/.net-fsharp

# Create kernel.json files
cat > /root/.local/share/jupyter/kernels/.net-fsharp/kernel.json << EOF
{
  "argv": ["/usr/bin/dotnet", "interactive", "jupyter", "--kernel-name", "fsharp", "--http-port-range", "1000-3000", "{connection_file}"],
  "display_name": ".NET (F#)",
  "language": "F#"
}
EOF

cat > /root/.local/share/jupyter/kernels/.net-csharp/kernel.json << EOF
{
  "argv": ["/usr/bin/dotnet", "interactive", "jupyter", "--kernel-name", "csharp", "--http-port-range", "1000-3000", "{connection_file}"],
  "display_name": ".NET (C#)",
  "language": "C#"
}
EOF

# Verify installation
echo "Verifying installation..."
dotnet tool list -g
jupyter kernelspec list

echo "Done."
echo "After running this script:"
echo "1. Select \"Runtime\" -> \"Change Runtime Type\""
echo "2. Choose \".NET (C#)\" or \".NET (F#)\" from the dropdown"
echo "3. Click \"Save\""