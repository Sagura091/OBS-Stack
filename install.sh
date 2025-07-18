#!/bin/bash

# Docker Logger Installation Script
# This script installs the docker-logger CLI tool on your system

set -e

echo "=== Docker Logger Installation ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. Installing system-wide."
    INSTALL_DIR="/usr/local/bin"
    USER_INSTALL=""
else
    print_status "Installing for current user."
    INSTALL_DIR="$HOME/.local/bin"
    USER_INSTALL="--user"
    mkdir -p "$INSTALL_DIR"
fi

# Check for Python 3.11+
print_status "Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_status "Found Python $PYTHON_VERSION"
    
    # Convert version to comparable number
    VERSION_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    VERSION_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    VERSION_NUM=$(( VERSION_MAJOR * 100 + VERSION_MINOR ))
    
    if [ $VERSION_NUM -lt 311 ]; then
        print_error "Python 3.11 or higher is required. Found: $PYTHON_VERSION"
        print_status "Please upgrade Python and try again."
        exit 1
    fi
else
    print_error "Python3 not found. Please install Python 3.11+ and try again."
    exit 1
fi

# Check if pip is available
print_status "Checking pip availability..."
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 not found. Please install pip and try again."
    exit 1
fi

# Install the OpsHub package
print_status "Installing docker-logger package..."
cd "$(dirname "$0")"

if [ -f "pyproject.toml" ]; then
    print_status "Installing from source..."
    pip3 install $USER_INSTALL -e .
else
    print_error "pyproject.toml not found. Please run this script from the opshub directory."
    exit 1
fi

# Verify installation
print_status "Verifying installation..."
if command -v docker-logger &> /dev/null; then
    print_success "docker-logger CLI installed successfully!"
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]] && [ "$INSTALL_DIR" != "/usr/local/bin" ]; then
        print_warning "$INSTALL_DIR is not in your PATH."
        print_status "Add the following line to your ~/.bashrc or ~/.zshrc:"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
else
    print_error "Installation verification failed."
    print_status "The docker-logger command was not found in PATH."
    exit 1
fi

# Set environment variable for OpsHub connection
print_status "Setting up environment..."
OPSHUB_HOST="${OPSHUB_HOST:-localhost}"

echo ""
print_success "Installation completed successfully!"
echo ""
echo "=== Usage Examples ==="
echo ""
echo "# View logs from all containers:"
echo "  docker-logger logs all"
echo ""
echo "# View only error logs:"
echo "  docker-logger logs all --level error"
echo ""
echo "# Follow logs in real-time:"
echo "  docker-logger logs all --follow"
echo ""
echo "# Show container status:"
echo "  docker-logger status"
echo ""
echo "# Monitor OpenWebUI users:"
echo "  docker-logger users"
echo ""
echo "# Show system performance:"
echo "  docker-logger performance"
echo ""
echo "# Live monitoring dashboard:"
echo "  docker-logger monitor"
echo ""
echo "=== Configuration ==="
echo ""
echo "Set the OpsHub server address (default: localhost):"
echo "  export OPSHUB_HOST=your-server-ip"
echo ""
print_status "Make sure the OpsHub container is running with:"
print_status "  docker-compose up -d opshub"
echo ""

# Check if OpsHub is running
print_status "Checking OpsHub connectivity..."
if curl -s "http://$OPSHUB_HOST:8089/health" > /dev/null 2>&1; then
    print_success "OpsHub server is running and accessible!"
    echo ""
    echo "Try it now:"
    echo "  docker-logger status"
else
    print_warning "OpsHub server is not accessible at http://$OPSHUB_HOST:8089"
    print_status "Start the observability stack with:"
    print_status "  docker-compose up -d"
    print_status "Then try: docker-logger status"
fi

echo ""
print_success "Setup complete! 🚀"
