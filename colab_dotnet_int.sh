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

# Create /usr/share/dotnet/host if it doesn't exist
sudo mkdir -p /usr/share/dotnet/host

# Find the .NET Core App directory in the entire file system
DOTNET_CORE_APP_DIR=$(find / -name "Microsoft.NETCore.App" -type d 2>/dev/null)

if [ -z "$DOTNET_CORE_APP_DIR" ]; then
    echo "Error: Microsoft.NETCore.App directory not found anywhere."
    echo "Contents of /usr/share/dotnet:"
    ls -l /usr/share/dotnet
    exit 1
fi

# Create symlink to the .NET Core App directory
if [ ! -L "/usr/share/dotnet/host/fxr" ]; then
    echo "Creating symlink for /usr/share/dotnet/host/fxr..."
    sudo ln -s "$DOTNET_CORE_APP_DIR" /usr/share/dotnet/host/fxr
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create symlink for /usr/share/dotnet/host/fxr"
        exit 1
    fi
else
    echo "Symlink /usr/share/dotnet/host/fxr already exists."
fi

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