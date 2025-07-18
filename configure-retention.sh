#!/bin/bash

# 📚 Log Retention Policy Configuration Script
# This script sets up comprehensive log retention policies for your environment

set -e

OPSHUB_CONFIG_DIR="/opt/obs-stack/opshub"
LOKI_CONFIG_DIR="/opt/obs-stack/loki"
PROMETHEUS_CONFIG_DIR="/opt/obs-stack/prometheus"

echo "📚 Configuring log retention policies for high-volume environment..."

# Function to configure OpsHub retention
configure_opshub_retention() {
    echo "🔧 Configuring OpsHub retention policies..."
    
    cat > "${OPSHUB_CONFIG_DIR}/retention_config.yaml" << 'EOF'
# OpsHub Retention Configuration
# Optimized for 200+ users and high-volume logging

retention:
  # Database retention settings
  database:
    # Keep active session data for 14 days
    active_sessions: 14d
    
    # Archive user sessions after 30 days  
    archived_sessions: 90d
    
    # Purge old performance metrics after 180 days
    performance_metrics: 180d
    
    # Keep error logs for 365 days (compliance)
    error_logs: 365d
    
    # Regular log entries - 30 days
    general_logs: 30d
    
    # Container status history - 60 days
    container_status: 60d
    
    # User analytics data - 1 year
    user_analytics: 365d
  
  # Log processing settings
  processing:
    # Batch size for log processing
    batch_size: 1000
    
    # Maximum logs to process per minute
    rate_limit: 5000
    
    # Archive logs instead of deleting
    archive_before_delete: true
    
    # Compression for archived logs
    compression_enabled: true
    
    # Backup location for archived data
    archive_path: "/data/archives"
  
  # Cleanup schedules
  schedules:
    # Daily cleanup at 2 AM
    daily_cleanup: "0 2 * * *"
    
    # Weekly deep cleanup on Sunday 3 AM
    weekly_cleanup: "0 3 * * 0"
    
    # Monthly archive on 1st at 4 AM
    monthly_archive: "0 4 1 * *"
    
    # Quarterly purge on 1st of quarter at 5 AM
    quarterly_purge: "0 5 1 */3 *"

# Performance optimization
performance:
  # Use bulk operations for better performance
  bulk_operations: true
  
  # Index optimization
  optimize_indexes: true
  
  # Vacuum database weekly
  vacuum_schedule: "0 1 * * 0"
  
  # Memory limits for processing
  max_memory_mb: 2048
  
  # Connection pool settings
  db_pool_size: 20
  db_pool_timeout: 30s

# Alert thresholds for retention monitoring
alerts:
  # Alert when database size exceeds threshold
  db_size_threshold_gb: 50
  
  # Alert when cleanup takes too long
  cleanup_timeout_minutes: 60
  
  # Alert when archive storage is low
  archive_space_threshold_percent: 85
  
  # Alert when retention queue is too large
  queue_size_threshold: 10000
EOF

    echo "✅ OpsHub retention configuration created"
}

