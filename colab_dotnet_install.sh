#!/usr/bin/env bash
set -e  # Exit on error

echo "Installing dotnet interactive for existing .NET installation..."

# Determine .NET version
DOTNET_VERSION=$(dotnet --version | cut -d '.' -f 1)

echo "Detected .NET version: $DOTNET_VERSION"

# Set .NET version-specific variables
if [ "$DOTNET_VERSION" = "9" ]; then
    DOTNET_RUNTIME="9.0"
    DOTNET_VERSION_DIR="9.0"
else
    echo "Unsupported .NET version: $DOTNET_VERSION. Aborting."
    exit 1
fi

# Set environment variables
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install dotnet interactive
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