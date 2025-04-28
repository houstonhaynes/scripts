#!/usr/bin/env bash
# Comprehensive .NET 6 installation for Google Colab

echo "Setting up .NET 6 SDK and interactive tools for Google Colab..."

# Install .NET packages (assuming they're already installed)
# Check where dotnet components are actually installed
echo "Finding .NET installation locations..."
find / -name dotnet -type f 2>/dev/null

# Check for existing installations
if dpkg -l | grep -q dotnet-sdk-6.0; then
  echo ".NET SDK 6.0 is already installed"
else
  echo "Installing .NET SDK 6.0..."
  # Get Ubuntu version
  source /etc/os-release
  
  # Download and install Microsoft repository
  wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
  dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  
  # Install .NET SDK
  apt-get update
  apt-get install -y apt-transport-https
  apt-get update
  apt-get install -y dotnet-sdk-6.0
fi

# Determine actual install location
POSSIBLE_LOCATIONS=(
  "/usr/lib/dotnet"
  "/usr/share/dotnet"
  "/opt/dotnet"
)

DOTNET_PATH=""
for loc in "${POSSIBLE_LOCATIONS[@]}"; do
  if [ -f "$loc/dotnet" ]; then
    DOTNET_PATH="$loc"
    break
  fi
done

if [ -z "$DOTNET_PATH" ]; then
  echo "Can't find dotnet executable. Searching for it..."
  DOTNET_PATH=$(dirname $(find / -name dotnet -type f 2>/dev/null | head -1))
  echo "Found dotnet at: $DOTNET_PATH"
fi

if [ -z "$DOTNET_PATH" ]; then
  echo "ERROR: Could not locate dotnet installation."
  exit 1
fi

# Create symlink in a location that's in PATH
echo "Setting up dotnet symlinks..."
ln -sf $DOTNET_PATH/dotnet /usr/local/bin/dotnet
export PATH=$PATH:/usr/local/bin

# Set environment variables
echo "export DOTNET_ROOT=$DOTNET_PATH" >> ~/.bashrc
echo "export PATH=\$PATH:/usr/local/bin:\$HOME/.dotnet/tools" >> ~/.bashrc
export DOTNET_ROOT=$DOTNET_PATH

# Check if dotnet is now available
echo "Verifying dotnet command..."
which dotnet || echo "dotnet command not found in PATH"

# Source the path immediately
source ~/.bashrc

# Verify installation
if [ -x "$(command -v dotnet)" ]; then
  echo "dotnet is now available:"
  dotnet --version
  
  # Install dotnet interactive
  echo "Installing .NET Interactive..."
  dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307
  
  # Make sure ~/.dotnet/tools is in PATH for this session
  export PATH=$PATH:$HOME/.dotnet/tools
  
  # Create Jupyter kernel directories
  echo "Setting up Jupyter kernels..."
  mkdir -p /root/.local/share/jupyter/kernels/fsharp
  mkdir -p /root/.local/share/jupyter/kernels/csharp
  
  # Create kernel configurations
  echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
  echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json
  
  # Install the kernels
  if [ -f "/root/.dotnet/tools/dotnet-interactive" ]; then
    /root/.dotnet/tools/dotnet-interactive jupyter install
  else
    echo "Warning: dotnet-interactive tool not found at expected location"
    find / -name dotnet-interactive -type f 2>/dev/null
  fi
else
  echo "ERROR: dotnet installation failed."
  
  # Last resort - try finding and linking the actual binary
  DOTNET_BIN=$(find / -name dotnet -type f -executable 2>/dev/null | head -1)
  if [ -n "$DOTNET_BIN" ]; then
    echo "Found dotnet binary at $DOTNET_BIN"
    ln -sf $DOTNET_BIN /usr/local/bin/dotnet
    echo "Created symlink to /usr/local/bin/dotnet"
    echo "Please restart your Colab session and try again."
  fi
fi

echo "Done."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
echo "You may need to restart the Colab runtime for changes to take effect."