# 🔧 OpsHub API Guide - Your Custom Monitoring Microservice

**OpsHub is the intelligent heart of your Docker monitoring system, providing custom APIs, user tracking, and advanced log analysis tailored specifically for your environment.**

---

## 🎯 What is OpsHub?

OpsHub is a custom-built FastAPI microservice that:
- **Aggregates data** from all monitoring sources (Docker, system, GPU)
- **Tracks user sessions** specifically for OpenWebUI and Ollama usage
- **Provides REST APIs** for easy integration with your applications
- **Processes logs intelligently** with pattern recognition and categorization
- **Offers real-time data** through WebSocket connections
- **Stores structured data** in SQLite for quick queries and analytics

## 🌐 Accessing OpsHub API

**URL**: `http://your-instance-ip:8089`

### API Documentation
- **Interactive Docs**: `http://your-instance-ip:8089/docs` (Swagger UI)
- **ReDoc**: `http://your-instance-ip:8089/redoc` (Alternative documentation)
- **OpenAPI Schema**: `http://your-instance-ip:8089/openapi.json`

---

## 📊 Core API Endpoints

### 1. **Health & Status Endpoints**

#### Health Check
```bash
GET /health
curl http://your-instance-ip:8089/health
```
**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Metrics Endpoint (Prometheus Format)
```bash
GET /metrics
curl http://your-instance-ip:8089/metrics
```
**Response:** Prometheus metrics format for scraping

---

### 2. **Container Management Endpoints**

#### Get All Container Status
```bash
GET /containers/status
curl http://your-instance-ip:8089/containers/status
```
**Response:**
```json
[
  {
    "name": "openwebui",
    "status": "running",
    "image": "ghcr.io/open-webui/open-webui:cuda",
    "created": "2024-01-15T08:00:00Z",
    "cpu_percent": "15.2",
    "memory_usage": "1.2 GB (8.5%)",
    "network_io": "RX: 45.2 MB, TX: 12.8 MB",
    "uptime": "2d 4h 30m"
  },
  {
    "name": "ollama",
    "status": "running",
    "image": "ollama/ollama:latest",
    "created": "2024-01-15T08:00:00Z",
    "cpu_percent": "45.8",
    "memory_usage": "8.4 GB (28.3%)",
    "network_io": "RX: 128.5 MB, TX: 67.2 MB",
    "uptime": "2d 4h 30m"
  }
]
```

#### Get Specific Container Status
```bash
GET /containers/{container_name}/status
curl http://your-instance-ip:8089/containers/ollama/status
```

---

### 3. **Log Management Endpoints**

#### Get Container Logs
```bash
GET /logs/{container}?level={level}&tail={count}&follow={boolean}
curl http://your-instance-ip:8089/logs/all?level=error&tail=100
```

**Parameters:**
- `container`: Container name or "all" for all containers
- `level`: info, warning, error, success, critical, all (default: all)
- `tail`: Number of lines to return (default: 100)
- `follow`: Stream logs in real-time (default: false)

**Response:**
```json
{
  "logs": [
    {
      "timestamp": "2024-01-15T10:25:30Z",
      "container": "openwebui",
      "level": "ERROR",
      "message": "Failed to connect to ollama service",
      "source": "docker_logs"
    }
  ]
}
```

#### Search Logs
```bash
GET /search/logs?query={text}&container={name}&level={level}&start_time={iso}&end_time={iso}&limit={count}
curl "http://your-instance-ip:8089/search/logs?query=authentication&level=error&limit=50"
```

**Response:**
```json
{
  "results": [
    {
      "timestamp": "2024-01-15T10:20:15Z",
      "container": "keycloak",
      "level": "ERROR",
      "message": "Authentication failed for user: john.doe",
      "metadata": {
        "user": "john.doe",
        "ip": "192.168.1.100"
      }
    }
  ],
  "count": 1
}
```

---

### 4. **User Session Tracking Endpoints**

