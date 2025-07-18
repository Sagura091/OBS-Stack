# RedHat 9 EC2 Deployment Guide

## Prerequisites for p3.24xlarge Instance

### 1. Install Docker and Docker Compose
```bash
# Update system
sudo dnf update -y

# Install Docker
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 2. Install NVIDIA Container Runtime (for GPU support)
```bash
# Add NVIDIA repository
curl -s -L https://nvidia.github.io/nvidia-container-runtime/rhel9.0/nvidia-container-runtime.repo | sudo tee /etc/yum.repos.d/nvidia-container-runtime.repo

# Install NVIDIA container runtime
sudo dnf install -y nvidia-container-runtime

# Configure Docker to use NVIDIA runtime
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF

# Restart Docker
sudo systemctl restart docker

# Test GPU access
docker run --rm nvidia/cuda:11.0-base nvidia-smi
```

### 3. Install Python 3.11+ (for CLI tool)
```bash
# Install Python 3.11
sudo dnf install -y python3.11 python3.11-pip python3.11-devel

# Create symlinks if needed
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
```

## Deployment Steps

### 1. Deploy the Observability Stack
```bash
# Create deployment directory
sudo mkdir -p /opt/obs-stack
cd /opt/obs-stack

# Copy your observability stack files here
# (upload via scp, git clone, etc.)

# Make scripts executable
chmod +x setup.sh install.sh

# Run the setup script
sudo ./setup.sh
```

### 2. Install as System Service
```bash
# Copy service file
sudo cp obs-stack.service /etc/systemd/system/

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable obs-stack.service
sudo systemctl start obs-stack.service

# Check status
sudo systemctl status obs-stack.service
```

### 3. Configure Firewall
```bash
# Open required ports
sudo firewall-cmd --permanent --add-port=3001/tcp  # Grafana
sudo firewall-cmd --permanent --add-port=9090/tcp  # Prometheus
sudo firewall-cmd --permanent --add-port=8089/tcp  # OpsHub API
sudo firewall-cmd --reload

# Or open all ports for internal network (adjust as needed)
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='10.0.0.0/8' accept"
sudo firewall-cmd --reload
```

### 4. Install CLI Tool System-wide
```bash
# Install CLI for all users
cd /opt/obs-stack
sudo ./install.sh

# Or install for specific user
su - your-user
cd /opt/obs-stack
./install.sh
```

## Configuration for 200+ Users

### 1. Optimize Resource Limits
Edit `/opt/obs-stack/docker-compose.yml`:

```yaml
services:
  opshub:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
        reservations:
          memory: 2G
          cpus: '1.0'

  loki:
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '2.0'

  prometheus:
    deploy:
      resources:
        limits:
          memory: 16G
          cpus: '4.0'

  grafana:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### 2. Increase Retention for High Volume
```yaml
environment:
  OPS_RETENTION_ACTIVE_DAYS: "14"     # 2 weeks active
  OPS_RETENTION_ARCHIVE_DAYS: "90"    # 3 months archive
  OPS_RETENTION_PURGE_DAYS: "365"     # 1 year total
```

### 3. Configure Log Rotation
```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/obs-stack <<EOF
/opt/obs-stack/opshub_data/logs/*/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
```

## Monitoring Your Existing Containers

The system will automatically discover and monitor all your containers:
- ollama
- openwebui
- nginx-proxy-manager
- keycloak
- postgres instances
- redis
- and all others

### OpenWebUI User Tracking

To enable user session tracking, add this to your OpenWebUI container:

```yaml
# In your existing OpenWebUI docker-compose
openwebui:
  # ... existing config ...
  labels:
    - "opshub.track=true"
    - "opshub.service=openwebui"
  logging:
    driver: "json-file"
    options:
      max-size: "100m"
      max-file: "3"
```

## Performance Optimization

