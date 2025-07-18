# 📊 Prometheus Guide - Metrics Collection & Storage

**Prometheus is the heart of your metrics collection system, gathering performance data from all your containers and system components.**

---

## 🎯 What is Prometheus?

Prometheus is an open-source monitoring and alerting toolkit that:
- **Collects metrics** from your applications and infrastructure
- **Stores time-series data** efficiently with compression
- **Provides powerful queries** using PromQL (Prometheus Query Language)
- **Scrapes metrics** from configured endpoints automatically
- **Handles service discovery** to find new monitoring targets
- **Triggers alerts** based on defined rules

## 🌐 Accessing Prometheus

**URL**: `http://your-instance-ip:9090`

### Interface Overview:
1. **Graph** - Query and visualize metrics
2. **Alerts** - View active alerts and firing rules
3. **Status** - Check configuration, targets, and service discovery
4. **Help** - PromQL documentation and examples

---

## 📈 What Metrics Are Being Collected

### 1. **System Metrics** (via Node Exporter)
```promql
# CPU usage per core
node_cpu_seconds_total

# Memory statistics
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes

# Disk usage and I/O
node_filesystem_size_bytes
node_disk_io_time_seconds_total

# Network traffic
node_network_receive_bytes_total
node_network_transmit_bytes_total

# Load average
node_load1, node_load5, node_load15
```

### 2. **Container Metrics** (via cAdvisor)
```promql
# Container CPU usage
container_cpu_usage_seconds_total

# Container memory usage
container_memory_usage_bytes
container_memory_limit_bytes

# Container network I/O
container_network_receive_bytes_total
container_network_transmit_bytes_total

# Container filesystem usage
container_fs_usage_bytes
container_fs_limit_bytes
```

### 3. **GPU Metrics** (via DCGM Exporter)
```promql
# GPU utilization percentage
DCGM_FI_DEV_GPU_UTIL

# GPU memory utilization
DCGM_FI_DEV_MEM_COPY_UTIL

# GPU temperature
DCGM_FI_DEV_GPU_TEMP

# GPU power consumption
DCGM_FI_DEV_POWER_USAGE
```

### 4. **Application Metrics** (via OpsHub)
```promql
# Docker container status
opshub_container_up

# User session metrics
opshub_user_sessions_active
opshub_user_requests_total

# Log entry counts by level
opshub_log_entries_total

# Custom application metrics
opshub_model_requests_total
opshub_api_response_time_seconds
```

---

## 🔍 Using PromQL (Prometheus Query Language)

### Basic Query Examples

#### 1. **Current Values**
```promql
# Current CPU usage percentage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Current memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Current container count
count(container_last_seen)

# Active user sessions
opshub_user_sessions_active
```

#### 2. **Rate Calculations**
```promql
# CPU usage rate over 5 minutes
rate(node_cpu_seconds_total[5m])

# Network receive rate in MB/s
rate(node_network_receive_bytes_total[5m]) / 1024 / 1024

# Container restart rate
rate(container_start_time_seconds[1h])

# API request rate
rate(opshub_api_requests_total[5m])
```

#### 3. **Aggregations**
```promql
# Average CPU usage across all cores
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m]))

# Total network traffic
sum(rate(node_network_receive_bytes_total[5m]))

# Top 5 containers by memory usage
topk(5, container_memory_usage_bytes)

# Maximum GPU temperature
max(DCGM_FI_DEV_GPU_TEMP)
```

#### 4. **Filtering and Grouping**
```promql
# CPU usage by container
sum by (name) (rate(container_cpu_usage_seconds_total[5m]))

# Memory usage for specific containers
container_memory_usage_bytes{name=~"ollama|openwebui"}

# GPU metrics for GPU 0
DCGM_FI_DEV_GPU_UTIL{gpu="0"}

# Error logs from last hour
increase(opshub_log_entries_total{level="error"}[1h])
```

---

## 📊 Essential Queries for Your Environment

### Container Monitoring

#### 1. **Container Health**
```promql
# Containers that are down
up{job="docker"} == 0

# Containers with high restart rate
rate(container_start_time_seconds[1h]) > 0.1

# Containers using >90% memory
(container_memory_usage_bytes / container_memory_limit_bytes) * 100 > 90
```

#### 2. **Resource Usage**
```promql
# Top CPU consumers
topk(10, rate(container_cpu_usage_seconds_total[5m]) * 100)

# Top memory consumers
topk(10, container_memory_usage_bytes / 1024 / 1024 / 1024)

# Containers with network issues
rate(container_network_receive_bytes_total[5m]) == 0
```

### System Performance

#### 1. **CPU Monitoring**
```promql
# System CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage by mode
rate(node_cpu_seconds_total[5m]) * 100

# Load average
node_load1 / count(node_cpu_seconds_total{mode="idle"})
```

#### 2. **Memory Monitoring**
```promql
# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memory usage in GB
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

# Swap usage
node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes
```

