# 🚀 OBS Stack - One-Command Setup Instructions

## 🎯 For Complete Beginners

**Just want to get it running? Copy and paste ONE command!**

### 🐧 **Linux/EC2 (Production)**
```bash
curl -sSL https://raw.githubusercontent.com/Sagura091/OBS-Stack/main/quick-install.sh | bash
```

### 🪟 **Windows 11 (Testing)**
```powershell
iwr -useb https://raw.githubusercontent.com/Sagura091/OBS-Stack/main/quick-install-windows.ps1 | iex
```

**That's it! 🎉** 

The scripts will:
- ✅ Install Docker automatically
- ✅ Set up all services 
- ✅ Create dashboards
- ✅ Configure everything
- ✅ Show you exactly where to go

---

## 🏃‍♂️ Alternative: Super Quick Local Setup

If you already have Docker installed:

```bash
# 1. Download and extract
git clone https://github.com/Sagura091/OBS-Stack.git
cd OBS-Stack

# 2. One command start
./obs start

# 3. Access dashboards
# Grafana: http://localhost:3001 (admin/admin)
```

---

## 📊 What You Get Instantly

| Service | URL | Purpose |
|---------|-----|---------|
| **Grafana** | http://localhost:3001 | 📊 Beautiful dashboards |
| **Prometheus** | http://localhost:9090 | 📈 Metrics collection |
| **OpsHub API** | http://localhost:8089 | 🚀 User monitoring |

---

## 🛠️ Simple Commands

```bash
./obs start     # Start everything
./obs stop      # Stop everything  
./obs status    # Check what's running
./obs logs      # See what's happening
./obs monitor   # Open dashboards
```

---

## 🎯 For Your 200+ User Environment

**Windows Testing First** (recommended):
1. Run the Windows installer above
2. Test with simulated users
3. Verify everything works
4. Then deploy to EC2

**Direct to EC2**:
1. Run the Linux installer above
2. Run `sudo ./implement-all-steps.sh` for production features
3. Access via your EC2 public IP

---

## 🆘 If Something Goes Wrong

```bash
# Check if Docker is running
docker --version

# Restart everything
./obs restart

# Clean start
./obs clean && ./obs start

# Get help
./obs
```

---

## ✨ Advanced Setup (Optional)

Only if you want to customize:

```bash
# Clone repository  
git clone https://github.com/Sagura091/OBS-Stack.git
cd OBS-Stack

# Edit configuration (optional)
vim .env

# Start with all production features
sudo ./implement-all-steps.sh
```

---

**🚀 Goal: Get you monitoring 200+ users in under 5 minutes!**
