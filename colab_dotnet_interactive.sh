#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Setting up .NET environment and installing dotnet interactive 1.0.355307..."

# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Create the shared runtime directory structure
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36

# Link the runtime files where the SDK expects them
echo "Linking runtime files..."
ln -sf /usr/lib/dotnet/shared/Microsoft.NETCore.App/6.0.36/* /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36/

# Verify the framework is properly linked
echo "Verifying .NET setup..."
dotnet --list-runtimes

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools

# Install dotnet interactive
echo "Installing dotnet interactive..."
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307

# Install Jupyter kernels
echo "Installing Jupyter kernels..."
dotnet interactive jupyter install

# Create kernel directories
mkdir -p /root/.local/share/jupyter/kernels/{fsharp,csharp}

# Create kernel configurations
echo "Configuring kernels..."
echo "{\"argv\": [\"/usr/bin/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/usr/bin/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

# Verify installation
echo "Verifying installation..."
dotnet tool list -g
jupyter kernelspec list

echo "Done."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"