#### 3. **Disk Monitoring**
```promql
# Disk usage percentage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Disk I/O rate
rate(node_disk_io_time_seconds_total[5m])

# Free disk space in GB
node_filesystem_avail_bytes / 1024 / 1024 / 1024
```

### GPU Performance

#### 1. **GPU Utilization**
```promql
# GPU utilization per GPU
DCGM_FI_DEV_GPU_UTIL

# Average GPU utilization
avg(DCGM_FI_DEV_GPU_UTIL)

# GPU memory usage percentage
(DCGM_FI_DEV_FB_USED / DCGM_FI_DEV_FB_TOTAL) * 100
```

#### 2. **GPU Health**
```promql
# GPU temperature
DCGM_FI_DEV_GPU_TEMP

# GPU power consumption
DCGM_FI_DEV_POWER_USAGE

# GPU throttling events
DCGM_FI_DEV_THERMAL_VIOLATION
```

### User Analytics

#### 1. **User Activity**
```promql
# Active user count
opshub_user_sessions_active

# User login rate
rate(opshub_user_logins_total[5m])

# Average session duration
avg(opshub_session_duration_seconds)
```

#### 2. **Model Usage**
```promql
# Most popular models
topk(10, rate(opshub_model_requests_total[1h]))

# Model response time
histogram_quantile(0.95, rate(opshub_model_response_time_seconds_bucket[5m]))

# Failed model requests
rate(opshub_model_requests_total{status="error"}[5m])
```

---

## 📋 Monitoring Targets

### Current Scrape Targets

You can view all monitoring targets at: `http://your-instance-ip:9090/targets`

#### 1. **System Targets**
- **Node Exporter** - System metrics (localhost:9100)
- **cAdvisor** - Container metrics (localhost:8085)
- **DCGM Exporter** - GPU metrics (localhost:9400)

#### 2. **Application Targets**
- **OpsHub** - Custom metrics (localhost:9188)
- **Prometheus** - Self-monitoring (localhost:9090)

#### 3. **Service Discovery**
Your Prometheus is configured to automatically discover:
- Docker containers with monitoring labels
- Services in the Docker network
- Dynamic service endpoints

---

## 🚨 Alert Rules

### Pre-configured Alert Rules

#### 1. **System Alerts**
```yaml
# High CPU usage
- alert: HighCPUUsage
  expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage detected"
    description: "CPU usage is {{ $value }}% for more than 5 minutes"

# High memory usage
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
  for: 3m
  labels:
    severity: critical
  annotations:
    summary: "High memory usage detected"
    description: "Memory usage is {{ $value }}% for more than 3 minutes"

# Low disk space
- alert: LowDiskSpace
  expr: 100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100) > 85
  for: 1m
  labels:
    severity: warning
  annotations:
    summary: "Low disk space"
    description: "Disk usage is {{ $value }}% on {{ $labels.mountpoint }}"
```

#### 2. **Container Alerts**
```yaml
# Container down
- alert: ContainerDown
  expr: up{job="docker"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Container is down"
    description: "Container {{ $labels.instance }} has been down for more than 1 minute"

# High container memory usage
- alert: ContainerHighMemory
  expr: (container_memory_usage_bytes / container_memory_limit_bytes) * 100 > 90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Container high memory usage"
    description: "Container {{ $labels.name }} is using {{ $value }}% of its memory limit"
```

#### 3. **GPU Alerts**
```yaml
# GPU overheating
- alert: GPUOverheating
  expr: DCGM_FI_DEV_GPU_TEMP > 85
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "GPU overheating"
    description: "GPU {{ $labels.gpu }} temperature is {{ $value }}°C"

# High GPU utilization
- alert: HighGPUUtilization
  expr: DCGM_FI_DEV_GPU_UTIL > 95
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High GPU utilization"
    description: "GPU {{ $labels.gpu }} has been at {{ $value }}% utilization for 10 minutes"
```

---

## 🔧 Configuration Deep Dive

### Prometheus Configuration File

Your Prometheus is configured via `/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s        # How often to scrape targets
  evaluation_interval: 15s    # How often to evaluate rules

rule_files:
  - "alert_rules.yml"         # Alert rule definitions

scrape_configs:
  # System metrics
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Container metrics  
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  # GPU metrics
  - job_name: 'dcgm-exporter'
    static_configs:
      - targets: ['dcgm-exporter:9400']

  # Application metrics
  - job_name: 'opshub'
    static_configs:
      - targets: ['opshub:9188']

  # Self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### Data Retention

Your Prometheus stores data with these settings:
- **Retention Period**: 15 days (configurable)
- **Storage Size**: Limited by disk space
- **Compression**: Automatic compression of older data

---

## 📊 Performance Tuning

### Query Performance

#### 1. **Efficient Queries**
```promql
# Good: Use rate() for counters
rate(container_cpu_usage_seconds_total[5m])

# Bad: Don't use raw counter values
container_cpu_usage_seconds_total

