#!/bin/bash

# install-hw-test.sh
# Installs the hardware testing script and creates necessary shortcuts
# Version: 1.0.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_URL="https://github.com/username/live-hw-tester/raw/main/hw-test.sh"  # Replace with actual URL
LOCAL_BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/Desktop"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
echo -e "${YELLOW}Checking requirements...${NC}"
if ! command_exists curl; then
    echo -e "${RED}Error: curl is not installed${NC}"
    echo "Please install curl and try again"
    exit 1
fi

# Create .local/bin directory if it doesn't exist
echo -e "${YELLOW}Creating local bin directory...${NC}"
mkdir -p "$LOCAL_BIN_DIR"

# Download the script
echo -e "${YELLOW}Downloading hardware test script...${NC}"
if curl -L "$SCRIPT_URL" -o "$LOCAL_BIN_DIR/hw-test.sh"; then
    echo -e "${GREEN}Script downloaded successfully${NC}"
else
    echo -e "${RED}Failed to download script${NC}"
    exit 1
fi

# Make the script executable
echo -e "${YELLOW}Making script executable...${NC}"
chmod +x "$LOCAL_BIN_DIR/hw-test.sh"

# Create desktop shortcut
echo -e "${YELLOW}Creating desktop shortcut...${NC}"
cat > "$DESKTOP_DIR/Hardware Test.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Hardware Test
Comment=Run hardware diagnostics and stress tests
Exec=$LOCAL_BIN_DIR/hw-test.sh
Terminal=true
Categories=System;Utility;
EOF

# Make the desktop shortcut executable
chmod +x "$DESKTOP_DIR/Hardware Test.desktop"

echo -e "${GREEN}Installation complete!${NC}"
echo "You can now run the hardware test by:"
echo "1. Double-clicking the 'Hardware Test' icon on your desktop"
echo "2. Running 'hw-test.sh' from the terminal"
echo
echo "Note: You may need to log out and back in for the desktop shortcut to work properly." 