# Function to configure Loki retention
configure_loki_retention() {
    echo "🗂️ Configuring Loki retention policies..."
    
    cat > "${LOKI_CONFIG_DIR}/retention-config.yaml" << 'EOF'
# Loki Retention Configuration
# Optimized for high-volume log ingestion

auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  log_level: info

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

# Retention configuration
limits_config:
  # Retention period for different log levels
  retention_period: 744h  # 31 days default
  
  # Split retention by stream
  retention_stream:
    # Error logs - keep for 1 year
    - selector: '{level="error"}'
      priority: 1
      period: 8760h  # 365 days
    
    # OpenWebUI user activity - 6 months
    - selector: '{container_name=~".*openwebui.*"}'
      priority: 2
      period: 4320h  # 180 days
    
    # Ollama model logs - 3 months
    - selector: '{container_name=~".*ollama.*"}'
      priority: 3
      period: 2160h  # 90 days
    
    # Database logs - 6 months
    - selector: '{container_name=~".*postgres.*|.*redis.*"}'
      priority: 4
      period: 4320h  # 180 days
    
    # Nginx/proxy logs - 2 months
    - selector: '{container_name=~".*nginx.*|.*proxy.*"}'
      priority: 5
      period: 1440h  # 60 days
    
    # System logs - 1 month
    - selector: '{job="systemd"}'
      priority: 6
      period: 744h   # 31 days
    
    # Debug logs - 1 week
    - selector: '{level="debug"}'
      priority: 7
      period: 168h   # 7 days
  
  # Ingestion rate limits for high volume
  ingestion_rate_mb: 50           # 50MB/s per tenant
  ingestion_burst_size_mb: 100    # 100MB burst
  max_streams_per_user: 10000     # Support many containers
  max_line_size: 256000           # 256KB max line size
  max_entries_limit_per_query: 5000
  
  # Query limits
  max_query_length: 12000h        # 500 days max query range
  max_query_parallelism: 32       # Parallel query processing
  max_concurrent_tail_requests: 20
  
  # Per-stream rate limiting for stability
  per_stream_rate_limit: 10MB     # 10MB/s per stream
  per_stream_rate_limit_burst: 20MB
  
  # Compaction settings for performance
  compactor:
    working_directory: /loki/compactor
    shared_store: filesystem
    compaction_interval: 10m
    retention_enabled: true
    retention_delete_delay: 2h
    retention_delete_worker_count: 150

# Table manager for retention
table_manager:
  retention_deletes_enabled: true
  retention_period: 744h  # 31 days default

# Compactor for cleanup
compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150

# Ruler for retention rules
ruler:
  storage:
    type: local
    local:
      directory: /loki/rules
  rule_path: /loki/rules
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
  enable_alertmanager_v2: true

# Query frontend optimization
frontend:
  max_outstanding_per_tenant: 256
  compress_responses: true
  log_queries_longer_than: 10s

query_range:
  align_queries_with_step: true
  max_retries: 5
  cache_results: true
  results_cache:
    cache:
      enable_fifocache: true
      fifocache:
        max_size_items: 1024
        validity: 24h

# Analytics and monitoring
analytics:
  reporting_enabled: false
EOF

    echo "✅ Loki retention configuration created"
}

