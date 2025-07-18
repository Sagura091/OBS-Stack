#!/bin/bash

# 🚀 OBS Stack - One-Command Quick Setup
# Ultra-simple installation for Linux/EC2

set -e

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fancy banner
echo -e "${PURPLE}"
cat << "EOF"
 ██████╗ ██████╗ ███████╗    ███████╗████████╗ █████╗  ██████╗██╗  ██╗
██╔═══██╗██╔══██╗██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
██║   ██║██████╔╝███████╗    ███████╗   ██║   ███████║██║     █████╔╝ 
██║   ██║██╔══██╗╚════██║    ╚════██║   ██║   ██╔══██║██║     ██╔═██╗ 
╚██████╔╝██████╔╝███████║    ███████║   ██║   ██║  ██║╚██████╗██║  ██╗
 ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
                                                                        
    🚀 Comprehensive Observability & Monitoring for 200+ Users
EOF
echo -e "${NC}"

echo -e "${CYAN}===============================================${NC}"
echo -e "${GREEN}🎯 ONE-COMMAND SETUP - No Configuration Needed!${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root for some commands
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
        print_status "Will use sudo for system commands..."
    fi
}

# Detect OS
detect_os() {
    print_status "🔍 Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/redhat-release ]; then
            OS="redhat"
            print_success "Detected: Red Hat/CentOS/RHEL"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
            print_success "Detected: Ubuntu/Debian"
        else
            OS="linux"
            print_success "Detected: Generic Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected: macOS"
    else
        OS="unknown"
        print_warning "Unknown OS, proceeding with generic Linux setup..."
    fi
}

# Check system requirements
check_requirements() {
    print_status "⚙️ Checking system requirements..."
    
    # Check memory (minimum 4GB recommended)
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$MEMORY_GB" -ge 4 ]; then
        print_success "Memory: ${MEMORY_GB}GB (✅ Good for 200+ users)"
    else
        print_warning "Memory: ${MEMORY_GB}GB (Recommended: 4GB+)"
    fi
    
    # Check disk space (minimum 10GB)
    DISK_GB=$(df / | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [ "$DISK_GB" -ge 10 ]; then
        print_success "Disk space: ${DISK_GB}GB available"
    else
        print_error "Insufficient disk space: ${DISK_GB}GB (Need 10GB+)"
        exit 1
    fi
    
    # Check if ports are available
    for port in 3001 8089 9090 8085; do
        if ss -tuln | grep -q ":$port "; then
            print_warning "Port $port is already in use"
        else
            print_success "Port $port is available"
        fi
    done
}

# Install Docker if not present
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        docker --version
    else
        print_status "📦 Installing Docker..."
        
        if [ "$OS" = "redhat" ]; then
            $SUDO yum update -y
            $SUDO yum install -y yum-utils
            $SUDO yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif [ "$OS" = "debian" ]; then
            $SUDO apt-get update
            $SUDO apt-get install -y ca-certificates curl gnupg
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        elif [ "$OS" = "macos" ]; then
            print_error "Please install Docker Desktop for Mac from https://docker.com/products/docker-desktop"
            exit 1
        fi
        
        $SUDO systemctl start docker
        $SUDO systemctl enable docker
        $SUDO usermod -aG docker $USER
        
        print_success "Docker installed successfully!"
    fi
}

# Install Docker Compose if not present
install_docker_compose() {
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        print_success "Docker Compose is available"
    else
        print_status "📦 Installing Docker Compose..."
        
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        $SUDO curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        $SUDO chmod +x /usr/local/bin/docker-compose
        
        print_success "Docker Compose installed successfully!"
    fi
}

# Install Python and pip if needed
install_python() {
    if command -v python3 &> /dev/null; then
        print_success "Python3 is available"
    else
        print_status "🐍 Installing Python3..."
        
        if [ "$OS" = "redhat" ]; then
            $SUDO yum install -y python3 python3-pip
        elif [ "$OS" = "debian" ]; then
            $SUDO apt-get install -y python3 python3-pip
        fi
        
        print_success "Python3 installed successfully!"
    fi
}

# Create necessary directories
create_directories() {
    print_status "📁 Creating directories..."
    
    mkdir -p data/grafana data/prometheus data/loki logs backups
    chmod 777 data/grafana  # Grafana needs write access
    
    print_success "Directories created"
}

# Generate environment configuration
generate_config() {
    print_status "⚙️ Generating configuration..."
    
    # Create .env file with sensible defaults
    cat > .env << EOF
# 🚀 OBS Stack Configuration
# Auto-generated on $(date)

# Basic Settings
GRAFANA_ADMIN_PASSWORD=admin123
MAX_CONCURRENT_USERS=250
GPU_MONITORING_ENABLED=true

# Retention Policies (days)
LOG_RETENTION_DAYS=30
METRICS_RETENTION_DAYS=90
ARCHIVE_RETENTION_DAYS=365

# Resource Limits
OPSHUB_MEMORY_LIMIT=1g
OPSHUB_CPU_LIMIT=1.0
GRAFANA_MEMORY_LIMIT=512m
PROMETHEUS_MEMORY_LIMIT=1g

# Network Settings
GRAFANA_PORT=3001
PROMETHEUS_PORT=9090
OPSHUB_PORT=8089
CADVISOR_PORT=8085

# Optional: Alert Configuration
# ALERT_EMAIL=admin@yourcompany.com
# SLACK_WEBHOOK_URL=your-slack-webhook-url

# GPU Settings (for p3.24xlarge)
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility
EOF

    print_success "Configuration generated (.env file)"
}

