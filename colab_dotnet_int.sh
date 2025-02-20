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
apt-get install -y dotnet-runtime-6.0
apt-get install -y aspnetcore-runtime-6.0
apt-get install -y dotnet-sdk-6.0

# Verify .NET installation
if [ ! -d "/usr/share/dotnet/host/fxr" ]; then
    echo "Creating missing fxr directory..."
    mkdir -p /usr/share/dotnet/host/fxr
fi

# Verify installation
dotnet --version

# Install dotnet interactive
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
dotnet tool install -g Microsoft.dotnet-interactive

# Create directories (with parents)
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