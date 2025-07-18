# 🪟 Windows 11 Docker Desktop Development Guide

**Test your complete Docker logging and observability stack on Windows 11 before deploying to EC2 p3.24xlarge RedHat 9**

---

## 🎯 Overview

This guide helps you test the complete observability stack on Windows 11 Docker Desktop, ensuring everything works perfectly before moving to production on your EC2 instance.

**What you'll test:**
- ✅ Complete Docker Compose stack
- ✅ Grafana dashboards and alerts
- ✅ User monitoring for 200+ users simulation
- ✅ Log retention policies
- ✅ Resource scaling (simulated)
- ✅ All CLI tools and APIs

---

## 📋 Prerequisites for Windows 11

### Required Software
- [ ] **Windows 11** (Pro/Enterprise recommended)
- [ ] **Docker Desktop** 4.15+ with WSL2 backend
- [ ] **Python 3.11+** 
- [ ] **PowerShell 7+** (optional, but recommended)
- [ ] **Git for Windows**
- [ ] **VS Code** (recommended for editing)

### System Requirements
- [ ] **8GB RAM minimum** (16GB recommended)
- [ ] **50GB free disk space**
- [ ] **WSL2 enabled**
- [ ] **Hyper-V enabled** (if not using WSL2)

---

## 🔧 Step 1: Setup Windows Environment

### 1.1 Install Docker Desktop
```powershell
# Download from https://www.docker.com/products/docker-desktop/
# Or use winget
winget install Docker.DockerDesktop

# After installation, enable WSL2 backend in Docker Desktop settings
```

### 1.2 Install Python 3.11+
```powershell
# Using winget
winget install Python.Python.3.11

# Or download from python.org
# Verify installation
python --version
pip --version
```

### 1.3 Install Required Tools
```powershell
# Install Git
winget install Git.Git

# Install PowerShell 7 (optional)
winget install Microsoft.PowerShell

# Install VS Code (optional)
winget install Microsoft.VisualStudioCode
```

### 1.4 Configure Docker Desktop
1. Open Docker Desktop
2. Go to **Settings → General**
3. Enable **Use WSL 2 based engine**
4. Go to **Settings → Resources → Advanced**
5. Allocate resources:
   - **Memory:** 8GB (or 50% of your RAM)
   - **CPUs:** 4+ cores
   - **Disk:** 50GB+

---

## 📂 Step 2: Prepare the Project

### 2.1 Setup Development Directory
```powershell
# Create development directory
mkdir C:\dev\obs-stack-test
cd C:\dev\obs-stack-test

# Copy your OBS-stack files here
# You can copy from Downloads\OBS-stack to this directory
```

### 2.2 Windows-Specific File Structure
```
C:\dev\obs-stack-test\
├── docker-compose.yml
├── docker-compose.windows.yml      # Windows overrides
├── setup-windows.ps1               # Windows setup script
├── test-windows.ps1                # Windows testing script
├── simulate-users.ps1              # User simulation script
├── grafana/
├── loki/
├── opshub/
├── prometheus/
├── promtail/
└── docs/
```

---

## 🐳 Step 3: Run the Stack on Windows

### 3.1 Start with Windows Override
```powershell
# Navigate to your project directory
cd C:\dev\obs-stack-test

# Start the stack with Windows-specific settings
docker-compose -f docker-compose.yml -f docker-compose.windows.yml up -d

# Check service status
docker-compose ps
```

### 3.2 Windows-Specific Considerations