# Function to configure Prometheus retention
configure_prometheus_retention() {
    echo "📊 Configuring Prometheus retention policies..."
    
    cat > "${PROMETHEUS_CONFIG_DIR}/retention-config.yml" << 'EOF'
# Prometheus Retention Configuration
# Optimized for p3.24xlarge with 200+ users

global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'obs-stack'
    env: 'production'

# Recording rules for retention optimization
rule_files:
  - "retention_rules.yml"
  - "aggregation_rules.yml"

# Alerting rules
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # High-frequency scraping for critical metrics
  - job_name: 'opshub'
    scrape_interval: 10s
    static_configs:
      - targets: ['opshub:9188']
    metric_relabel_configs:
      # Keep important metrics longer
      - source_labels: [__name__]
        regex: 'opshub_(active_users|model_usage|error_rate)'
        target_label: retention_class
        replacement: 'critical'
      
      # Drop noisy metrics quickly
      - source_labels: [__name__]
        regex: 'opshub_debug_.*'
        action: drop

  # GPU metrics - high priority
  - job_name: 'dcgm-exporter'
    scrape_interval: 5s  # High frequency for GPU
    static_configs:
      - targets: ['dcgm-exporter:9400']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'DCGM_.*'
        target_label: retention_class
        replacement: 'gpu_critical'

  # Container metrics
  - job_name: 'cadvisor'
    scrape_interval: 15s
    static_configs:
      - targets: ['cadvisor:8080']
    metric_relabel_configs:
      # Keep container CPU/Memory metrics longer
      - source_labels: [__name__]
        regex: 'container_(cpu|memory)_.*'
        target_label: retention_class
        replacement: 'container_important'
      
      # Drop filesystem metrics for tmpfs
      - source_labels: [__name__, device]
        regex: 'container_fs_.*;tmpfs'
        action: drop

  # Node metrics
  - job_name: 'node-exporter'
    scrape_interval: 15s
    static_configs:
      - targets: ['node-exporter:9100']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_(cpu|memory|load|disk)_.*'
        target_label: retention_class
        replacement: 'system_critical'

# Remote write for long-term storage (optional)
# remote_write:
#   - url: "http://long-term-storage:9201/write"
#     write_relabel_configs:
#       - source_labels: [retention_class]
#         regex: '(critical|gpu_critical)'
#         action: keep

# Storage configuration
storage:
  tsdb:
    # Retention based on importance
    retention.time: 30d        # Default retention
    retention.size: 50GB       # Size-based retention
    
    # Performance tuning for p3.24xlarge
    min-block-duration: 2h     # Minimum block duration
    max-block-duration: 36h    # Maximum block duration
    wal-compression: true      # Enable WAL compression
    
    # Compaction settings
    max-block-chunk-segment-size: 1GB
    enable-overlapping-blocks: false

# Recording rules for different retention periods
EOF

    # Create retention rules file
    cat > "${PROMETHEUS_CONFIG_DIR}/retention_rules.yml" << 'EOF'
groups:
  # Critical metrics - keep raw data for 90 days
  - name: critical_metrics_raw
    interval: 30s
    rules:
      - record: critical:opshub_active_users
        expr: opshub_active_users
      
      - record: critical:gpu_utilization
        expr: DCGM_FI_DEV_GPU_UTIL
      
      - record: critical:container_cpu_usage
        expr: rate(container_cpu_usage_seconds_total[5m])

  # Hourly aggregations - keep for 1 year
  - name: hourly_aggregations
    interval: 1h
    rules:
      - record: hourly:avg_active_users
        expr: avg_over_time(opshub_active_users[1h])
      
      - record: hourly:max_gpu_util
        expr: max_over_time(DCGM_FI_DEV_GPU_UTIL[1h])
      
      - record: hourly:avg_cpu_usage
        expr: avg_over_time(node_cpu_seconds_total[1h])
      
      - record: hourly:avg_memory_usage
        expr: avg_over_time(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes[1h])

  # Daily aggregations - keep for 2 years
  - name: daily_aggregations
    interval: 24h
    rules:
      - record: daily:peak_users
        expr: max_over_time(hourly:avg_active_users[24h])
      
      - record: daily:avg_gpu_util
        expr: avg_over_time(hourly:max_gpu_util[24h])
      
      - record: daily:model_usage_total
        expr: increase(opshub_model_requests_total[24h])

  # Weekly aggregations - keep for 5 years
  - name: weekly_aggregations
    interval: 168h  # 7 days
    rules:
      - record: weekly:avg_peak_users
        expr: avg_over_time(daily:peak_users[7d])
      
      - record: weekly:total_model_requests
        expr: sum_over_time(daily:model_usage_total[7d])
EOF

    # Create aggregation rules for performance
    cat > "${PROMETHEUS_CONFIG_DIR}/aggregation_rules.yml" << 'EOF'
groups:
  # User activity aggregations
  - name: user_activity
    interval: 1m
    rules:
      - record: opshub:active_sessions_by_model
        expr: sum by (model_name) (opshub_active_sessions)
      
      - record: opshub:requests_per_minute
        expr: rate(opshub_requests_total[1m]) * 60
      
      - record: opshub:error_rate
        expr: rate(opshub_errors_total[5m]) / rate(opshub_requests_total[5m]) * 100

  # Container resource aggregations  
  - name: container_resources
    interval: 30s
    rules:
      - record: container:cpu_usage_percent
        expr: rate(container_cpu_usage_seconds_total[1m]) * 100
      
      - record: container:memory_usage_percent
        expr: (container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100
      
      - record: container:network_io_total
        expr: rate(container_network_receive_bytes_total[1m]) + rate(container_network_transmit_bytes_total[1m])

  # System health aggregations
  - name: system_health
    interval: 1m
    rules:
      - record: system:cpu_usage_percent
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
      
      - record: system:memory_usage_percent
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
      
      - record: system:disk_usage_percent
        expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
EOF

    echo "✅ Prometheus retention configuration created"
}

# Function to create retention cleanup script
create_cleanup_script() {
    echo "🧹 Creating automated cleanup script..."
    
    cat > "/opt/obs-stack/cleanup-retention.sh" << 'EOF'
#!/bin/bash

# Automated Retention Cleanup Script
# Runs daily to maintain optimal storage usage

set -e

LOG_FILE="/var/log/obs-stack-cleanup.log"
OPSHUB_DB="/opt/obs-stack/opshub_data/opshub.db"
PROMETHEUS_DATA="/opt/obs-stack/prometheus_data"
LOKI_DATA="/opt/obs-stack/loki_data"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Cleanup OpsHub database
cleanup_opshub() {
    log "Starting OpsHub database cleanup..."
    
    # Archive old sessions (older than 30 days)
    sqlite3 "$OPSHUB_DB" "
        DELETE FROM user_sessions 
        WHERE created_at < datetime('now', '-30 days');
    "
    
    # Clean old performance metrics (older than 180 days)
    sqlite3 "$OPSHUB_DB" "
        DELETE FROM performance_metrics 
        WHERE timestamp < datetime('now', '-180 days');
    "
    
    # Keep only recent container status (60 days)
    sqlite3 "$OPSHUB_DB" "
        DELETE FROM container_status 
        WHERE last_seen < datetime('now', '-60 days');
    "
    
    # Vacuum database for space reclaim
    sqlite3 "$OPSHUB_DB" "VACUUM;"
    
    log "OpsHub cleanup completed"
}

# Monitor disk usage
check_disk_space() {
    DISK_USAGE=$(df /opt/obs-stack | tail -1 | awk '{print $5}' | sed 's/%//')
    
    log "Current disk usage: ${DISK_USAGE}%"
    
    if [ "$DISK_USAGE" -gt 85 ]; then
        log "WARNING: Disk usage above 85%"
        
        # Emergency cleanup - reduce retention
        log "Performing emergency cleanup..."
        
        # Reduce Prometheus retention to 15 days
        docker exec prometheus promtool tsdb delete --dry-run --match='{__name__!~"critical:.*"}' --start="$(date -d '15 days ago' --iso-8601)"
        
        # Clean old Loki chunks
        find "$LOKI_DATA/chunks" -type f -mtime +15 -delete
        
        log "Emergency cleanup completed"
    fi
}

# Generate retention report
generate_report() {
    log "Generating retention report..."
    
    REPORT_FILE="/tmp/retention-report-$(date +%Y%m%d).txt"
    
    cat > "$REPORT_FILE" << EOL
# Retention Cleanup Report - $(date)

## Database Sizes
$(du -sh "$OPSHUB_DB" 2>/dev/null || echo "OpsHub DB: Not found")
$(du -sh "$PROMETHEUS_DATA" 2>/dev/null || echo "Prometheus Data: Not found")
$(du -sh "$LOKI_DATA" 2>/dev/null || echo "Loki Data: Not found")

## Disk Usage
$(df -h /opt/obs-stack)

## Container Status
$(docker-compose -f /opt/obs-stack/docker-compose.yml ps)

## Recent Log Counts
OpsHub Logs: $(sqlite3 "$OPSHUB_DB" "SELECT COUNT(*) FROM logs;" 2>/dev/null || echo "N/A")
User Sessions: $(sqlite3 "$OPSHUB_DB" "SELECT COUNT(*) FROM user_sessions;" 2>/dev/null || echo "N/A")
Performance Metrics: $(sqlite3 "$OPSHUB_DB" "SELECT COUNT(*) FROM performance_metrics;" 2>/dev/null || echo "N/A")

## Cleanup Actions Taken
$(tail -20 "$LOG_FILE")
EOL
    
    log "Report generated: $REPORT_FILE"
}

# Main cleanup function
main() {
    log "=== Starting retention cleanup ==="
    
    cleanup_opshub
    check_disk_space
    generate_report
    
    log "=== Retention cleanup completed ==="
}

# Run cleanup
main "$@"
EOF

    chmod +x "/opt/obs-stack/cleanup-retention.sh"
    echo "✅ Cleanup script created"
}

# Function to setup cron jobs
setup_cron_jobs() {
    echo "⏰ Setting up automated retention cron jobs..."
    
    # Create cron job for daily cleanup
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/obs-stack/cleanup-retention.sh") | crontab -
    
    # Create cron job for weekly optimization
    (crontab -l 2>/dev/null; echo "0 3 * * 0 docker exec prometheus promtool tsdb snapshot /prometheus/snapshots") | crontab -
    
    # Create cron job for monthly archival
    (crontab -l 2>/dev/null; echo "0 4 1 * * tar -czf /opt/backups/obs-stack-$(date +%Y%m).tar.gz /opt/obs-stack/") | crontab -
    
    echo "✅ Cron jobs configured:"
    echo "  • Daily cleanup at 2:00 AM"
    echo "  • Weekly optimization at 3:00 AM (Sunday)"
    echo "  • Monthly archival at 4:00 AM (1st of month)"
}

# Function to update docker-compose with retention settings
update_docker_compose() {
    echo "🐳 Updating docker-compose with retention settings..."
    
    # Backup original docker-compose.yml
    cp /opt/obs-stack/docker-compose.yml /opt/obs-stack/docker-compose.yml.bak
    
    # Update OpsHub with retention environment variables
    cat >> /opt/obs-stack/docker-compose.yml << 'EOF'

# Additional retention configuration
x-retention-config: &retention-config
  OPS_RETENTION_ACTIVE_DAYS: "14"
  OPS_RETENTION_ARCHIVE_DAYS: "90"
  OPS_RETENTION_PURGE_DAYS: "365"
  OPS_CLEANUP_SCHEDULE: "0 2 * * *"
  OPS_MAX_LOG_SIZE_MB: "1000"
  OPS_COMPRESSION_ENABLED: "true"
  OPS_ARCHIVE_PATH: "/data/archives"

EOF

    echo "✅ Docker compose updated with retention settings"
}

# Main execution
main() {
    echo "🚀 Starting log retention configuration..."
    
    # Create backup directory
    mkdir -p /opt/backups
    mkdir -p /opt/obs-stack/archives
    
    configure_opshub_retention
    configure_loki_retention
    configure_prometheus_retention
    create_cleanup_script
    setup_cron_jobs
    update_docker_compose
    
    echo ""
    echo "🎉 Log retention configuration completed!"
    echo ""
    echo "📚 Configured Retention Policies:"
    echo "  • Active sessions: 14 days"
    echo "  • Archived sessions: 90 days"
    echo "  • Error logs: 365 days"
    echo "  • Performance metrics: 180 days"
    echo "  • GPU metrics: 90 days (high priority)"
    echo "  • Container logs: 30 days"
    echo "  • Debug logs: 7 days"
    echo ""
    echo "🧹 Automated Cleanup:"
    echo "  • Daily cleanup at 2:00 AM"
    echo "  • Weekly optimization at 3:00 AM"
    echo "  • Monthly archival at 4:00 AM"
    echo "  • Emergency cleanup when disk >85%"
    echo ""
    echo "📊 Storage Optimization:"
    echo "  • Database compression enabled"
    echo "  • Automatic archiving"
    echo "  • Prometheus recording rules"
    echo "  • Loki log compression"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Restart the stack: docker-compose down && docker-compose up -d"
    echo "  2. Monitor cleanup logs: tail -f /var/log/obs-stack-cleanup.log"
    echo "  3. Check retention reports in /tmp/retention-report-*.txt"
    echo "  4. Adjust retention periods in configs if needed"
}

# Run the configuration
main "$@"
