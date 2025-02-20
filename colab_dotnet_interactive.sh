#!/usr/bin/env bash
echo "Installing dotnet interactive 1.0.355307..."

# Create shared runtime path and link runtime files
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36
ln -sf /usr/lib/dotnet/shared/Microsoft.NETCore.App/6.0.36/* /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36/

# Add dotnet tools to PATH
export PATH=$PATH:$HOME/.dotnet/tools

# Install dotnet interactive
dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307
dotnet interactive jupyter install

# Create directories for kernels
mkdir -p /root/.local/share/jupyter/kernels/{fsharp,csharp}

# Create kernel configurations
echo "{\"argv\": [\"/usr/bin/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/usr/bin/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

echo "Done."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"