# Good: Aggregate early
sum(rate(node_network_receive_bytes_total[5m])) by (instance)

# Bad: Aggregate many series
sum(node_network_receive_bytes_total) by (instance)
```

#### 2. **Time Range Selection**
- Use appropriate time ranges for your queries
- Longer ranges require more computation
- Use recording rules for frequently used complex queries

#### 3. **Label Usage**
- Avoid high-cardinality labels
- Use label filtering to reduce data sets
- Be selective with label combinations

### Resource Management

#### 1. **Memory Usage**
- Monitor Prometheus memory consumption
- Adjust `--storage.tsdb.retention.size` if needed
- Use recording rules to pre-calculate expensive queries

#### 2. **Storage Management**
```bash
# Check storage usage
du -sh /prometheus-data

# View storage statistics in Prometheus
prometheus_tsdb_storage_blocks_bytes
```

---

## 🔍 Troubleshooting Prometheus

### Common Issues

#### 1. **High Memory Usage**
```bash
# Check Prometheus memory usage
docker stats prometheus

# View internal metrics
curl http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series

# Reduce retention if needed
# Edit docker-compose.yml: --storage.tsdb.retention.time=7d
```

#### 2. **Scrape Failures**
```bash
# Check target status
curl http://localhost:9090/api/v1/targets

# View failed targets in UI
# Go to Status > Targets in Prometheus web UI

# Check network connectivity
docker exec prometheus ping cadvisor
```

#### 3. **Slow Queries**
```bash
# Check query performance
# Go to Status > Query in Prometheus web UI

# Use query inspector in Grafana
# Enable query inspector for slow panels

# Optimize queries with recording rules
```

#### 4. **Missing Metrics**
```bash
# Verify metric names
curl http://localhost:9090/api/v1/label/__name__/values

# Check if targets are being scraped
curl http://localhost:9090/api/v1/targets

# Verify service endpoints
curl http://localhost:9100/metrics  # Node exporter
curl http://localhost:8085/metrics  # cAdvisor
```

---

## 📚 Advanced Features

### 1. **Recording Rules**
Pre-calculate expensive queries:

```yaml
groups:
  - name: performance_rules
    rules:
    - record: instance:cpu_usage:rate5m
      expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
    
    - record: instance:memory_usage:percentage
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### 2. **Federation**
For large environments, use Prometheus federation:
- Multiple Prometheus servers
- Hierarchical data collection
- Reduced query load

### 3. **Remote Storage**
For long-term storage:
- InfluxDB integration
- Thanos for long-term storage
- Cortex for scalable storage

---

## 🔐 Security Considerations

### 1. **Access Control**
- Prometheus runs on internal network only
- Use reverse proxy for external access
- Implement authentication if needed

### 2. **Data Protection**
- Metrics contain sensitive system information
- Restrict network access appropriately
- Consider encryption for data in transit

### 3. **Resource Limits**
- Set memory limits for Prometheus container
- Monitor storage usage
- Implement query timeouts

---

## 📱 API Usage

### Prometheus HTTP API

#### 1. **Query API**
```bash
# Instant query
curl 'http://localhost:9090/api/v1/query?query=up'

# Range query
curl 'http://localhost:9090/api/v1/query_range?query=up&start=2024-01-01T00:00:00Z&end=2024-01-01T01:00:00Z&step=15s'

# Query metadata
curl 'http://localhost:9090/api/v1/metadata'
```

#### 2. **Administrative API**
```bash
# Health check
curl http://localhost:9090/-/healthy

# Ready check
curl http://localhost:9090/-/ready

# Configuration reload (if enabled)
curl -X POST http://localhost:9090/-/reload
```

---

## 🎯 Best Practices for Your Environment

### 1. **Monitoring 200+ Users**
- Set up user-based alerting
- Monitor session patterns
- Track resource consumption per user
- Alert on unusual activity

### 2. **AI/ML Workload Monitoring**
- Monitor GPU utilization patterns
- Track model performance metrics
- Alert on GPU overheating
- Monitor VRAM usage

### 3. **Container Management**
- Monitor container health
- Track resource limits
- Alert on container failures
- Monitor image vulnerabilities

### 4. **Performance Optimization**
- Use recording rules for complex queries
- Set appropriate retention periods
- Monitor Prometheus performance itself
- Regular maintenance and cleanup

---

## 📈 Quick Reference

### Essential URLs
- **Main Interface**: `http://your-instance-ip:9090`
- **Targets Status**: `http://your-instance-ip:9090/targets`
- **Configuration**: `http://your-instance-ip:9090/config`
- **Rules**: `http://your-instance-ip:9090/rules`

### Key Metrics to Monitor
- `up` - Service availability
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemAvailable_bytes` - Available memory
- `container_memory_usage_bytes` - Container memory
- `DCGM_FI_DEV_GPU_TEMP` - GPU temperature

**Prometheus is the data engine powering your observability stack. Master it to gain deep insights into your infrastructure! 📊🚀**
