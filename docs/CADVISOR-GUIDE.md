# 📊 cAdvisor Guide - Container Resource Monitoring

**cAdvisor (Container Advisor) provides real-time resource usage and performance metrics for all your Docker containers, giving you detailed insights into container behavior and resource consumption.**

---

## 🎯 What is cAdvisor?

cAdvisor is Google's open-source container monitoring tool that:
- **Monitors container resources** - CPU, memory, network, and disk usage
- **Collects performance metrics** automatically for all containers
- **Provides historical data** for trend analysis and capacity planning
- **Exposes metrics** in multiple formats (Prometheus, InfluxDB, etc.)
- **Requires no configuration** - automatically discovers all containers
- **Runs with minimal overhead** - lightweight monitoring agent

## 🌐 Accessing cAdvisor

**URL**: `http://your-instance-ip:8085`

### Interface Overview:
- **Home** - Overall system and container overview
- **Containers** - Detailed per-container metrics and drill-down
- **System** - Host system resource usage
- **Docker Images** - Image-based resource analysis

---

## 📊 What cAdvisor Monitors

### 1. **Container-Level Metrics**

#### CPU Metrics
- **CPU Usage** - Total CPU time consumed
- **CPU Percentage** - Current CPU utilization
- **CPU Throttling** - When containers hit CPU limits
- **Per-Core Usage** - CPU usage distribution across cores

#### Memory Metrics
- **Memory Usage** - Current memory consumption
- **Memory Limit** - Container memory limits
- **Memory Cache** - Page cache usage
- **Memory Swap** - Swap space utilization
- **RSS Memory** - Resident Set Size (physical memory)

#### Network Metrics
- **RX Bytes** - Network bytes received
- **TX Bytes** - Network bytes transmitted
- **RX Packets** - Network packets received
- **TX Packets** - Network packets transmitted
- **Network Errors** - Transmission errors

#### Disk Metrics
- **Disk Usage** - Container disk space usage
- **Disk I/O** - Read/write operations
- **I/O Wait** - Time waiting for disk operations

### 2. **System-Level Metrics**

#### Overall System
- **Total CPU Usage** - Aggregate CPU across all containers
- **Total Memory Usage** - System memory consumption
- **Total Network Traffic** - Aggregate network usage
- **Total Disk Usage** - System-wide disk metrics

### 3. **Container Lifecycle Metrics**
- **Container Creation Time** - When containers were created
- **Container Uptime** - How long containers have been running
- **Container Restart Count** - Number of restarts
- **Container Status** - Running, stopped, paused states

---

## 🔍 Using the cAdvisor Web Interface

### 1. **Main Dashboard**

When you visit `http://your-instance-ip:8085`, you'll see:

#### System Overview
- **Total Containers** - Count of running containers
- **System Load** - Current system load average
- **Memory Usage** - Overall system memory consumption
- **CPU Usage** - System-wide CPU utilization

#### Container List
A table showing all containers with:
- Container name and image
- Current CPU and memory usage
- Network I/O statistics
- Uptime and status

### 2. **Container Drill-Down**

Click on any container to see detailed metrics:

#### Resource Usage Graphs
- **CPU Usage Over Time** - Historical CPU consumption
- **Memory Usage Over Time** - Memory usage trends
- **Network I/O Over Time** - Network traffic patterns
- **Disk I/O Over Time** - Disk usage patterns

#### Real-Time Metrics
- Current resource consumption
- Resource limits and quotas
- Process information within the container

### 3. **Time Range Selection**

cAdvisor provides data for different time ranges:
- **Last Hour** - Minute-by-minute data
- **Last Day** - Hourly aggregated data
- **Last Week** - Daily aggregated data

---

## 📈 Key Metrics for Your Environment

### 1. **AI/ML Container Monitoring**

#### Ollama Container
```
Container: ollama
Key Metrics to Watch:
- CPU Usage: Should be high during model inference
- Memory Usage: Models require significant RAM
- GPU Integration: Works with GPU monitoring
- Network: API request/response traffic
```

#### OpenWebUI Container
```
Container: openwebui
Key Metrics to Watch:
- Memory Usage: Web application overhead
- Network: User request traffic
- CPU Usage: Web server processing
- Disk I/O: Log writes and static files
```

### 2. **Database Container Monitoring**

#### PostgreSQL Containers
```
Containers: postgres-*, clip-postgres
Key Metrics to Watch:
- Memory Usage: Database buffer pools
- Disk I/O: Database operations
- CPU Usage: Query processing
- Network: Database connections
```

