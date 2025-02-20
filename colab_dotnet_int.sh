#!/usr/bin/env bash
set -e  # Exit on error

echo "Installing dotnet-sdk-6.0 and dotnet interactive..."

# Install .NET SDK
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb > /dev/null
apt-get update > /dev/null
apt-get install -y dotnet-sdk-6.0 > /dev/null

# Install dotnet interactive
dotnet tool install -g Microsoft.dotnet-interactive > /dev/null
export PATH=$PATH:$HOME/.dotnet/tools

# Install jupyter integration
dotnet interactive jupyter install > /dev/null

# Create kernel directories
mkdir -p /root/.local/share/jupyter/kernels/.net-fsharp
mkdir -p /root/.local/share/jupyter/kernels/.net-csharp

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

# Verify installation
if command -v dotnet &> /dev/null && [ -f "$HOME/.dotnet/tools/dotnet-interactive" ]; then
    echo "Installation completed successfully."
    echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
else
    echo "Installation failed. Please check the error messages above."
    exit 1
fi