#### Get User Sessions
```bash
GET /users/sessions?active_only={boolean}&hours={number}
curl http://your-instance-ip:8089/users/sessions?active_only=true&hours=24
```

**Response:**
```json
[
  {
    "username": "john.doe",
    "model": "llama2:7b",
    "session_id": "sess_abc123",
    "started_at": "2024-01-15T09:00:00Z",
    "last_activity": "2024-01-15T10:28:45Z",
    "request_count": 15,
    "ip_address": "192.168.1.100",
    "status": "active"
  },
  {
    "username": "jane.smith",
    "model": "codellama:13b",
    "session_id": "sess_def456",
    "started_at": "2024-01-15T08:30:00Z",
    "last_activity": "2024-01-15T10:25:12Z",
    "request_count": 8,
    "ip_address": "192.168.1.101",
    "status": "active"
  }
]
```

#### Track User Session Activity
```bash
POST /users/session
curl -X POST http://your-instance-ip:8089/users/session \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john.doe",
    "model": "llama2:7b",
    "action": "login",
    "session_id": "sess_abc123",
    "ip_address": "192.168.1.100"
  }'
```

**Response:**
```json
{
  "status": "recorded"
}
```

---

### 5. **Performance Metrics Endpoints**

#### Get System Performance
```bash
GET /metrics/performance
curl http://your-instance-ip:8089/metrics/performance
```

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "cpu_percent": 45.2,
  "memory_percent": 62.8,
  "disk_percent": 78.5,
  "load_avg": [2.1, 1.8, 1.6],
  "gpus": [
    {
      "index": 0,
      "name": "Tesla V100-SXM2-32GB",
      "utilization": 85.3,
      "memory_utilization": 76.2,
      "memory_used": 24576,
      "memory_total": 32768,
      "memory_percent": 75.0,
      "temperature": 78,
      "power_draw": 245.5,
      "graphics_clock": 1380,
      "memory_clock": 877
    }
  ]
}
```

#### Get Historical Performance Data
```bash
GET /metrics/performance/history?hours={number}&metric={name}
curl "http://your-instance-ip:8089/metrics/performance/history?hours=24&metric=cpu_percent"
```

---

### 6. **Analytics Endpoints**

#### User Analytics Dashboard Data
```bash
GET /analytics/users?period={hours}
curl http://your-instance-ip:8089/analytics/users?period=24
```

**Response:**
```json
{
  "period": "24h",
  "total_users": 45,
  "active_users": 23,
  "peak_concurrent": 15,
  "total_sessions": 78,
  "average_session_duration": 2340,
  "top_models": [
    {
      "model": "llama2:7b",
      "requests": 156,
      "users": 18
    },
    {
      "model": "codellama:13b", 
      "requests": 89,
      "users": 12
    }
  ],
  "hourly_activity": [
    {"hour": "00", "users": 2, "requests": 8},
    {"hour": "01", "users": 1, "requests": 3}
  ]
}
```

#### Model Usage Analytics
```bash
GET /analytics/models?period={hours}
curl http://your-instance-ip:8089/analytics/models?period=168
```

**Response:**
```json
{
  "period": "7d",
  "models": [
    {
      "name": "llama2:7b",
      "total_requests": 1250,
      "unique_users": 67,
      "avg_response_time": 2.3,
      "success_rate": 97.2,
      "peak_usage": "2024-01-15T14:00:00Z"
    }
  ]
}
```

---

### 7. **Alert Management Endpoints**

#### Get Active Alerts
```bash
GET /alerts?severity={level}&resolved={boolean}&hours={number}
curl http://your-instance-ip:8089/alerts?severity=critical&resolved=false
```

**Response:**
```json
[
  {
    "id": 123,
    "alert_type": "gpu_high_temperature",
    "severity": "critical",
    "message": "GPU 0 temperature is 87°C",
    "container_name": "gpu_0",
    "metric_value": 87.0,
    "threshold_value": 85.0,
    "timestamp": "2024-01-15T10:25:00Z",
    "resolved": false
  }
]
```

#### Create Custom Alert
```bash
POST /alerts
curl -X POST http://your-instance-ip:8089/alerts \
  -H "Content-Type: application/json" \
  -d '{
    "alert_type": "custom_threshold",
    "severity": "warning",
    "message": "Custom alert triggered",
    "container_name": "openwebui",
    "metric_value": 95.0,
    "threshold_value": 90.0
  }'