#### Redis Container
```
Container: clip-redis
Key Metrics to Watch:
- Memory Usage: In-memory data store
- Network: Cache operations
- CPU Usage: Data processing
- Persistence: Disk operations
```

### 3. **Infrastructure Container Monitoring**

#### NGINX Proxy Manager
```
Container: nginx-proxy-manager
Key Metrics to Watch:
- Network: Proxy traffic
- CPU Usage: Request processing
- Memory Usage: Connection pools
- Disk I/O: Log files
```

#### RabbitMQ
```
Container: clip-rabbitmq
Key Metrics to Watch:
- Memory Usage: Message queues
- Network: Message traffic
- Disk I/O: Message persistence
- CPU Usage: Message routing
```

---

## 🚨 Resource Alerts and Thresholds

### 1. **Critical Thresholds to Monitor**

#### High CPU Usage (>90%)
```
Indicators:
- Sustained high CPU across multiple containers
- CPU throttling events
- Increased response times

Actions:
- Scale containers horizontally
- Optimize application code
- Increase CPU limits
```

#### High Memory Usage (>90%)
```
Indicators:
- Memory usage approaching limits
- Swap usage increasing
- Container OOM (Out of Memory) kills

Actions:
- Increase memory limits
- Optimize memory usage
- Add more system memory
```

#### Network Bottlenecks
```
Indicators:
- High network error rates
- Sustained high bandwidth usage
- Network timeouts

Actions:
- Check network configuration
- Monitor external dependencies
- Optimize data transfer
```

#### Disk I/O Issues
```
Indicators:
- High I/O wait times
- Slow disk operations
- Disk space running low

Actions:
- Optimize database queries
- Implement caching
- Monitor log file growth
```

### 2. **Container-Specific Alerts**

#### For Your 200+ User Environment

**OpenWebUI Performance**
- Memory usage > 2GB (indicates high user load)
- CPU usage > 80% (web server strain)
- Network traffic spikes (user activity surges)

**Ollama Resource Consumption**
- Memory usage > 16GB (large models loaded)
- CPU usage consistently > 90% (inference bottleneck)
- GPU utilization < 50% (underutilized AI hardware)

**Database Performance**
- PostgreSQL memory > 4GB (query performance issues)
- High disk I/O on database containers (slow queries)
- Network timeouts on database connections

---

## 📊 Integration with Prometheus

### 1. **Metrics Exposition**

cAdvisor automatically exposes metrics at:
```
http://your-instance-ip:8085/metrics
```

These metrics are automatically scraped by Prometheus and include:

#### Container CPU Metrics
```promql
# CPU usage rate
container_cpu_usage_seconds_total

# CPU usage percentage
rate(container_cpu_usage_seconds_total[5m]) * 100

# CPU throttling
container_cpu_cfs_throttled_seconds_total
```

#### Container Memory Metrics
```promql
# Memory usage
container_memory_usage_bytes

# Memory limit
container_memory_limit_bytes

# Memory usage percentage
(container_memory_usage_bytes / container_memory_limit_bytes) * 100

# Memory cache
container_memory_cache
```

#### Container Network Metrics
```promql
# Network receive bytes
container_network_receive_bytes_total

# Network transmit bytes  
container_network_transmit_bytes_total

# Network errors
container_network_receive_errors_total
```

#### Container Filesystem Metrics
```promql
# Filesystem usage
container_fs_usage_bytes

# Filesystem limit
container_fs_limit_bytes

# Filesystem usage percentage
(container_fs_usage_bytes / container_fs_limit_bytes) * 100
```

### 2. **Useful Prometheus Queries**

#### Top Resource Consumers
```promql
# Top 10 CPU consuming containers
topk(10, rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100)

# Top 10 memory consuming containers
topk(10, container_memory_usage_bytes{name!=""} / 1024 / 1024 / 1024)

# Top 10 network consuming containers
topk(10, rate(container_network_receive_bytes_total{name!=""}[5m]))
```

#### Resource Utilization Trends
```promql
# Average CPU usage over time
avg(rate(container_cpu_usage_seconds_total{name!=""}[5m])) by (name)

# Memory usage trend
container_memory_usage_bytes{name!=""} / container_memory_limit_bytes{name!=""} * 100

# Network traffic trends
rate(container_network_receive_bytes_total{name!=""}[5m]) + 
rate(container_network_transmit_bytes_total{name!=""}[5m])
```

#### Container Health Indicators
```promql
# Containers approaching memory limits
(container_memory_usage_bytes / container_memory_limit_bytes) * 100 > 90

# Containers with high restart rates
rate(container_start_time_seconds[1h]) > 0.1

# Containers with network errors
rate(container_network_receive_errors_total[5m]) > 0
```