### 1. SSD Storage for Logs
```bash
# Mount fast storage for logs
sudo mkdir -p /opt/obs-stack/data
# Mount your fastest SSD here

# Update docker-compose.yml volume
volumes:
  - /opt/obs-stack/data:/data
```

### 2. Database Optimization
For high load, consider PostgreSQL instead of SQLite:

```yaml
postgres:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: opshub
    POSTGRES_USER: opshub
    POSTGRES_PASSWORD: secure_password
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

### 3. Network Optimization
```bash
# Increase network buffer sizes
echo 'net.core.rmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Security Considerations

### 1. Access Control
```bash
# Create dedicated user for monitoring
sudo useradd -r -s /bin/false opshub
sudo usermod -aG docker opshub

# Set proper permissions
sudo chown -R opshub:opshub /opt/obs-stack/data
sudo chmod 750 /opt/obs-stack/data
```

### 2. Secure Web Interfaces
Add authentication to Grafana and Prometheus:

```yaml
grafana:
  environment:
    GF_SECURITY_ADMIN_USER: admin
    GF_SECURITY_ADMIN_PASSWORD: your_secure_password
    GF_USERS_ALLOW_SIGN_UP: "false"
```

### 3. Network Security
```bash
# Restrict external access (internal monitoring only)
sudo firewall-cmd --permanent --remove-port=3001/tcp
sudo firewall-cmd --permanent --remove-port=9090/tcp
sudo firewall-cmd --reload

# Access via SSH tunnel instead:
# ssh -L 3001:localhost:3001 user@your-server
```

## Maintenance Tasks

### 1. Daily Maintenance Script
```bash
#!/bin/bash
# /opt/obs-stack/maintenance.sh

# Clean up old logs
find /opt/obs-stack/data/logs -name "*.log" -mtime +30 -delete

# Optimize database
sqlite3 /opt/obs-stack/data/opshub.db "VACUUM;"

# Check disk usage
df -h /opt/obs-stack/data

# Restart services if needed
systemctl is-active obs-stack.service || systemctl restart obs-stack.service
```

Add to cron:
```bash
sudo crontab -e
# Add: 0 2 * * * /opt/obs-stack/maintenance.sh
```

### 2. Backup Script
```bash
#!/bin/bash
# /opt/obs-stack/backup.sh

BACKUP_DIR="/opt/backups/obs-stack"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configurations
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
  /opt/obs-stack/docker-compose.yml \
  /opt/obs-stack/prometheus/ \
  /opt/obs-stack/grafana/ \
  /opt/obs-stack/loki/

# Backup database
cp /opt/obs-stack/data/opshub.db $BACKUP_DIR/opshub_$DATE.db

# Keep only last 7 days
find $BACKUP_DIR -mtime +7 -delete
```

## Troubleshooting

### Common Issues

1. **GPU metrics not showing**
   ```bash
   # Check NVIDIA runtime
   docker run --rm --runtime=nvidia nvidia/cuda:11.0-base nvidia-smi
   
   # Check DCGM exporter logs
   docker-compose logs dcgm-exporter
   ```

2. **High memory usage**
   ```bash
   # Check container memory usage
   docker stats
   
   # Reduce retention periods
   # Edit OPS_RETENTION_* in docker-compose.yml
   ```

3. **Service not starting**
   ```bash
   # Check service status
   sudo systemctl status obs-stack.service
   
   # Check Docker logs
   docker-compose logs
   ```

4. **CLI not working**
   ```bash
   # Check OpsHub connectivity
   curl http://localhost:8089/health
   
   # Reinstall CLI
   cd /opt/obs-stack && sudo ./install.sh
   ```

## Support Commands

```bash
# Quick status check
docker-logger status

# View system performance
docker-logger performance

# Monitor user sessions
docker-logger users

# Live monitoring
docker-logger monitor

# Check all error logs
docker-logger logs all --level error --tail 100

# Follow specific container logs
docker-logger logs openwebui --follow
```

Your observability stack is now ready to handle 200+ users with comprehensive monitoring! 🚀
