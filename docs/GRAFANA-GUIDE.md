# 📊 Grafana Guide - Visualization & Dashboards

**Grafana is your main visualization interface for monitoring all aspects of your Docker environment, system performance, and user analytics.**

---

## 🎯 What is Grafana?

Grafana is an open-source analytics and monitoring platform that allows you to:
- **Create dashboards** with beautiful, interactive visualizations
- **Set up alerts** for critical system conditions
- **Query multiple data sources** (Prometheus, Loki, databases)
- **Share insights** with your team through reports and annotations
- **Monitor trends** over time with historical data analysis

## 🌐 Accessing Grafana

**URL**: `http://your-instance-ip:3001`
- **Username**: `admin`
- **Password**: `admin` (change this immediately!)

### First Login Steps:
1. Open `http://your-instance-ip:3001` in your browser
2. Login with `admin/admin`
3. **IMPORTANT**: Change the default password when prompted
4. You'll see the Grafana home dashboard

---

## 📊 Pre-configured Dashboards

Your observability stack comes with several pre-built dashboards:

### 1. **Container Overview Dashboard**
- **Purpose**: Monitor all Docker containers at a glance
- **Metrics**: Container status, resource usage, restart counts
- **Use Cases**: 
  - Quick health check of all services
  - Identify containers using too many resources
  - Spot containers that are frequently restarting

### 2. **System Performance Dashboard**
- **Purpose**: Monitor host system metrics
- **Metrics**: CPU, memory, disk, network usage
- **Use Cases**:
  - Ensure your p3.24xlarge instance is performing well
  - Identify system bottlenecks
  - Plan for capacity scaling

### 3. **GPU Monitoring Dashboard**
- **Purpose**: Track NVIDIA GPU performance
- **Metrics**: GPU utilization, memory, temperature, power
- **Use Cases**:
  - Monitor AI/ML workload performance
  - Prevent GPU overheating
  - Optimize model deployment

### 4. **OpenWebUI User Analytics Dashboard**
- **Purpose**: Track user activity and model usage
- **Metrics**: Active users, session duration, model requests
- **Use Cases**:
  - Monitor your 200+ users
  - Identify popular models
  - Plan resource allocation

### 5. **Log Analysis Dashboard**
- **Purpose**: Visualize log patterns and errors
- **Metrics**: Error rates, log volume, alert counts
- **Use Cases**:
  - Spot error trends across services
  - Monitor application health
  - Track security events

---

## 🔧 How to Use Grafana

### Navigation Basics

1. **Home Dashboard** - Main landing page with overview
2. **Browse** - Access all available dashboards
3. **Playlists** - Rotate through multiple dashboards
4. **Alerting** - Configure and manage alerts
5. **Configuration** - Settings, data sources, users

### Creating Custom Dashboards

#### Step 1: Create New Dashboard
```
1. Click "+" icon in left sidebar
2. Select "Dashboard"
3. Click "Add new panel"
```

#### Step 2: Configure Panel
```
1. Select data source (Prometheus for metrics, Loki for logs)
2. Write PromQL query for metrics or LogQL for logs
3. Choose visualization type (graph, stat, table, etc.)
4. Configure panel title and description
```

#### Step 3: Save Dashboard
```
1. Click "Save" icon
2. Enter dashboard name and description
3. Choose folder organization
4. Set tags for easy searching
```

### Essential Queries for Your Environment

#### Container Metrics
```promql
# CPU usage by container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memory usage by container
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100

# Network traffic by container
rate(container_network_receive_bytes_total[5m])
```

#### System Metrics
```promql
# Overall CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage percentage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)
```

#### GPU Metrics
```promql
# GPU utilization
DCGM_FI_DEV_GPU_UTIL

# GPU memory usage
DCGM_FI_DEV_MEM_COPY_UTIL

# GPU temperature
DCGM_FI_DEV_GPU_TEMP
```

---

## 🚨 Setting Up Alerts

### Critical Alerts for Your Environment

#### 1. High CPU Usage Alert
```
Alert Name: High CPU Usage
Condition: avg(100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 90
Evaluation: Every 1m for 5m
Message: "System CPU usage is above 90% for 5 minutes"
```

#### 2. Container Down Alert
```
Alert Name: Container Down
Condition: up{job="docker"} == 0
Evaluation: Every 30s for 1m
Message: "Container {{$labels.instance}} is down"
```

#### 3. GPU Temperature Alert
```
Alert Name: GPU Overheating
Condition: DCGM_FI_DEV_GPU_TEMP > 85
Evaluation: Every 1m for 2m
Message: "GPU {{$labels.gpu}} temperature is {{$value}}°C"
```

