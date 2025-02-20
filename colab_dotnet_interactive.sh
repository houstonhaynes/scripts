#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Installing dotnet interactive 1.0.355307..."

# Create base directories
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36

# Link the entire dotnet directory structure
ln -sf /usr/lib/dotnet/host /usr/share/dotnet/
ln -sf /usr/lib/dotnet/shared/Microsoft.NETCore.App/6.0.36/* /usr/share/dotnet/shared/Microsoft.NETCore.App/6.0.36/
ln -sf /usr/lib/dotnet/sdk /usr/share/dotnet/

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