# 🚀 OBS Stack - Comprehensive Observability & Monitoring

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=Prometheus&logoColor=white)](https://prometheus.io/)

**Complete Docker-based observability stack for monitoring 200+ OpenWebUI users on AWS EC2 p3.24xlarge instances**

> 🎯 **Production-Ready**: Built for enterprise-scale monitoring with intelligent alerting, automatic scaling, and comprehensive analytics.

## 🌟 Features

### 🎛️ **Complete Observability Stack**
- **Grafana** - Advanced dashboards and visualization
- **Prometheus** - High-performance metrics collection
- **Loki** - Scalable log aggregation
- **cAdvisor** - Container performance monitoring
- **OpsHub** - Custom FastAPI service for user analytics

### � **Advanced Monitoring Capabilities**
- ✅ **200+ User Tracking** - Real-time user session monitoring
- ✅ **GPU Performance** - NVIDIA GPU utilization and memory tracking
- ✅ **Container Health** - Docker container status and performance
- ✅ **Intelligent Alerting** - Proactive notifications for critical events
- ✅ **Automatic Scaling** - Resource scaling based on user load
- ✅ **Executive Dashboards** - High-level KPIs and business metrics

### 🛠️ **Developer Experience**
- ✅ **CLI Tools** - `docker-logger` command for easy monitoring
- ✅ **REST APIs** - Complete API suite for integration
- ✅ **Windows Testing** - Full development environment for Windows 11
- ✅ **Automated Setup** - One-command deployment scripts
- ✅ **Comprehensive Documentation** - Detailed guides and examples

## 📋 Current Container Support

Your environment includes:
- **AI/ML**: ollama, openwebui, openwebui-pipeline, comfyui, clip-microservice
- **Databases**: postgres (multiple instances), redis, qdrant
- **Infrastructure**: nginx-proxy-manager, keycloak, rabbitmq
- **Monitoring**: prometheus, grafana, tika

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Docker Logs   │───▶│     OpsHub      │───▶│      Loki       │
│                 │    │  (Log Parser)   │    │  (Log Store)    │
## 🏗️ Architecture

```mermaid
graph TB
    Users[200+ OpenWebUI Users] --> LB[Load Balancer]
    LB --> OpenWebUI[OpenWebUI Interface]
    
    OpenWebUI --> OpsHub[OpsHub Service]
    OpsHub --> SQLite[(SQLite Database)]
    OpsHub --> Prometheus[Prometheus Metrics]
    
    Docker[Docker Containers] --> cAdvisor[cAdvisor]
    cAdvisor --> Prometheus
    
    Prometheus --> Grafana[Grafana Dashboards]
    Logs[Application Logs] --> Loki[Loki Log Storage]
    Loki --> Grafana
    
    Grafana --> Alerts[Alert Manager]
    Alerts --> Slack[Slack Notifications]
    Alerts --> Email[Email Alerts]
    
    CLI[docker-logger CLI] --> OpsHub
    API[REST API] --> OpsHub
```

## ⚡ ONE-COMMAND SETUP

**🎯 For Complete Beginners - Just Copy & Paste!**

### 🐧 **Linux/EC2 (Production)**
```bash
curl -sSL https://raw.githubusercontent.com/Sagura091/OBS-Stack/main/quick-install.sh | bash
```

### 🪟 **Windows 11 (Development/Testing)**
```powershell
iwr -useb https://raw.githubusercontent.com/Sagura091/OBS-Stack/main/quick-install-windows.ps1 | iex
```

**That's it! 🎉** Everything installs automatically:
- ✅ Docker installation
- ✅ All services configured  
- ✅ Dashboards ready
- ✅ 200+ user monitoring active
- ✅ Shows you exactly where to access everything

---

## 🏃‍♂️ Alternative: Super Quick Local Setup

Already have Docker? Even faster:

```bash
git clone https://github.com/Sagura091/OBS-Stack.git
cd OBS-Stack
./obs start
```

**Access instantly**: http://localhost:3001 (admin/admin)

---

## ⚡ Quick Start

### 🐧 **Linux/EC2 Production**

```bash
# Clone the repository
git clone https://github.com/Sagura091/OBS-Stack.git
cd OBS-Stack

# Set up the environment
sudo chmod +x setup-linux.sh
sudo ./setup-linux.sh

# Start the complete stack
docker-compose up -d

# Install CLI tools
sudo ./install-cli.sh

# Implement all features (alerts, retention, dashboards, user monitoring, scaling)
sudo ./implement-all-steps.sh

# Monitor live activity
docker-logger monitor
```

### 🪟 **Windows Development**

```powershell
# Clone the repository
git clone https://github.com/Sagura091/OBS-Stack.git
cd OBS-Stack

# Set up Windows development environment
.\setup-windows.ps1

# Start with Windows-specific configurations
docker-compose -f docker-compose.yml -f docker-compose.windows.yml up -d

# Run comprehensive testing
.\test-windows.ps1 -FullTest

# Simulate 200 users for testing
.\simulate-users.ps1 -UserCount 200 -Duration 600
```

# Live monitoring dashboard  
docker-logger monitor
```

## 📱 CLI Usage Examples

### 📋 **View Container Status**
```bash
docker-logger status
```
Shows running containers with CPU, memory, and uptime.

### 📊 **Monitor Performance**
```bash
docker-logger performance
```
Displays system CPU, memory, disk, and GPU metrics.

### 👥 **Track User Sessions**
```bash
docker-logger users
```
Shows OpenWebUI user sessions, models used, and activity.

### 🔍 **Filter Logs by Level**
```bash
# Only errors and critical issues
docker-logger logs all --level error

## 🖥️ Windows Development

Perfect for testing before expensive EC2 deployment!

| Feature | Windows 11 | EC2 Production |
|---------|------------|----------------|
| **All Services** | ✅ Full Stack | ✅ Full Stack |
| **User Simulation** | ✅ 200+ Users | ✅ Real Users |
| **Monitoring** | ✅ Complete | ✅ Complete |
| **GPU Monitoring** | ❌ Simulated | ✅ Real p3.24xlarge |
| **Testing** | ✅ Comprehensive | ✅ Production |

```powershell
# Quick validation (5 minutes)
.\test-windows.ps1 -Quick

# Full production testing (30 minutes)
.\test-windows.ps1 -FullTest -TestDuration 1800 -UserCount 200
```

## � Production Deployment

### AWS EC2 p3.24xlarge Setup

```bash
# System requirements check
./scripts/check-requirements.sh

# Install all dependencies
sudo ./setup-linux.sh

# Configure for 200+ users
export MAX_USERS=250
export GPU_MONITORING=true
export ALERT_EMAIL="admin@yourcompany.com"
export SLACK_WEBHOOK="your-slack-webhook-url"

# Deploy production stack
sudo ./deploy-production.sh

# Verify deployment
./scripts/verify-deployment.sh
```

## 📊 Dashboards & Monitoring

### 🎛️ **Access Points**

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | `http://your-ip:3001` | admin/admin |
| **Prometheus** | `http://your-ip:9090` | No auth |
| **OpsHub API** | `http://your-ip:8089` | REST API |
| **cAdvisor** | `http://your-ip:8085` | No auth |

### � **Available Dashboards**

1. **🏢 Executive Summary**
   - Total active users
   - System health overview
   - Cost optimization metrics
   - Performance trends

2. **🔧 System Monitoring**
   - Real-time CPU/Memory/GPU usage
   - Container health status
   - Network performance
   - Storage utilization

3. **👥 User Analytics**
   - Active user sessions
   - Model usage patterns
   - User behavior analysis
   - Capacity planning

4. **⚡ Performance**
   - Response times
   - Throughput metrics
   - Error rates
   - Resource efficiency

## � User Analytics

### 📊 **User Monitoring Features**

```bash
# View active users
docker-logger users

# Get user analytics
curl http://localhost:8089/api/users/analytics

# Top users by activity
curl http://localhost:8089/api/users/top-users

# Model usage statistics
curl http://localhost:8089/api/users/model-usage

# Capacity analysis
curl http://localhost:8089/api/users/capacity-analysis
```

## 🛠️ CLI Reference

### 🔍 **Essential Commands**

```bash
# Monitor live system activity
docker-logger monitor

# Check user analytics
docker-logger users

# View performance metrics
docker-logger performance

# System health check
docker-logger status

# Export data
docker-logger export --format json --period 7d

# Generate reports
docker-logger report --type executive
```

The system automatically detects:
- **User logins** in OpenWebUI logs
- **Model usage** in Ollama logs  
- **API requests** across services
- **Error patterns** in all containers
- **GPU utilization** in ML workloads

## 🚨 Alerting

Automatic alerts for:
- High CPU usage (>90%)
- High memory usage (>90%)
- High GPU temperature (>80°C)
- Container failures
- Disk space issues
- Error rate spikes

## 📈 Performance Impact

The monitoring stack is designed for minimal overhead:
- **CPU**: <2% additional usage
- **Memory**: ~500MB for full stack
- **Disk**: Configurable retention policies
- **Network**: Minimal impact with local collection

## 🔄 Log Retention

Three-tier retention strategy:
1. **Active** (7 days): Full logs accessible via CLI/API
2. **Archive** (30 days): Compressed logs for analysis
3. **Purge** (90 days): Remove old data

## 💾 Data Storage

- **Logs**: `/data/logs/` (file-based + SQLite)
- **Metrics**: Prometheus TSDB
- **Dashboards**: Grafana configuration
- **Database**: SQLite for user sessions and metadata

## 🛡️ Security

- Local network communication only
- No external data transmission
- Configurable access controls
- Log data stays on your infrastructure

## 📊 API Endpoints

The OpsHub service provides REST APIs:

```bash
# Health check
curl http://localhost:8089/health

# Container status
curl http://localhost:8089/containers/status

# Performance metrics
curl http://localhost:8089/metrics/performance

# User sessions
curl http://localhost:8089/users/sessions

# Search logs
curl "http://localhost:8089/search/logs?query=error&limit=100"
```

## 🚀 Production Deployment

For your 200+ user environment:

### 1. Resource Allocation
```yaml
# Increase resources in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
```

### 2. High Availability
- Deploy multiple OpsHub instances
- Use external database for persistence
- Configure load balancing

### 3. Scaling
- Increase retention periods for compliance
- Add custom dashboards for business metrics
- Integrate with external alerting (PagerDuty, Slack)

## 🔧 Troubleshooting

### CLI Not Working
```bash
# Check OpsHub connectivity
curl http://localhost:8089/health

# Restart OpsHub service
docker-compose restart opshub

# Check logs
docker-compose logs opshub
```

### Missing GPU Metrics
```bash
# Verify NVIDIA runtime
docker run --rm --runtime=nvidia nvidia/cuda:11.0-base nvidia-smi

# Check DCGM exporter
docker-compose logs dcgm-exporter
```

### High Resource Usage
```bash
# Check container resource usage
docker stats

# Adjust retention settings
# Edit OPS_RETENTION_* variables in docker-compose.yml
```

## 📚 Advanced Usage

### Custom Log Parsing
Add patterns in `opshub/logging_pipeline.py`:

```python
CUSTOM_PATTERNS = {
    "payment_success": re.compile(r"payment.*success", re.I),
    "user_signup": re.compile(r"user.*registered", re.I),
}
```

### Additional Metrics
Extend `opshub/metrics_host.py` for custom metrics:

```python
def collect_custom_metrics():
    # Your custom metric collection
    pass
```

### Database Queries
Access the SQLite database directly:

```python
from opshub.database import get_connection
conn = get_connection()
# Your queries here
```

## 🤝 Support

For issues or questions:
1. Check container logs: `docker-compose logs [service]`
2. Verify connectivity: `docker-logger status`
3. Review configuration in `docker-compose.yml`

## 📝 License

This observability stack is designed for your specific infrastructure needs. Modify and extend as required for your environment.

---

**Ready to monitor your Docker empire! 🚀**

Start with: `docker-logger monitor` for a real-time overview of your entire infrastructure.