#### 4. High Error Rate Alert
```
Alert Name: High Error Rate
Condition: rate(log_entries{level="error"}[5m]) > 10
Evaluation: Every 1m for 3m
Message: "Error rate is {{$value}} errors per second"
```

### Configuring Alert Notifications

#### Slack Integration
```json
{
  "webhook_url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
  "channel": "#alerts",
  "username": "Grafana",
  "title": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}",
  "text": "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
}
```

#### Email Notifications
```
SMTP Host: your-smtp-server.com
Port: 587
Username: alerts@yourcompany.com
Password: your-email-password
From: alerts@yourcompany.com
To: admin@yourcompany.com
```

---

## 📈 Dashboard Best Practices

### 1. **Dashboard Organization**
- Create folders for different teams/services
- Use consistent naming conventions
- Tag dashboards appropriately
- Set appropriate refresh intervals

### 2. **Panel Design**
- Use meaningful titles and descriptions
- Add units to metrics (%, MB, seconds)
- Set appropriate time ranges
- Use colors consistently

### 3. **Performance Optimization**
- Limit dashboard refresh rates
- Use efficient queries
- Avoid too many panels per dashboard
- Set reasonable time ranges

### 4. **User Experience**
- Add annotations for important events
- Use template variables for flexibility
- Provide context with text panels
- Link related dashboards

---

## 🔍 Monitoring Your 200+ Users

### User Activity Dashboard Panels

#### 1. **Active User Count**
```promql
# Current active sessions
count(opshub_user_sessions{status="active"})
```

#### 2. **Top Used Models**
```promql
# Most popular Ollama models
topk(10, count by (model) (opshub_model_requests))
```

#### 3. **User Session Duration**
```promql
# Average session length
avg(opshub_session_duration_seconds)
```

#### 4. **API Request Rate**
```promql
# Requests per second to OpenWebUI
rate(opshub_api_requests_total[5m])
```

### Setting User Limits

Create alerts for:
- Too many concurrent users
- Unusual API request patterns
- Long-running sessions
- Failed authentication attempts

---

## 🛠️ Advanced Features

### 1. **Annotations**
Mark important events on your graphs:
- Deployments
- Configuration changes
- Incidents
- Maintenance windows

### 2. **Templating**
Create dynamic dashboards with variables:
- Container selection dropdown
- Time range picker
- Environment selector
- User filter

### 3. **Data Source Management**
Configure multiple data sources:
- Prometheus (metrics)
- Loki (logs)
- PostgreSQL (application data)
- InfluxDB (time series data)

### 4. **Dashboard Sharing**
Share insights with your team:
- Public snapshots
- PDF reports
- Embedded panels
- Direct links with time ranges

---

## 🔧 Troubleshooting Grafana

### Common Issues

#### 1. **Dashboard Not Loading**
```bash
# Check Grafana service
docker-compose logs grafana

# Verify data source connectivity
curl http://localhost:9090/api/v1/query?query=up

# Check disk space
df -h
```

#### 2. **No Data in Panels**
- Verify data source configuration
- Check query syntax
- Confirm time range
- Ensure metrics are being collected

#### 3. **Slow Dashboard Performance**
- Reduce query complexity
- Increase refresh intervals
- Limit time ranges
- Optimize panel count

#### 4. **Alert Not Firing**
- Check alert rule syntax
- Verify notification channels
- Review alert history
- Test with manual queries

---

## 📱 Mobile Access

Grafana works well on mobile devices:
- Responsive dashboard design
- Touch-friendly navigation
- Mobile app available
- Push notifications for alerts

---

## 🔐 Security Best Practices

### 1. **Authentication**
- Change default admin password
- Enable LDAP/OAuth if available
- Use strong passwords
- Regular password rotation

### 2. **Authorization**
- Create role-based access
- Limit dashboard editing permissions
- Restrict data source access
- Audit user activities

### 3. **Network Security**
- Use HTTPS in production
- Restrict network access
- Configure firewall rules
- Use VPN for remote access

---

## 📚 Useful Resources

### Documentation
- [Official Grafana Documentation](https://grafana.com/docs/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Community Dashboards
Import pre-built dashboards from:
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- Docker monitoring dashboards
- System monitoring templates
- Application-specific dashboards

---

## 🎯 Quick Start Checklist

- [ ] Access Grafana at `http://your-instance-ip:3001`
- [ ] Change default admin password
- [ ] Explore pre-configured dashboards
- [ ] Set up critical alerts
- [ ] Configure notification channels
- [ ] Create custom dashboard for your needs
- [ ] Test alert notifications
- [ ] Train your team on dashboard usage

**Grafana is your window into the health and performance of your entire infrastructure. Use it to stay ahead of issues and make data-driven decisions! 📊🚀**
