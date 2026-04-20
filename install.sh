#!/bin/bash

# Create sites command in /usr/local/bin
sudo ln -sf "$(readlink -f sites-manager.sh)" /usr/local/bin/sites
sudo chmod +x /usr/local/bin/sites

# Create required directories
mkdir -p "$HOME/.sites/scripts"

# Initialize if needed
sites init

echo "Installation complete. You can now use the 'sites' command from anywhere."
echo "Run 'sites --help' for usage information." 