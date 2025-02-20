#!/usr/bin/env bash
set -e  # Exit on error

echo "Installing dotnet-sdk-6.0 and dotnet interactive..."

# Remove any existing .NET installations and Microsoft repository definitions
rm -rf /usr/share/dotnet
rm -f /etc/apt/sources.list.d/microsoft-prod.list
rm -f /etc/apt/sources.list.d/microsoft-prod.list.save

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list and install dependencies
apt-get update
apt-get install -y apt-transport-https

# Create required directories
mkdir -p /usr/share/dotnet
mkdir -p /usr/share/dotnet/host/fxr
chmod 755 /usr/share/dotnet
chmod 755 /usr/share/dotnet/host
chmod 755 /usr/share/dotnet/host/fxr

# Install .NET SDK and runtime
apt-get install -y dotnet-runtime-6.0
apt-get install -y aspnetcore-runtime-6.0
apt-get install -y dotnet-sdk-6.0

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1  # Opt out of telemetry

# Verify installation
dotnet --version || {
    echo "Failed to verify dotnet installation"
    exit 1
}

# Install dotnet interactive
dotnet tool install -g Microsoft.dotnet-interactive

# Create jupyter kernel directories
mkdir -p /root/.local/share/jupyter/kernels/.net-fsharp
mkdir -p /root/.local/share/jupyter/kernels/.net-csharp

# Install jupyter integration
dotnet interactive jupyter install

# Create kernel.json files
cat > /root/.local/share/jupyter/kernels/.net-fsharp/kernel.json << EOF
{
  "argv": ["$HOME/.dotnet/tools/dotnet-interactive", "jupyter", "--default-kernel", "fsharp", "--http-port-range", "1000-3000", "{connection_file}"],
  "display_name": ".NET (F#)",
  "language": "F#"
}
EOF

cat > /root/.local/share/jupyter/kernels/.net-csharp/kernel.json << EOF
{
  "argv": ["$HOME/.dotnet/tools/dotnet-interactive", "jupyter", "--default-kernel", "csharp", "--http-port-range", "1000-3000", "{connection_file}"],
  "display_name": ".NET (C#)",
  "language": "C#"
}
EOF

echo "Installation completed. Please verify the kernels are available in Jupyter."