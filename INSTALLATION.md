# 🚀 Complete EC2 Installation Guide - Docker Logger & Observability Stack

**A detailed step-by-step guide to deploy the complete monitoring solution on your RedHat 9 EC2 p3.24xlarge instance in under 30 minutes.**

---

## 📋 Prerequisites Checklist

- [ ] EC2 p3.24xlarge instance running RedHat 9
- [ ] SSH access to the instance
- [ ] Root or sudo privileges
- [ ] At least 50GB free disk space
- [ ] Security group allowing ports: 22 (SSH), 3001 (Grafana), 9090 (Prometheus), 8089 (OpsHub API)

---

## 🎯 Quick Overview

This guide will install:
- ✅ Docker & Docker Compose
- ✅ NVIDIA Container Runtime (for GPU monitoring)
- ✅ Complete observability stack (Loki, Prometheus, Grafana)
- ✅ OpsHub monitoring service
- ✅ `docker-logger` CLI tool
- ✅ Automatic startup on boot
- ✅ User session tracking for OpenWebUI
- ✅ Performance monitoring for all containers

**Total installation time: ~15-30 minutes**

---

## 🔐 Step 1: Connect to Your EC2 Instance

```bash
# Connect via SSH (replace with your instance details)
ssh -i your-key.pem ec2-user@your-instance-ip

# Switch to root (or use sudo for all commands)
sudo su -
```

---

## 🔧 Step 2: System Update and Prerequisites

### 2.1 Update the System
```bash
# Update all packages
dnf update -y

# Install essential tools
dnf install -y curl wget git vim htop unzip
```

### 2.2 Install Python 3.11+ (Required for CLI)
```bash
# Install Python 3.11
dnf install -y python3.11 python3.11-pip python3.11-devel

# Create symlinks for easier access
alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1

# Verify installation
python3 --version  # Should show 3.11+
pip3 --version
```

**Expected output:**
```
Python 3.11.x
pip 23.x.x from /usr/lib/python3.11/site-packages/pip (python 3.11)
```

---

## 🐳 Step 3: Install Docker and Docker Compose

### 3.1 Install Docker
```bash
# Install Docker
dnf install -y docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Add current user to docker group (if not root)
usermod -aG docker $USER

# Verify Docker installation
docker --version
docker info
```

**Expected output:**
```
Docker version 24.x.x, build xxxxx
```

### 3.2 Install Docker Compose
```bash
# Download latest Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
chmod +x /usr/local/bin/docker-compose

# Create symlink for easier access
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

**Expected output:**
```
Docker Compose version v2.x.x
```

---

## 🎮 Step 4: Install NVIDIA Container Runtime (GPU Support)

### 4.1 Add NVIDIA Repository
```bash
# Add NVIDIA container runtime repository
curl -s -L https://nvidia.github.io/nvidia-container-runtime/rhel9.0/nvidia-container-runtime.repo | tee /etc/yum.repos.d/nvidia-container-runtime.repo

# Install NVIDIA container runtime
dnf install -y nvidia-container-runtime
```

### 4.2 Configure Docker for NVIDIA Runtime
```bash
# Create Docker daemon configuration
mkdir -p /etc/docker

cat <<EOF > /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    }
}
EOF

# Restart Docker to apply changes
systemctl restart docker

# Test GPU access
docker run --rm nvidia/cuda:11.0-base nvidia-smi
```

**Expected output:** You should see your GPU information displayed.

---

## 📂 Step 5: Download and Prepare the Observability Stack

### 5.1 Create Installation Directory
```bash
# Create deployment directory
mkdir -p /opt/obs-stack
cd /opt/obs-stack

