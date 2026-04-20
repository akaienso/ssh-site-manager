#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/ssh-site-manager"

# Create sites command in /usr/local/bin
sudo ln -sf "$SCRIPT_PATH" /usr/local/bin/sites

# Create required directories
mkdir -p "$HOME/.sites/scripts"

# Initialize if needed
sites init

echo "Installation complete. You can now use the 'sites' command from anywhere."
echo "Run 'sites --help' for usage information." 