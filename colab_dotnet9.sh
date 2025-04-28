#!/usr/bin/env bash
# Complete .NET 9 installation for Google Colab
# This script performs a fresh installation with all necessary components

echo "Starting comprehensive .NET 9 installation for Google Colab..."

# Step 1: Install Microsoft package repository
echo "Setting up Microsoft package repository..."
# Get Ubuntu version
source /etc/os-release
echo "Running on Ubuntu version: $VERSION_ID"

# Download and install Microsoft repository
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package lists
apt-get update
apt-get install -y apt-transport-https
apt-get update

# Step 2: Install .NET 9 SDK and runtime
echo "Installing .NET 9 SDK and runtime components..."
apt-get install -y dotnet-sdk-9.0 aspnetcore-runtime-9.0 dotnet-runtime-9.0

# Step 3: Set up directory structure
echo "Setting up proper directory structure..."

# Create required directories
mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App
mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App
mkdir -p /usr/share/dotnet/host/fxr

# Find installed versions
NETCORE_VERSION=$(find /usr -path "*/shared/Microsoft.NETCore.App/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)
FXR_VERSION=$(find /usr -path "*/host/fxr/9.0*" -type d | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -1)

echo "Detected .NET Core App version: $NETCORE_VERSION"
echo "Detected FXR version: $FXR_VERSION"

# If we found version info, set up the directory structure
if [ -n "$NETCORE_VERSION" ]; then
    # Find source locations
    NETCORE_SRC=$(find /usr -path "*/shared/Microsoft.NETCore.App/$NETCORE_VERSION" -type d | head -1)
    ASPNET_SRC=$(find /usr -path "*/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION" -type d | head -1)
    FXR_SRC=$(find /usr -path "*/host/fxr/$FXR_VERSION" -type d | head -1)
    SDK_SRC=$(find /usr -path "*/sdk/9.0*" -type d | head -1)
    
    echo "Found .NET Core source: $NETCORE_SRC"
    echo "Found ASP.NET Core source: $ASPNET_SRC"
    echo "Found FXR source: $FXR_SRC"
    echo "Found SDK source: $SDK_SRC"
    
    # Create target directories
    mkdir -p /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION
    mkdir -p /usr/share/dotnet/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION
    mkdir -p /usr/share/dotnet/host/fxr/$FXR_VERSION
    
    # Copy files instead of symlinks for better reliability
    if [ -d "$NETCORE_SRC" ]; then
        echo "Copying .NET Core App framework..."
        cp -r $NETCORE_SRC/* /usr/share/dotnet/shared/Microsoft.NETCore.App/$NETCORE_VERSION/
    fi
    
    if [ -d "$ASPNET_SRC" ]; then
        echo "Copying ASP.NET Core App framework..."
        cp -r $ASPNET_SRC/* /usr/share/dotnet/shared/Microsoft.AspNetCore.App/$NETCORE_VERSION/
    fi
    
    if [ -d "$FXR_SRC" ]; then
        echo "Copying host/fxr libraries..."
        cp -r $FXR_SRC/* /usr/share/dotnet/host/fxr/$FXR_VERSION/
    fi
    
    # Create specific version symlinks if needed for compatibility
    for DIR in /usr/lib/dotnet/host/fxr/*; do
        if [ -d "$DIR" ]; then
            VERSION=$(basename "$DIR")
            if [[ "$VERSION" == 9.0* ]]; then
                echo "Creating additional symlink for fxr version $VERSION..."
                mkdir -p /usr/share/dotnet/host/fxr/$VERSION
                cp -r $DIR/* /usr/share/dotnet/host/fxr/$VERSION/
            fi
        fi
    done
else
    echo "WARNING: Could not detect .NET 9 version information!"
    # Try to find any .NET 9 components
    echo "Searching for any .NET 9 components..."
    find /usr -path "*/9.0*" -type d 2>/dev/null || echo "No .NET 9 components found"
fi

# Step 4: Set up dotnet command
echo "Setting up dotnet command..."
# Find the actual dotnet executable
DOTNET_BIN=$(find /usr -name dotnet -type f -executable | head -1)
if [ -n "$DOTNET_BIN" ]; then
    echo "Found dotnet binary at: $DOTNET_BIN"
    ln -sf $DOTNET_BIN /usr/local/bin/dotnet
    DOTNET_ROOT=$(dirname "$DOTNET_BIN")
else
    echo "ERROR: Could not find dotnet binary!"
    # Default to standard location
    DOTNET_ROOT="/usr/share/dotnet"
fi

# Step 5: Set environment variables
echo "Setting up environment variables..."
export DOTNET_ROOT=$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools
echo "export DOTNET_ROOT=$DOTNET_ROOT" >> ~/.bashrc
echo "export PATH=\$PATH:$DOTNET_ROOT:\$HOME/.dotnet/tools" >> ~/.bashrc

# Step 6: Verify installation
echo "Verifying .NET 9 installation..."
# Check for the dotnet command
if command -v dotnet >/dev/null 2>&1; then
    echo "dotnet command found:"
    which dotnet
    
    # Check version
    echo "Installed version:"
    dotnet --version
    
    # Check installed SDKs and runtimes
    echo "Installed SDKs:"
    dotnet --list-sdks || echo "Failed to list SDKs"
    
    echo "Installed runtimes:"
    dotnet --list-runtimes || echo "Failed to list runtimes"
else
    echo "ERROR: dotnet command not found in PATH"
fi

# Step 7: Install .NET Interactive
echo "Installing .NET Interactive..."
# Make sure PATH is correct for this session
export PATH=$PATH:$DOTNET_ROOT:$HOME/.dotnet/tools

# First check for latest compatible version of .NET Interactive for .NET 9
echo "Looking for latest compatible version of .NET Interactive..."
# Try to install latest version compatible with .NET 9
dotnet tool install -g Microsoft.dotnet-interactive || {
    echo "Error installing latest .NET Interactive, trying specific version..."
    # If latest fails, try a specific version known to work with .NET 9
    # Note: You might need to update this version as .NET 9 matures
    dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.420108
}

# Step 8: Set up Jupyter kernels
echo "Setting up Jupyter kernels..."
# Create kernel directories
mkdir -p /root/.local/share/jupyter/kernels/fsharp
mkdir -p /root/.local/share/jupyter/kernels/csharp

# Create kernel configurations
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"fsharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET 9 (F#)\", \"language\": \"F#\"}" > /root/.local/share/jupyter/kernels/fsharp/kernel.json
echo "{\"argv\": [\"/root/.dotnet/tools/dotnet-interactive\", \"jupyter\", \"--default-kernel\", \"csharp\", \"--http-port-range\", \"1000-3000\", \"{connection_file}\"], \"display_name\": \".NET 9 (C#)\", \"language\": \"C#\"}" > /root/.local/share/jupyter/kernels/csharp/kernel.json

# Register kernels with Jupyter
if [ -f "/root/.dotnet/tools/dotnet-interactive" ]; then
    echo "Registering kernels with dotnet-interactive..."
    /root/.dotnet/tools/dotnet-interactive jupyter install
else
    echo "WARNING: dotnet-interactive not found at /root/.dotnet/tools/dotnet-interactive"
    find / -name dotnet-interactive -type f 2>/dev/null
fi

# Final check
echo "Final verification of directory structure:"
echo ".NET Core App frameworks:"
ls -la /usr/share/dotnet/shared/Microsoft.NETCore.App/ 
echo "Host FXR directories:"
ls -la /usr/share/dotnet/host/fxr/

# Add diagnostic information if something went wrong
if ! dotnet --list-sdks >/dev/null 2>&1; then
    echo "===== DIAGNOSTICS ====="
    echo "Checking library dependencies:"
    ldd $(which dotnet) || echo "Failed to check dependencies"
    
    echo "Checking for missing directories:"
    for dir in "/usr/share/dotnet" "/usr/share/dotnet/shared" "/usr/share/dotnet/host"; do
        if [ ! -d "$dir" ]; then
            echo "Missing directory: $dir"
        fi
    done
fi

# Create proxy file
echo "Creating IPC proxy kernel file..."
cat > ipc_proxy_kernel.py << 'EOL'
import zmq;
import json;
import argparse;
from threading import Thread;
from traitlets.traitlets import Type;
from jupyter_client import KernelClient;
from jupyter_client.session import Session;
from jupyter_client.channels import HBChannel;
from jupyter_client.manager import KernelManager;

parser = argparse.ArgumentParser();
parser.add_argument("connection_file");
parser.add_argument("--kernel", type = str, required = True);
args = parser.parse_args();

# parse connection file details
with open(args.connection_file, "r") as connection_file:
    connection_file_contents = json.load(connection_file);
    transport = str(connection_file_contents["transport"]);
    ip = str(connection_file_contents["ip"]);
    shell_port = int(connection_file_contents["shell_port"]);
    stdin_port = int(connection_file_contents["stdin_port"]);
    control_port = int(connection_file_contents["control_port"]);
    iopub_port = int(connection_file_contents["iopub_port"]);
    hb_port = int(connection_file_contents["hb_port"]);
    signature_scheme = str(connection_file_contents["signature_scheme"]);
    key = str(connection_file_contents["key"]).encode();
# channel | kernel_type | client_type
# shell   | ROUTER      | DEALER
# stdin   | ROUTER      | DEALER
# ctrl    | ROUTER      | DEALER
# iopub   | PUB         | SUB
# hb      | REP         | REQ
zmq_context = zmq.Context()

def create_and_bind_socket(port: int, socket_type: int):
    if(port <= 0):
        raise ValueError(f"Invalid port: {port}");
    if(transport == "tcp"):
        addr = f"tcp://{ip}:{port}";
    elif(transport == "ipc"):
        addr = f"ipc://{ip}-{port}";
    else:
        raise ValueError(f"Unknown transport: {transport}");
    socket: zmq.Socket = zmq_context.socket(socket_type);
    socket.linger = 1000; # ipykernel does this
    socket.bind(addr);
    return socket;

shell_socket = create_and_bind_socket(shell_port, zmq.ROUTER);
stdin_socket = create_and_bind_socket(stdin_port, zmq.ROUTER);
control_socket = create_and_bind_socket(control_port, zmq.ROUTER);
iopub_socket = create_and_bind_socket(iopub_port, zmq.PUB);
hb_socket = create_and_bind_socket(hb_port, zmq.REP);
# Proxy and the real kernel have their own heartbeats. (shoutout to ipykernel
# for this neat little heartbeat implementation)
Thread(target = zmq.device, args = (zmq.QUEUE, hb_socket, hb_socket)).start();

def ZMQProxyChannel_factory(proxy_server_socket: zmq.Socket):
    class ZMQProxyChannel(object):
        kernel_client_socket: zmq.Socket = None;
        session: Session = None;

        def __init__(self, socket: zmq.Socket, session: Session, _ = None):
            super().__init__();
            self.kernel_client_socket = socket;
            self.session = session;

        def start(self):
            # Very convenient zmq device here, proxy will handle the actual zmq
            # proxying on each of our connected sockets (other than heartbeat).
            # It blocks while they are connected so stick it in a thread.
            Thread(
                target = zmq.proxy,
                args = (proxy_server_socket, self.kernel_client_socket)
            ).start();

        def stop(self):
            if(self.kernel_client_socket is not None):
                try:
                    self.kernel_client_socket.close(linger = 0);
                except Exception:
                    pass;
                self.kernel_client_socket = None;

        def is_alive(self):
            return self.kernel_client_socket is not None;

    return ZMQProxyChannel

class ProxyKernelClient(KernelClient):
    shell_channel_class = Type(ZMQProxyChannel_factory(shell_socket));
    stdin_channel_class = Type(ZMQProxyChannel_factory(stdin_socket));
    control_channel_class = Type(ZMQProxyChannel_factory(control_socket));
    iopub_channel_class = Type(ZMQProxyChannel_factory(iopub_socket));
    hb_channel_class = Type(HBChannel);


kernel_manager = KernelManager();
kernel_manager.kernel_name = args.kernel;
kernel_manager.transport = "tcp";
kernel_manager.client_factory = ProxyKernelClient;
kernel_manager.autorestart = False;
# Make sure the wrapped kernel uses the same session info. This way we don't
# need to decode them before forwarding, we can directly pass everything
# through.
kernel_manager.session.signature_scheme = signature_scheme;
kernel_manager.session.key = key;
kernel_manager.start_kernel();
# Connect to the real kernel we just started and start up all the proxies.
kernel_client: ProxyKernelClient = kernel_manager.client();
kernel_client.start_channels();
# Everything should be up and running. We now just wait for the managed kernel
# process to exit and when that happens, shutdown and exit with the same code.
exit_code = kernel_manager.kernel.wait();
kernel_client.stop_channels();
zmq_context.destroy(0);
exit(exit_code);
EOL

# Set up the proxy for F# kernel
echo "Setting up F# kernel proxy..."
python3 - << 'EOF'
import os;
import sys;
import json;
import shutil;
import os.path;
from jupyter_client.kernelspec import KernelSpec, KernelSpecManager, NoSuchKernel;

kernel_spec_manager = KernelSpecManager();
try:
    real_kernel_spec = kernel_spec_manager.get_kernel_spec(".net-fsharp");
    real_kernel_install_path = real_kernel_spec.resource_dir;
    new_kernel_name = ".net-fsharp_tcp";
    new_kernel_install_path = os.path.join(
        os.path.dirname(real_kernel_install_path), new_kernel_name
    );
    
    # Only move if it exists and hasn't been moved already
    if os.path.exists(real_kernel_install_path) and not os.path.exists(new_kernel_install_path):
        shutil.move(real_kernel_install_path, new_kernel_install_path);
        
        # Update the moved kernel name and args
        new_kernel_json_path = os.path.join(new_kernel_install_path, "kernel.json");
        with open(new_kernel_json_path, "r") as in_:
            real_kernel_json = json.load(in_);
            real_kernel_json["name"] = new_kernel_name;
            real_kernel_json["argv"] = list(
                map(
                    lambda arg: arg.replace(real_kernel_install_path, new_kernel_install_path),
                    real_kernel_json["argv"]
                )
            );
        with open(new_kernel_json_path, "w") as out:
            json.dump(real_kernel_json, out);
        
        # Create directory for proxy kernel
        os.makedirs(real_kernel_install_path, exist_ok=True)
        proxy_kernel_implementation_path = os.path.join(
            real_kernel_install_path, "ipc_proxy_kernel.py"
        );
        
        # Create proxy kernel spec
        proxy_kernel_spec = KernelSpec();
        proxy_kernel_spec.argv = [
            sys.executable,
            proxy_kernel_implementation_path,
            "{connection_file}",
            f"--kernel={new_kernel_name}"
        ];
        proxy_kernel_spec.display_name = real_kernel_spec.display_name;
        proxy_kernel_spec.interrupt_mode = real_kernel_spec.interrupt_mode or "message";
        proxy_kernel_spec.language = real_kernel_spec.language;
        proxy_kernel_json_path = os.path.join(real_kernel_install_path, "kernel.json");
        with open(proxy_kernel_json_path, "w") as out:
            json.dump(proxy_kernel_spec.to_dict(), out, indent = 2);
        
        # Copy proxy script
        shutil.copy("ipc_proxy_kernel.py", proxy_kernel_implementation_path);
        print("F# kernel proxy setup complete.")
    else:
        print("F# kernel proxy already set up or original kernel not found.")
except NoSuchKernel:
    print("F# kernel not found. Make sure dotnet interactive installed the kernels properly.")
except Exception as e:
    print(f"Error setting up F# kernel proxy: {e}")
EOF

# Clean up temporary files
rm -f ipc_proxy_kernel.py

# Final verification
echo "Verifying F# kernel setup..."
jupyter kernelspec list

echo "Done! .NET 9 and .NET Interactive should now be ready to use."
echo "Select \"Runtime\" -> \"Change Runtime Type\" and click \"Save\" to activate for this notebook"
echo "** IMPORTANT: You MUST disconnect and reconnect to the runtime for all changes to take effect **"