---

## 🔧 Advanced Features

### 1. **Machine-Readable Formats**

#### JSON API
```bash
# Get container information in JSON
curl http://your-instance-ip:8085/api/v1.3/containers/

# Get specific container stats
curl http://your-instance-ip:8085/api/v1.3/containers/docker/$(docker ps -q --filter name=ollama)
```

#### CSV Export
```bash
# Export metrics to CSV (custom implementation needed)
curl http://your-instance-ip:8085/api/v1.3/containers/ | jq '.[] | [.name, .stats[0].cpu.usage.total, .stats[0].memory.usage] | @csv'
```

### 2. **Historical Data Storage**

cAdvisor stores metrics for:
- **2 minutes** - Raw data points
- **24 hours** - Minute-level aggregation  
- **7 days** - Hour-level aggregation

For longer retention, data flows through Prometheus.

### 3. **Custom Container Labels**

Use Docker labels for better organization:
```yaml
# In docker-compose.yml
services:
  your-service:
    labels:
      - "monitoring.team=ai-ml"
      - "monitoring.criticality=high"
      - "monitoring.environment=production"
```

These labels appear in cAdvisor and help with filtering.

---

## 🔍 Troubleshooting cAdvisor

### 1. **Common Issues**

#### cAdvisor Not Showing Data
```bash
# Check if cAdvisor is running
docker-compose ps cadvisor

# Check cAdvisor logs
docker-compose logs cadvisor

# Verify Docker socket access
docker exec cadvisor ls -la /var/run/docker.sock
```

#### Missing Container Metrics
```bash
# Verify container is running
docker ps

# Check if container has resource limits
docker inspect container_name | grep -i memory

# Restart cAdvisor if needed
docker-compose restart cadvisor
```

#### High cAdvisor Resource Usage
```bash
# Monitor cAdvisor itself
docker stats cadvisor

# Check storage usage
docker exec cadvisor df -h

# Reduce data retention if needed
# (Modify housekeeping_interval in docker-compose.yml)
```

### 2. **Performance Optimization**

#### Reduce Collection Frequency
```yaml
# In docker-compose.yml
cadvisor:
  command:
    - '--housekeeping_interval=30s'  # Default 10s
    - '--docker_only=true'           # Monitor Docker only
    - '--disable_metrics=network,disk'  # Disable specific metrics
```

#### Storage Optimization
```yaml
cadvisor:
  command:
    - '--storage_duration=1h'       # Reduce storage duration
    - '--enable_load_reader=false'  # Disable load reader
```

---

## 📱 Mobile and API Access

### 1. **Mobile Interface**

cAdvisor's web interface is responsive and works on mobile devices:
- Touch-friendly navigation
- Responsive graphs and charts
- Mobile-optimized layouts

### 2. **REST API Examples**

#### Get All Container Stats
```python
import requests
import json

# Get container data
response = requests.get('http://your-instance-ip:8085/api/v1.3/containers/')
containers = response.json()

# Process container stats
for container_path, container_data in containers.items():
    if container_data.get('spec', {}).get('labels', {}).get('com.docker.compose.service'):
        service_name = container_data['spec']['labels']['com.docker.compose.service']
        latest_stats = container_data['stats'][-1] if container_data['stats'] else {}
        
        print(f"Service: {service_name}")
        print(f"CPU Usage: {latest_stats.get('cpu', {}).get('usage', {}).get('total', 0)}")
        print(f"Memory Usage: {latest_stats.get('memory', {}).get('usage', 0)}")
        print("---")
```

#### Monitor Specific Containers
```python
# Monitor your key services
key_services = ['ollama', 'openwebui', 'postgres', 'redis']

def get_container_metrics(service_name):
    response = requests.get(f'http://your-instance-ip:8085/api/v1.3/containers/')
    containers = response.json()
    
    for path, data in containers.items():
        labels = data.get('spec', {}).get('labels', {})
        if labels.get('com.docker.compose.service') == service_name:
            return data['stats'][-1] if data['stats'] else {}
    return None

# Get metrics for all key services
for service in key_services:
    metrics = get_container_metrics(service)
    if metrics:
        cpu_usage = metrics.get('cpu', {}).get('usage', {}).get('total', 0)
        memory_usage = metrics.get('memory', {}).get('usage', 0)
        print(f"{service}: CPU={cpu_usage}, Memory={memory_usage/1024/1024:.1f}MB")
```

---

## 📊 Custom Dashboards and Alerts