```

---

## 🔧 Advanced Features

### 1. **WebSocket Real-time Data**

#### Connect to Real-time Logs
```javascript
const ws = new WebSocket('ws://your-instance-ip:8089/ws/logs');
ws.onmessage = function(event) {
  const logEntry = JSON.parse(event.data);
  console.log(`[${logEntry.level}] ${logEntry.container}: ${logEntry.message}`);
};
```

#### Connect to Real-time Metrics
```javascript
const ws = new WebSocket('ws://your-instance-ip:8089/ws/metrics');
ws.onmessage = function(event) {
  const metrics = JSON.parse(event.data);
  updateDashboard(metrics);
};
```

### 2. **Custom Integration Examples**

#### Monitor Specific User Activity
```python
import requests

# Get current user sessions
response = requests.get('http://your-instance-ip:8089/users/sessions?active_only=true')
sessions = response.json()

# Filter for specific users
vip_users = [s for s in sessions if s['username'] in ['admin', 'john.doe']]

# Track model usage
for session in vip_users:
    print(f"{session['username']} using {session['model']} - {session['request_count']} requests")
```

#### Custom Alert Integration
```python
import requests

# Check for high resource usage
response = requests.get('http://your-instance-ip:8089/metrics/performance')
metrics = response.json()

if metrics['cpu_percent'] > 90:
    # Send custom alert
    alert_data = {
        'alert_type': 'custom_cpu_high',
        'severity': 'critical',
        'message': f'CPU usage is {metrics["cpu_percent"]}%',
        'metric_value': metrics['cpu_percent'],
        'threshold_value': 90.0
    }
    requests.post('http://your-instance-ip:8089/alerts', json=alert_data)
```

### 3. **Bulk Operations**

#### Export User Activity Report
```bash
# Get comprehensive user report
curl "http://your-instance-ip:8089/analytics/users?period=168" > weekly_user_report.json

# Get all error logs for analysis
curl "http://your-instance-ip:8089/search/logs?level=error&limit=10000" > error_analysis.json
```

#### Batch User Session Tracking
```python
import requests

# Track multiple user actions
session_data = [
    {'username': 'user1', 'model': 'llama2:7b', 'action': 'request'},
    {'username': 'user2', 'model': 'codellama:13b', 'action': 'request'},
    {'username': 'user3', 'model': 'llama2:7b', 'action': 'login'}
]

for session in session_data:
    requests.post('http://your-instance-ip:8089/users/session', json=session)