# Set proper permissions
chown -R $USER:$USER /opt/obs-stack
```

### 5.2 Download the Stack Files

**Option A: If you have the files locally, upload them:**
```bash
# From your local machine, upload the OBS-stack directory
scp -i your-key.pem -r /path/to/OBS-stack/* ec2-user@your-instance-ip:/opt/obs-stack/
```

**Option B: If using Git (recommended):**
```bash
# Clone or download your observability stack
# Replace with your actual repository or file location
cd /opt/obs-stack

# If you have a git repository:
# git clone https://github.com/your-repo/obs-stack.git .

# Or manually create the structure and copy files
```

### 5.3 Verify File Structure
```bash
ls -la /opt/obs-stack
```

**Expected structure:**
```
drwxr-xr-x. docker-compose.yml
drwxr-xr-x. grafana/
drwxr-xr-x. loki/
drwxr-xr-x. opshub/
drwxr-xr-x. prometheus/
drwxr-xr-x. promtail/
-rwxr-xr-x. install.sh
-rwxr-xr-x. setup.sh
-rw-r--r--. README.md
-rw-r--r--. DEPLOYMENT.md
```

---

## 🔧 Step 6: Configure Firewall

### 6.1 Configure System Firewall
```bash
# Start and enable firewall
systemctl start firewalld
systemctl enable firewalld

# Open required ports
firewall-cmd --permanent --add-port=3001/tcp   # Grafana
firewall-cmd --permanent --add-port=9090/tcp   # Prometheus
firewall-cmd --permanent --add-port=8089/tcp   # OpsHub API
firewall-cmd --permanent --add-port=8085/tcp   # cAdvisor
firewall-cmd --permanent --add-port=9400/tcp   # DCGM Exporter

# Reload firewall
firewall-cmd --reload

# Verify rules
firewall-cmd --list-ports
```

### 6.2 Configure AWS Security Group
```bash
# Add these rules to your EC2 Security Group:
# Type: Custom TCP, Port: 3001, Source: Your IP (Grafana)
# Type: Custom TCP, Port: 9090, Source: Your IP (Prometheus)
# Type: Custom TCP, Port: 8089, Source: Your IP (OpsHub API)
```

---

## 🚀 Step 7: Deploy the Observability Stack

### 7.1 Make Scripts Executable
```bash
cd /opt/obs-stack
chmod +x setup.sh install.sh
```

### 7.2 Run the Automated Setup
```bash
# Run the complete setup script
./setup.sh
```

**The setup script will:**
- ✅ Check all prerequisites
- ✅ Create required networks
- ✅ Pull all Docker images
- ✅ Build the OpsHub service
- ✅ Start all containers
- ✅ Install the CLI tool
- ✅ Verify everything is working

### 7.3 Manual Installation (Alternative)
If the setup script fails, you can run steps manually:

```bash
# Create external network
docker network create ai-net

# Start the stack
docker-compose up -d

# Wait for services to start
sleep 30

# Check service status
docker-compose ps
```

**Expected output:**
```
       Name                     Command                State                    Ports
-------------------------------------------------------------------------------------------------
cadvisor                /usr/bin/cadvisor -logtostderr  Up      0.0.0.0:8085->8080/tcp
dcgm-exporter           dcgm-exporter                   Up      0.0.0.0:9400->9400/tcp
grafana                 /run.sh                         Up      0.0.0.0:3001->3000/tcp
loki                    /usr/bin/loki -config.file=/e... Up      0.0.0.0:3100->3100/tcp
node-exporter           /bin/node_exporter --path.ro... Up
opshub                  /app/entrypoint.sh              Up      0.0.0.0:8089->8089/tcp, 0.0.0.0:9188->9188/tcp
prometheus              /bin/prometheus --config.fil... Up      0.0.0.0:9090->9090/tcp
promtail                /usr/bin/promtail -config.fi... Up
```

---

## 🛠️ Step 8: Install the CLI Tool

### 8.1 Install docker-logger CLI
```bash
cd /opt/obs-stack
./install.sh
```

### 8.2 Verify CLI Installation
```bash
# Test the CLI
docker-logger --help
docker-logger status
```

**Expected output:**
```
Usage: docker-logger [OPTIONS] COMMAND [ARGS]...

  Docker Logger - Monitor all your containers

Commands:
  logs         Stream logs from containers with filtering
  status       Show status of all containers
  users        Show OpenWebUI user sessions and activity
  performance  Show system performance metrics
  monitor      Live monitoring dashboard
```

### 8.3 Add to System PATH (if needed)
```bash
# Add to system PATH for all users
echo 'export PATH="$PATH:/root/.local/bin"' >> /etc/profile

# For current session
export PATH="$PATH:/root/.local/bin"
```

---

## 🔄 Step 9: Configure Automatic Startup

### 9.1 Create Systemd Service
```bash
# Copy the service file
cp /opt/obs-stack/obs-stack.service /etc/systemd/system/

# Edit the service file if needed
vim /etc/systemd/system/obs-stack.service

# Make sure WorkingDirectory points to your installation
sed -i 's|/opt/obs-stack|'$(pwd)'|g' /etc/systemd/system/obs-stack.service
```

### 9.2 Enable and Start Service
```bash
# Reload systemd
systemctl daemon-reload

# Enable service to start on boot
systemctl enable obs-stack.service

# Start the service
systemctl start obs-stack.service

# Check service status
systemctl status obs-stack.service
```

---

## ✅ Step 10: Verification and Testing

### 10.1 Verify All Services
```bash
# Check Docker containers
docker-compose ps

# Check service connectivity
curl http://localhost:8089/health         # OpsHub
curl http://localhost:9090/-/healthy      # Prometheus
curl http://localhost:3001/api/health     # Grafana

# Test CLI functionality
docker-logger status
docker-logger performance
```

### 10.2 Access Web Interfaces

Open these URLs in your browser (replace `your-instance-ip` with actual IP):

- **Grafana**: `http://your-instance-ip:3001`
  - Username: `admin`
  - Password: `admin`
  
- **Prometheus**: `http://your-instance-ip:9090`

- **OpsHub API**: `http://your-instance-ip:8089`

- **cAdvisor**: `http://your-instance-ip:8085`

### 10.3 Test Container Discovery
```bash
# The system should automatically discover your existing containers
docker-logger logs all --tail 10

# Check if your containers are being monitored
docker-logger status
```

**You should see all your existing containers:**
- ollama
- openwebui
- nginx-proxy-manager
- keycloak
- postgres instances
- redis
- etc.

---

## 🎯 Step 11: Configure for Your Environment

### 11.1 Optimize for 200+ Users
```bash
# Edit docker-compose.yml for higher resource limits
vim /opt/obs-stack/docker-compose.yml

# Increase retention periods
# Change these environment variables in opshub service:
# OPS_RETENTION_ACTIVE_DAYS: "14"
# OPS_RETENTION_ARCHIVE_DAYS: "90"
# OPS_RETENTION_PURGE_DAYS: "365"
```

### 11.2 Enable OpenWebUI User Tracking
Add labels to your existing OpenWebUI container:

```yaml
# Add these labels to your OpenWebUI container
labels:
  - "opshub.track=true"
  - "opshub.service=openwebui"
```

### 11.3 Restart with New Configuration
```bash
# Restart the stack with new configuration
docker-compose down
docker-compose up -d
```

---

## 📊 Step 12: Start Monitoring

### 12.1 Live Monitoring Dashboard
```bash
# Start the live monitoring dashboard
docker-logger monitor
```

### 12.2 Monitor Your Containers
```bash
# View all logs in real-time
docker-logger logs all --follow

# Monitor specific containers
docker-logger logs openwebui --follow
docker-logger logs ollama --follow

# Check error logs only
docker-logger logs all --level error

# Monitor user sessions
docker-logger users

# Check system performance
docker-logger performance
```

### 12.3 Set Up Grafana Dashboards
1. Open Grafana: `http://your-instance-ip:3001`
2. Login with `admin/admin`
3. Import pre-configured dashboards
4. Configure alerts for critical metrics

---

## 🚨 Troubleshooting Common Issues

### Issue: Docker containers not starting
```bash
# Check Docker service
systemctl status docker

# Check disk space
df -h

# Check Docker logs
docker-compose logs
```

### Issue: GPU metrics not showing
```bash
# Test NVIDIA runtime
docker run --rm --runtime=nvidia nvidia/cuda:11.0-base nvidia-smi

# Check DCGM exporter
docker-compose logs dcgm-exporter

# Verify NVIDIA drivers
nvidia-smi
```

### Issue: CLI not working
```bash
# Check OpsHub service
curl http://localhost:8089/health

# Reinstall CLI
cd /opt/obs-stack && ./install.sh

# Check Python version
python3 --version
```

### Issue: High resource usage
```bash
# Monitor resource usage
docker stats

# Adjust retention settings in docker-compose.yml
# Restart services
docker-compose restart
```

---

## 🔄 Step 13: Maintenance and Backup

### 13.1 Create Backup Script
```bash
cat <<'EOF' > /opt/obs-stack/backup.sh
#!/bin/bash
BACKUP_DIR="/opt/backups/obs-stack"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup configurations
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/obs-stack/

# Backup database
cp /opt/obs-stack/opshub_data/opshub.db $BACKUP_DIR/opshub_$DATE.db

# Keep only last 7 days
find $BACKUP_DIR -mtime +7 -delete
EOF

chmod +x /opt/obs-stack/backup.sh
```

### 13.2 Set Up Cron Jobs
```bash
# Add to crontab
crontab -e

# Add these lines:
# Daily backup at 2 AM
0 2 * * * /opt/obs-stack/backup.sh

# Weekly cleanup at 3 AM Sunday
0 3 * * 0 docker system prune -f
```

---

## 🎉 Success! Your Monitoring Stack is Ready

### 🎯 **What You Can Do Now:**

1. **Monitor all containers**: `docker-logger status`
2. **View real-time logs**: `docker-logger logs all --follow`
3. **Track user sessions**: `docker-logger users`
4. **Monitor performance**: `docker-logger performance`
5. **Live dashboard**: `docker-logger monitor`
6. **Access Grafana**: `http://your-instance-ip:3001`

### 📱 **Quick Commands Reference:**

```bash
# Essential monitoring commands
docker-logger status                    # Container overview
docker-logger logs all --level error   # Error logs only
docker-logger users                     # OpenWebUI user tracking
docker-logger performance              # System metrics
docker-logger monitor                   # Live dashboard

# Service management
systemctl status obs-stack             # Check service status
docker-compose ps                       # Check containers
docker-compose restart opshub          # Restart monitoring service
```

### 🚀 **Next Steps - FULLY IMPLEMENTED:**

**Run this single command to implement ALL next steps automatically:**

```bash
cd /opt/obs-stack
chmod +x implement-all-steps.sh
./implement-all-steps.sh
```

**What this implements:**

1. ✅ **Configure alerts** in Grafana for critical metrics
   - High CPU/Memory/GPU usage alerts
   - Container down notifications
   - User capacity warnings (>180 users)
   - Disk space monitoring
   - Email & Slack notifications

2. ✅ **Set up log retention** policies for your needs
   - 14-day active sessions
   - 365-day error logs
   - 180-day performance metrics
   - Automatic cleanup & archival
   - Optimized for 200+ users

3. ✅ **Create custom dashboards** for your specific use cases
   - Executive Summary Dashboard
   - Detailed p3.24xlarge Monitoring
   - User Analytics (200+ users)
   - Capacity Planning & Forecasting
   - Dashboard folders & permissions

4. ✅ **Monitor the 200+ users** using OpenWebUI analytics
   - Real-time session tracking
   - Model usage per user
   - Behavior pattern analysis
   - User satisfaction metrics
   - Top users identification
   - REST API for user data

5. ✅ **Scale resources** as needed for your workload
   - Automatic scaling at 160+ users
   - Critical alerts at 180+ users
   - Resource threshold monitoring
   - Growth rate prediction
   - Emergency scaling procedures

---

## 📞 **Support and Troubleshooting:**

If you encounter any issues:

1. **Check service status**: `systemctl status obs-stack`
2. **View container logs**: `docker-compose logs [service-name]`
3. **Test connectivity**: `docker-logger status`
4. **Check resources**: `docker stats`
5. **Verify configuration**: Review `docker-compose.yml`

**Your complete Docker monitoring and logging solution is now running! 🚀**

Monitor all your containers, track your 200+ users, and keep your p3.24xlarge instance performing optimally.