### 1. **Grafana Integration**

Create custom Grafana panels using cAdvisor metrics:

#### Container Resource Overview Panel
```promql
# Panel 1: Container CPU Usage
sum(rate(container_cpu_usage_seconds_total{name!=""}[5m])) by (name) * 100

# Panel 2: Container Memory Usage  
container_memory_usage_bytes{name!=""} / 1024 / 1024 / 1024

# Panel 3: Container Network I/O
rate(container_network_receive_bytes_total{name!=""}[5m]) + 
rate(container_network_transmit_bytes_total{name!=""}[5m])
```

#### AI/ML Workload Dashboard
```promql
# Ollama Performance
rate(container_cpu_usage_seconds_total{name="ollama"}[5m]) * 100

# OpenWebUI User Load
rate(container_network_receive_bytes_total{name="openwebui"}[5m])

# Database Performance
rate(container_cpu_usage_seconds_total{name=~"postgres.*"}[5m]) * 100
```

### 2. **Alert Rules**

#### Container Resource Alerts
```yaml
# High CPU usage alert
- alert: ContainerHighCPU
  expr: rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100 > 90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Container {{ $labels.name }} high CPU usage"
    description: "Container CPU usage is {{ $value }}%"

# High memory usage alert
- alert: ContainerHighMemory
  expr: (container_memory_usage_bytes / container_memory_limit_bytes) * 100 > 90
  for: 3m
  labels:
    severity: critical
  annotations:
    summary: "Container {{ $labels.name }} high memory usage"
    description: "Container memory usage is {{ $value }}%"

# Container restart alert
- alert: ContainerRestarting
  expr: rate(container_start_time_seconds[1h]) > 0.1
  for: 1m
  labels:
    severity: warning
  annotations:
    summary: "Container {{ $labels.name }} restarting frequently"
    description: "Container has restarted {{ $value }} times in the last hour"
```

---

## 🎯 Best Practices for Your Environment

### 1. **For 200+ User Monitoring**

#### Resource Planning
- Monitor container resource usage patterns during peak hours
- Identify bottlenecks before they impact users
- Plan capacity based on usage trends
- Set appropriate resource limits and requests

#### Performance Optimization
- Use cAdvisor data to optimize container resource allocation
- Identify containers that can be scaled horizontally
- Monitor for memory leaks and resource drift
- Optimize based on actual usage patterns

### 2. **AI/ML Workload Monitoring**

#### Model Performance
- Monitor Ollama container during model inference
- Track memory usage for different model sizes
- Optimize container limits based on model requirements
- Correlate GPU and container metrics

#### User Experience
- Monitor OpenWebUI response times through resource usage
- Track resource consumption patterns by user load
- Identify performance bottlenecks in the web stack
- Optimize based on user activity patterns

### 3. **Database and Infrastructure**

#### Database Performance
- Monitor PostgreSQL container resource usage
- Track disk I/O patterns for query optimization
- Monitor memory usage for buffer tuning
- Alert on database performance degradation

#### Network Monitoring
- Track inter-container communication patterns
- Monitor network bottlenecks
- Identify containers with high network usage
- Optimize network configuration based on traffic patterns

---

## 🔐 Security and Access Control

### 1. **Network Security**
- cAdvisor runs on internal network only
- No authentication required for internal access
- Use firewall rules to restrict external access
- Consider VPN for remote monitoring

### 2. **Data Privacy**
- Container metrics may reveal sensitive information
- Limit access to authorized personnel
- Be careful with metric exports and sharing
- Monitor who accesses the cAdvisor interface

---

## 📈 Quick Reference

### Essential URLs
- **Main Interface**: `http://your-instance-ip:8085`
- **Metrics Endpoint**: `http://your-instance-ip:8085/metrics`
- **API Endpoint**: `http://your-instance-ip:8085/api/v1.3/containers/`

### Key Metrics to Watch
- `container_cpu_usage_seconds_total` - CPU usage
- `container_memory_usage_bytes` - Memory consumption
- `container_network_receive_bytes_total` - Network input
- `container_fs_usage_bytes` - Disk usage
- `container_start_time_seconds` - Container lifecycle

### Common Use Cases
1. **Resource Planning** - Historical usage data for capacity planning
2. **Performance Debugging** - Identify resource bottlenecks
3. **Cost Optimization** - Right-size container resources
4. **Alerting** - Set up alerts for resource thresholds
5. **Trend Analysis** - Long-term resource usage patterns

**cAdvisor gives you deep visibility into container resource usage, helping you optimize performance and plan for growth! 📊🚀**