**⚠️ Differences from Linux:**
- No GPU monitoring (DCGM won't work)
- Different volume mount paths
- Some system metrics unavailable
- Simulated user load instead of real users

**✅ What still works:**
- All container monitoring
- Grafana dashboards
- Log aggregation
- API endpoints
- Alert testing
- Retention policies

---

## 🧪 Step 4: Testing Strategy

### 4.1 Basic Functionality Test
```powershell
# Test all services are running
docker-compose ps

# Test service endpoints
curl http://localhost:3001/api/health     # Grafana
curl http://localhost:9090/-/healthy      # Prometheus
curl http://localhost:8089/health         # OpsHub
```

### 4.2 User Simulation Testing
```powershell
# Run user simulation script
.\simulate-users.ps1

# This will:
# - Create fake user sessions
# - Generate model usage data
# - Test scaling triggers
# - Validate user analytics
```

### 4.3 Dashboard Testing
1. Open Grafana: `http://localhost:3001` (admin/admin)
2. Check all dashboards load
3. Verify metrics are populating
4. Test alert rules

### 4.4 API Testing
```powershell
# Test user monitoring APIs
curl http://localhost:8089/api/users/active
curl http://localhost:8089/api/users/analytics
curl http://localhost:8089/api/users/top-users

# Test CLI tools (after installation)
docker-logger status
docker-logger users
docker-logger performance
```

---

## 🚀 Step 5: Windows Setup Scripts

### 5.1 Automated Windows Setup
Run the automated setup:
```powershell
# Make sure Docker Desktop is running
# Run the Windows setup script
.\setup-windows.ps1
```

### 5.2 What the Setup Script Does
- ✅ Checks all prerequisites
- ✅ Creates Windows-compatible configurations
- ✅ Starts all services
- ✅ Installs CLI tools
- ✅ Runs initial tests
- ✅ Sets up user simulation

---

## 🔍 Step 6: Validation Checklist

### 6.1 Service Health
- [ ] Grafana accessible at http://localhost:3001
- [ ] Prometheus accessible at http://localhost:9090
- [ ] OpsHub API responding at http://localhost:8089
- [ ] All containers running (docker-compose ps)

### 6.2 Functionality Tests
- [ ] Dashboards showing data
- [ ] User simulation generating metrics
- [ ] Alerts can be triggered
- [ ] CLI tools working
- [ ] Log retention policies active

### 6.3 Performance Tests
- [ ] System handles simulated load
- [ ] Response times acceptable
- [ ] Memory usage reasonable
- [ ] No container crashes

---

## 📊 Step 7: User Simulation

### 7.1 Simulate 200+ Users
The Windows environment will simulate user activity:
```powershell
# Start user simulation
.\simulate-users.ps1 -UserCount 50 -Duration 30

# This creates:
# - Fake user sessions
# - Model usage patterns
# - Realistic activity levels
# - Scaling triggers
```

### 7.2 Monitor Simulation
```powershell
# Watch user metrics
docker-logger users

# Monitor performance
docker-logger performance

# Check scaling logs
docker-compose logs opshub | findstr "scaling"
```

---

## 🔄 Step 8: Migration Preparation

### 8.1 Export Configurations
Once everything works on Windows:
```powershell
# Export tested configurations
.\export-configs.ps1

# This will create:
# - Linux-compatible docker-compose.yml
# - Production-ready configurations
# - Migration scripts
```

### 8.2 Migration Checklist
- [ ] All features tested on Windows
- [ ] Configurations exported for Linux
- [ ] Performance benchmarks documented
- [ ] Known issues/limitations noted
- [ ] Scaling thresholds validated

---

## 🚀 Step 9: Deploy to Production

### 9.1 Transfer to EC2
```bash
# On your EC2 p3.24xlarge instance
scp -r ./obs-stack-production ec2-user@your-instance:/opt/

# Run the production installation
cd /opt/obs-stack-production
./install.sh
```

### 9.2 Production Differences
**Windows Testing → Linux Production:**
- Add GPU monitoring (DCGM)
- Enable real user tracking
- Increase resource limits
- Configure real alerts
- Set production retention policies

---

## 🎯 Benefits of Windows Testing

### ✅ **Confidence**
- Test all components before production
- Validate configurations work
- Debug issues in safe environment

### ✅ **Speed**
- Faster iteration on Windows
- No EC2 costs during development
- Instant restarts and testing

### ✅ **Validation**
- Ensure dashboards are correct
- Test user analytics logic
- Validate alert thresholds

---

## 🔧 Troubleshooting Windows Issues

### Common Windows Problems

**Docker Desktop Issues:**
```powershell
# Restart Docker Desktop
Stop-Service docker
Start-Service docker

# Check WSL2 integration
wsl --list --verbose
```

**Volume Mount Issues:**
```powershell
# Use Windows paths in docker-compose.windows.yml
# Convert /path/to/file to C:\path\to\file
```

**Port Conflicts:**
```powershell
# Check what's using ports
netstat -ano | findstr :3001
netstat -ano | findstr :9090
```

**Python/CLI Issues:**
```powershell
# Use Windows Python paths
# Install in user directory
pip install --user -r requirements.txt
```

---

## 🎉 Success! Windows Testing Complete

Once you've successfully tested on Windows 11:

✅ **All components verified working**
✅ **Dashboards and alerts tested**
✅ **User simulation successful**
✅ **CLI tools functional**
✅ **Ready for production deployment**

**Your observability stack is now tested and ready to deploy to your EC2 p3.24xlarge instance with confidence! 🚀**

---

## 📞 Next Steps

1. **Complete Windows testing** using this guide
2. **Export production configurations** 
3. **Deploy to EC2** using the main installation guide
4. **Enable GPU monitoring** on production
5. **Configure real user tracking** for 200+ users
6. **Set up production alerts** and monitoring

**You'll have a fully tested, production-ready monitoring solution! 🎯**
