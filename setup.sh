#!/bin/bash

# Quick Setup Script for Docker Logger & Observability Stack
# Run this script to get everything up and running quickly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

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

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the OBS-stack directory."
    exit 1
fi

print_header "Docker Logger & Observability Stack Setup"

echo "This script will:"
echo "  ✅ Check prerequisites"
echo "  ✅ Deploy the observability stack"
echo "  ✅ Install the docker-logger CLI" 
echo "  ✅ Verify everything is working"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Setup cancelled."
    exit 0
fi

print_header "Checking Prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker and try again."
    exit 1
fi
print_success "Docker found: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi
print_success "Docker Compose found"

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker and try again."
    exit 1
fi
print_success "Docker daemon is running"

# Check for NVIDIA runtime (optional)
if docker info 2>/dev/null | grep -q nvidia; then
    print_success "NVIDIA Docker runtime detected - GPU monitoring will be available"
else
    print_warning "NVIDIA Docker runtime not found - GPU monitoring will be disabled"
fi

print_header "Deploying Observability Stack"

# Create external network if it doesn't exist
if ! docker network ls | grep -q ai-net; then
    print_status "Creating ai-net network..."
    docker network create ai-net || print_warning "ai-net network may already exist"
fi

# Stop any existing services
print_status "Stopping existing services..."
$COMPOSE_CMD down -v 2>/dev/null || true

# Pull latest images
print_status "Pulling latest images..."
$COMPOSE_CMD pull

# Build custom images
print_status "Building OpsHub service..."
$COMPOSE_CMD build opshub

# Start services
print_status "Starting observability stack..."
$COMPOSE_CMD up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

print_header "Installing CLI Tool"

# Install the CLI
chmod +x install.sh
./install.sh

print_header "Verification"

# Check service status
print_status "Checking service status..."
$COMPOSE_CMD ps

# Test connectivity
print_status "Testing service connectivity..."

# Test OpsHub
if curl -s "http://localhost:8089/health" > /dev/null; then
    print_success "OpsHub API is responding"
else
    print_warning "OpsHub API is not responding yet (may need more time)"
fi

# Test Prometheus
if curl -s "http://localhost:9090/-/healthy" > /dev/null; then
    print_success "Prometheus is responding"
else
    print_warning "Prometheus is not responding yet"
fi

# Test Grafana
if curl -s "http://localhost:3001/api/health" > /dev/null; then
    print_success "Grafana is responding"
else
    print_warning "Grafana is not responding yet"
fi

print_header "Setup Complete!"

echo "🎉 Your observability stack is now running!"
echo ""
echo "📊 Web Interfaces:"
echo "  • Grafana:    http://localhost:3001 (admin/admin)"
echo "  • Prometheus: http://localhost:9090"
echo "  • OpsHub API: http://localhost:8089"
echo ""
echo "🖥️  CLI Commands:"
echo "  • docker-logger status      - Show container status"
echo "  • docker-logger logs all    - View all logs" 
echo "  • docker-logger users       - Show user sessions"
echo "  • docker-logger performance - System metrics"
echo "  • docker-logger monitor     - Live dashboard"
echo ""
echo "📚 Documentation:"
echo "  • README.md for detailed usage"
echo "  • docker-logger --help for CLI options"
echo ""

# Show current status
print_status "Current container status:"
docker-logger status 2>/dev/null || {
    print_warning "docker-logger not in PATH yet. Try:"
    echo "  source ~/.bashrc"
    echo "  or restart your terminal"
}

print_success "Setup completed successfully! 🚀"

# Optional: Open Grafana
read -p "Open Grafana in browser? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3001
    elif command -v open &> /dev/null; then
        open http://localhost:3001
    else
        print_status "Please open http://localhost:3001 in your browser"
    fi
fi