# Start the stack
start_stack() {
    print_status "🚀 Starting OBS Stack services..."
    
    # Pull images first to show progress
    print_status "📥 Pulling Docker images..."
    docker-compose pull
    
    # Start services
    print_status "🔄 Starting services..."
    docker-compose up -d
    
    print_success "All services started!"
}

# Wait for services to be ready
wait_for_services() {
    print_status "⏳ Waiting for services to be ready..."
    
    # Wait for Grafana
    print_status "Waiting for Grafana..."
    for i in {1..30}; do
        if curl -s -f http://localhost:3001/api/health > /dev/null 2>&1; then
            print_success "Grafana is ready!"
            break
        fi
        sleep 2
        echo -n "."
    done
    
    # Wait for Prometheus
    print_status "Waiting for Prometheus..."
    for i in {1..30}; do
        if curl -s -f http://localhost:9090/-/healthy > /dev/null 2>&1; then
            print_success "Prometheus is ready!"
            break
        fi
        sleep 2
        echo -n "."
    done
    
    # Wait for OpsHub
    print_status "Waiting for OpsHub..."
    for i in {1..30}; do
        if curl -s -f http://localhost:8089/health > /dev/null 2>&1; then
            print_success "OpsHub is ready!"
            break
        fi
        sleep 2
        echo -n "."
    done
}

# Install CLI tools
install_cli() {
    print_status "🛠️ Installing CLI tools..."
    
    # Install Python dependencies
    cd opshub
    pip3 install -e . --user
    cd ..
    
    # Create global command
    $SUDO ln -sf "$(pwd)/opshub/docker-logger.sh" /usr/local/bin/docker-logger 2>/dev/null || true
    
    print_success "CLI tools installed! Use 'docker-logger' command"
}

# Run quick health check
health_check() {
    print_status "🏥 Running health check..."
    
    # Check container status
    RUNNING_CONTAINERS=$(docker-compose ps --services --filter "status=running" | wc -l)
    TOTAL_CONTAINERS=$(docker-compose ps --services | wc -l)
    
    if [ "$RUNNING_CONTAINERS" -eq "$TOTAL_CONTAINERS" ]; then
        print_success "All $TOTAL_CONTAINERS containers are running"
    else
        print_warning "$RUNNING_CONTAINERS/$TOTAL_CONTAINERS containers running"
    fi
    
    # Test key endpoints
    if curl -s http://localhost:3001 > /dev/null; then
        print_success "Grafana is accessible"
    else
        print_warning "Grafana may not be ready yet"
    fi
    
    if curl -s http://localhost:8089/health > /dev/null; then
        print_success "OpsHub API is responding"
    else
        print_warning "OpsHub API may not be ready yet"
    fi
}

# Show final instructions
show_success() {
    echo ""
    echo -e "${GREEN}🎉🎉🎉 OBS STACK INSTALLATION COMPLETE! 🎉🎉🎉${NC}"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}📊 ACCESS YOUR MONITORING DASHBOARDS${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}🎛️  Grafana Dashboard:${NC}     http://localhost:3001"
    echo -e "${GREEN}🔧  Prometheus Metrics:${NC}    http://localhost:9090"  
    echo -e "${GREEN}🚀  OpsHub API:${NC}           http://localhost:8089"
    echo -e "${GREEN}📈  cAdvisor:${NC}             http://localhost:8085"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}🛠️  QUICK COMMANDS${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}# View live monitoring${NC}"
    echo -e "${BLUE}docker-logger monitor${NC}"
    echo ""
    echo -e "${GREEN}# Check system status${NC}"
    echo -e "${BLUE}docker-logger status${NC}"
    echo ""
    echo -e "${GREEN}# View active users${NC}"
    echo -e "${BLUE}docker-logger users${NC}"
    echo ""
    echo -e "${GREEN}# Check performance${NC}"
    echo -e "${BLUE}docker-logger performance${NC}"
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}📋 NEXT STEPS FOR PRODUCTION${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Configure alerts and retention:"
    echo -e "   ${BLUE}sudo ./implement-all-steps.sh${NC}"
    echo ""
    echo -e "${GREEN}2.${NC} Update Grafana password (default: admin/admin123)"
    echo ""
    echo -e "${GREEN}3.${NC} Configure email/Slack alerts in .env file"
    echo ""
    echo -e "${GREEN}4.${NC} For 200+ users, ensure adequate resources"
    echo ""
    echo -e "${PURPLE}🚀 Your monitoring stack is ready for 200+ OpenWebUI users!${NC}"
    echo ""
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting automated installation...${NC}"
    echo ""
    
    check_sudo
    detect_os
    check_requirements
    install_docker
    install_docker_compose
    install_python
    create_directories
    generate_config
    start_stack
    wait_for_services
    install_cli
    health_check
    show_success
    
    echo -e "${GREEN}✅ Installation completed in $(date)${NC}"
    echo -e "${YELLOW}💡 Tip: Run 'docker-logger monitor' to see live metrics!${NC}"
}

# Error handling
trap 'echo -e "\n${RED}❌ Installation failed! Check the logs above for details.${NC}"; exit 1' ERR

# Run main installation
main "$@"
