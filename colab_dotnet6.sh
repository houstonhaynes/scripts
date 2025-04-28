#!/usr/bin/env bash
# Fix .NET directory structure for Google Colab

echo "Fixing .NET 6 installation structure..."

# Create the missing directories
sudo mkdir -p /usr/share/dotnet/host/fxr

# Find where the FXR files are actually located
echo "Searching for existing FXR installation..."
FXR_PATH=$(find /usr -name fxr -type d 2>/dev/null | grep -v /usr/share/dotnet)

if [ -z "$FXR_PATH" ]; then
  echo "Cannot find existing FXR installation. Looking more broadly..."
  FXR_PATH=$(find / -name fxr -type d 2>/dev/null | grep -v /usr/share/dotnet)
fi

if [ -n "$FXR_PATH" ]; then
  echo "Found FXR at: $FXR_PATH"
  
  # Copy or link all version directories from the found location to the expected location
  for VERSION_DIR in "$FXR_PATH"/*; do
    if [ -d "$VERSION_DIR" ]; then
      VERSION=$(basename "$VERSION_DIR")
      echo "Linking version directory: $VERSION"
      sudo ln -sf "$VERSION_DIR" "/usr/share/dotnet/host/fxr/$VERSION"
    fi
  done
else
  echo "No existing FXR installation found. Creating from installed packages..."
  
  # Find the hostfxr shared library
  HOSTFXR_LIB=$(find /usr -name libhostfxr.so 2>/dev/null)
  
  if [ -n "$HOSTFXR_LIB" ]; then
    echo "Found hostfxr library at: $HOSTFXR_LIB"
    HOSTFXR_DIR=$(dirname "$HOSTFXR_LIB")
    PARENT_DIR=$(dirname "$HOSTFXR_DIR")
    
    if [[ "$PARENT_DIR" == */dotnet/host/fxr/* ]]; then
      VERSION=$(basename "$PARENT_DIR")
      echo "Detected version: $VERSION"
      sudo mkdir -p "/usr/share/dotnet/host/fxr/$VERSION"
      sudo cp -r "$PARENT_DIR"/* "/usr/share/dotnet/host/fxr/$VERSION/"
    else
      # If we find the library but not in the expected structure, 
      # create a version directory and place it there
      VERSION="6.0.136"  # Use the version mentioned in your logs
      echo "Creating version directory for $VERSION"
      sudo mkdir -p "/usr/share/dotnet/host/fxr/$VERSION"
      sudo cp "$HOSTFXR_LIB" "/usr/share/dotnet/host/fxr/$VERSION/"
    fi
  else
    echo "Cannot find libhostfxr.so. Creating structure manually..."
    
    # Create the directory structure based on the version from your logs
    VERSION="6.0.136"
    echo "Creating version directory for $VERSION and linking libraries"
    sudo mkdir -p "/usr/share/dotnet/host/fxr/$VERSION"
    
    # Try to find the .NET installation root
    DOTNET_ROOT=$(find /usr -name dotnet -type f -executable 2>/dev/null | head -1)
    if [ -n "$DOTNET_ROOT" ]; then
      DOTNET_ROOT=$(dirname "$DOTNET_ROOT")
      echo "Found .NET root at: $DOTNET_ROOT"
      
      # Look for files in various potential locations
      for LIB in libhostfxr.so libclrjit.so libcoreclr.so; do
        LIB_PATH=$(find "$DOTNET_ROOT" -name "$LIB" 2>/dev/null | head -1)
        if [ -n "$LIB_PATH" ]; then
          echo "Found $LIB at: $LIB_PATH"
          sudo cp "$LIB_PATH" "/usr/share/dotnet/host/fxr/$VERSION/"
        fi
      done
    fi
  fi
fi

# Make sure dotnet is in the path
sudo ln -sf /usr/bin/dotnet /usr/local/bin/dotnet

# Test if it works now
echo "Testing .NET installation..."
dotnet --list-sdks

# Install dotnet interactive if .NET works now
if [ $? -eq 0 ]; then
  echo "Installing .NET Interactive..."
  dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.355307
  
  # Set up Jupyter kernels
  echo "Setting up Jupyter kernels..."
  mkdir -p ~/.local/share/jupyter/kernels/fsharp
  mkdir -p ~/.local/share/jupyter/kernels/csharp
  
  echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (F#)\", \"language\": \"F#\"}" > ~/.local/share/jupyter/kernels/fsharp/kernel.json
  echo "{\"argv\": [\"$HOME/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET (C#)\", \"language\": \"C#\"}" > ~/.local/share/jupyter/kernels/csharp/kernel.json
  
  # Add .dotnet/tools to PATH
  export PATH=$PATH:$HOME/.dotnet/tools
  echo 'export PATH=$PATH:$HOME/.dotnet/tools' >> ~/.bashrc
  
  # Install the kernels if dotnet-interactive exists
  if [ -f "$HOME/.dotnet/tools/dotnet-interactive" ]; then
    "$HOME/.dotnet/tools/dotnet-interactive" jupyter install
  else
    echo "Warning: dotnet-interactive not found at $HOME/.dotnet/tools/dotnet-interactive"
  fi
else
  echo "ERROR: .NET installation still not working correctly."
fi

echo "Done. You may need to restart the Colab runtime for all changes to take effect."