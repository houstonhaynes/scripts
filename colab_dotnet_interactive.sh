#!/usr/bin/env bash
# Adds Jupyter kernels for F# and C# to a Google Colab session
echo "Installing dotnet interactive 1.0.355307..."

# First ensure all the symlinks point to the right places
rm -f /usr/share/dotnet/host/fxr/6.0.428/libhostfxr.so
mkdir -p /usr/share/dotnet/host/fxr/6.0.428

# Create proper symlinks to the actual files
ln -s /usr/lib/dotnet/host/fxr/6.0.36/libhostfxr.so /usr/share/dotnet/host/fxr/6.0.428/libhostfxr.so
ln -s /usr/bin/dotnet /usr/share/dotnet/dotnet

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