```

---

## 🔍 Database Schema & Direct Access

### SQLite Database Structure

OpsHub stores data in `/data/opshub.db` with these tables:

#### 1. **logs** - All container logs
```sql
CREATE TABLE logs (
    id INTEGER PRIMARY KEY,
    timestamp TEXT NOT NULL,
    container_name TEXT NOT NULL,
    container_id TEXT NOT NULL,
    level TEXT NOT NULL,
    message TEXT NOT NULL,
    raw_log TEXT,
    source TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. **user_sessions** - OpenWebUI user tracking
```sql
CREATE TABLE user_sessions (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    model TEXT,
    action TEXT NOT NULL,
    session_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT
);
```

#### 3. **performance_metrics** - System metrics
```sql
CREATE TABLE performance_metrics (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT,
    container_name TEXT,
    metadata TEXT
);
```

### Direct Database Queries

```bash
# Access database directly
docker exec -it opshub sqlite3 /data/opshub.db

# Example queries
.mode column
.headers on

-- Most active users in last 24 hours
SELECT username, COUNT(*) as requests, MAX(timestamp) as last_seen
FROM user_sessions 
WHERE timestamp >= datetime('now', '-24 hours')
GROUP BY username 
ORDER BY requests DESC;

-- Error trends by container
SELECT container_name, DATE(timestamp) as date, COUNT(*) as error_count
FROM logs 
WHERE level = 'ERROR' AND timestamp >= datetime('now', '-7 days')
GROUP BY container_name, DATE(timestamp)
ORDER BY date DESC, error_count DESC;

-- GPU utilization trends
SELECT DATE(timestamp) as date, AVG(value) as avg_utilization
FROM performance_metrics 
WHERE metric_name LIKE '%gpu%utilization%'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

---

## 🚨 Monitoring OpsHub Health

### Service Health Checks

#### 1. **API Health**
```bash
# Basic health check
curl http://your-instance-ip:8089/health

# Check if all endpoints respond
curl http://your-instance-ip:8089/containers/status
curl http://your-instance-ip:8089/metrics/performance
curl http://your-instance-ip:8089/users/sessions
```

#### 2. **Database Health**
```bash
# Check database size and integrity
docker exec opshub sqlite3 /data/opshub.db "PRAGMA integrity_check;"
docker exec opshub sqlite3 /data/opshub.db "SELECT COUNT(*) FROM logs;"
```

#### 3. **Log Collection Health**
```bash
# Verify logs are being collected
docker logs opshub | tail -20

# Check latest log entries
curl "http://your-instance-ip:8089/logs/all?tail=5"
```

### Performance Monitoring

#### 1. **Resource Usage**
```bash
# Monitor OpsHub container resources
docker stats opshub

# Check disk usage
docker exec opshub du -sh /data

# Monitor memory usage
docker exec opshub free -h
```

#### 2. **API Performance**
```bash
# Test API response time
time curl http://your-instance-ip:8089/containers/status

# Monitor concurrent connections
docker exec opshub netstat -an | grep :8089
```

---

## 🔧 Configuration & Customization

### Environment Variables

OpsHub behavior is controlled by environment variables in `docker-compose.yml`:

```yaml
environment:
  # Container discovery
  OPS_DISCOVER: "all"                    # Discover all containers
  OPS_INCLUDE_REGEX: ".*"                # Include pattern
  OPS_EXCLUDE_REGEX: "(opshub|loki|promtail)"  # Exclude monitoring containers
  OPS_INCLUDE_STOPPED: "true"            # Monitor stopped containers
  
  # Data retention
  OPS_RETENTION_ACTIVE_DAYS: "7"         # Keep logs for 7 days
  OPS_RETENTION_ARCHIVE_DAYS: "30"       # Archive for 30 days
  OPS_RETENTION_PURGE_DAYS: "90"         # Purge after 90 days
  
  # Archive settings
  OPS_ARCHIVE_MODE: "daily-tar"          # daily-tar | per-container
  
  # Database settings
  OPS_DATA_DIR: "/data"                  # Data directory
```

### Custom Log Patterns

Add custom log parsing patterns in `opshub/logging_pipeline.py`:

```python
# Custom patterns for your applications
CUSTOM_PATTERNS = {
    "payment_success": re.compile(r"payment.*success", re.I),
    "user_signup": re.compile(r"user.*registered", re.I),
    "model_load": re.compile(r"loaded\s+model[:\s]+(\w+)", re.I),
    "gpu_allocation": re.compile(r"allocated\s+gpu[:\s]+(\d+)", re.I)
}
```

### Custom Metrics

Add application-specific metrics:

```python
from prometheus_client import Counter, Histogram, Gauge

# Custom metrics
model_requests = Counter('model_requests_total', 'Total model requests', ['model', 'user'])
response_time = Histogram('model_response_time_seconds', 'Model response time')
active_models = Gauge('active_models', 'Number of active models')
```

---

## 🔐 Security Considerations

### 1. **API Security**
- OpsHub runs on internal network only
- No authentication required for internal use
- Add reverse proxy with auth for external access

### 2. **Data Privacy**
- User data is stored locally only
- No external data transmission
- Log data may contain sensitive information

### 3. **Resource Protection**
```yaml
# Resource limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
```

---

## 🎯 Integration Examples

### 1. **Slack Notifications**
```python
import requests

def send_slack_alert(message):
    webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    payload = {
        "text": f"🚨 Alert: {message}",
        "channel": "#alerts",
        "username": "OpsHub"
    }
    requests.post(webhook_url, json=payload)

# Monitor for high error rates
response = requests.get('http://localhost:8089/search/logs?level=error&hours=1')
error_count = response.json()['count']

if error_count > 50:
    send_slack_alert(f"High error rate: {error_count} errors in last hour")
```

### 2. **Custom Dashboard Data**
```python
import requests
import json

def get_dashboard_data():
    # Get current system status
    containers = requests.get('http://localhost:8089/containers/status').json()
    performance = requests.get('http://localhost:8089/metrics/performance').json()
    users = requests.get('http://localhost:8089/users/sessions?active_only=true').json()
    
    return {
        "containers_running": len([c for c in containers if c['status'] == 'running']),
        "cpu_usage": performance['cpu_percent'],
        "gpu_temp": max([gpu['temperature'] for gpu in performance['gpus']]),
        "active_users": len(users),
        "timestamp": performance['timestamp']
    }

# Use in your custom application
dashboard_data = get_dashboard_data()
print(json.dumps(dashboard_data, indent=2))
```

### 3. **Automated Reports**
```python
import requests
from datetime import datetime, timedelta

def generate_daily_report():
    yesterday = datetime.now() - timedelta(days=1)
    
    # Get user analytics
    users = requests.get('http://localhost:8089/analytics/users?period=24').json()
    
    # Get error summary
    errors = requests.get('http://localhost:8089/search/logs?level=error&hours=24').json()
    
    report = f"""
    Daily Report - {yesterday.strftime('%Y-%m-%d')}
    
    User Activity:
    - Total Users: {users['total_users']}
    - Active Users: {users['active_users']}
    - Peak Concurrent: {users['peak_concurrent']}
    
    System Health:
    - Total Errors: {errors['count']}
    - Top Models: {', '.join([m['model'] for m in users['top_models'][:3]])}
    """
    
    return report

# Schedule this to run daily
print(generate_daily_report())
```

---

## 📈 Performance Optimization

### 1. **Database Optimization**
```bash
# Optimize database performance
docker exec opshub sqlite3 /data/opshub.db "VACUUM;"
docker exec opshub sqlite3 /data/opshub.db "ANALYZE;"

# Monitor database size
docker exec opshub sqlite3 /data/opshub.db "SELECT COUNT(*) FROM logs;"
```

### 2. **Memory Management**
```bash
# Monitor OpsHub memory usage
docker stats opshub --no-stream

# Check for memory leaks
docker exec opshub ps aux
```

### 3. **API Response Time**
```bash
# Test API performance
for i in {1..10}; do
  time curl -s http://localhost:8089/health > /dev/null
done
```

---

## 🎯 Quick Reference

### Essential API Endpoints
- **Health**: `GET /health`
- **Container Status**: `GET /containers/status`
- **System Metrics**: `GET /metrics/performance`
- **User Sessions**: `GET /users/sessions`
- **Search Logs**: `GET /search/logs?query=text`
- **Analytics**: `GET /analytics/users`

### Common Use Cases
1. **Monitor container health**: Check `/containers/status` regularly
2. **Track user activity**: Use `/users/sessions` and `/analytics/users`
3. **Analyze errors**: Search logs with `/search/logs?level=error`
4. **System monitoring**: Get performance data from `/metrics/performance`
5. **Custom integrations**: Use WebSocket connections for real-time data

**OpsHub is your intelligent monitoring assistant, providing deep insights into your Docker environment and user behavior! 🔧🚀**
