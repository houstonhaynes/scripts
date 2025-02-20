#!/usr/bin/env bash
set -e  # Exit on error

echo "Installing .NET 9 and dotnet interactive..."

# Add Microsoft package repository
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list and install dependencies
apt-get update
apt-get install -y apt-transport-https

# Install .NET 9
apt-get install -y dotnet-sdk-9.0

# Clean up NuGet cache
rm -rf /root/.nuget/packages

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export NUGET_PACKAGES=/root/.nuget/packages

# Install dotnet interactive (specific version)
dotnet tool install -g Microsoft.dotnet-interactive

# Create jupyter kernel directories
mkdir -p /root/.local/share/jupyter/kernels/.net-fsharp
mkdir -p /root/.local/share/jupyter/kernels/.net-csharp

# Create kernel.json files with explicit kernel names
cat > /root/.local/share/jupyter/kernels/.net-fsharp/kernel.json << EOF
{
  "argv": ["/root/.dotnet/tools/dotnet-interactive", "jupyter", "--kernel-name", "fsharp", "{connection_file}"],
  "display_name": ".NET (F#)",
  "language": "F#"
}
EOF

cat > /root/.local/share/jupyter/kernels/.net-csharp/kernel.json << EOF
{
  "argv": ["/root/.dotnet/tools/dotnet-interactive", "jupyter", "--kernel-name", "csharp", "{connection_file}"],
  "display_name": ".NET (C#)",
  "language": "C#"
}
EOF

# Update Jupyter kernelspecs
jupyter kernelspec list

# Verify installation
echo "Verifying installation..."
dotnet tool list -g
jupyter kernelspec list

echo "Done."
echo "After running this script:"
echo "1. Select \"Runtime\" -> \"Change Runtime Type\""
echo "2. Choose \".NET (C#)\" or \".NET (F#)\" from the dropdown"
echo "3. Click \"Save\""