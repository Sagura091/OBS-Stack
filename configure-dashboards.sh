#!/bin/bash

# 📊 Custom Grafana Dashboards Setup Script
# Creates comprehensive dashboards for your specific use cases

set -e

GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
DASHBOARD_DIR="/opt/obs-stack/grafana/dashboards"

echo "📊 Creating custom Grafana dashboards for your environment..."

# Function to create API key
create_api_key() {
    echo "Creating Grafana API key..."
    
    API_KEY=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"name":"dashboard-config","role":"Admin"}' \
        -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
        "${GRAFANA_URL}/api/auth/keys" | jq -r '.key')
    
    if [ "$API_KEY" = "null" ] || [ -z "$API_KEY" ]; then
        echo "Using basic auth..."
        AUTH_HEADER="Authorization: Basic $(echo -n ${GRAFANA_USER}:${GRAFANA_PASS} | base64)"
    else
        echo "✅ API key created successfully"
        AUTH_HEADER="Authorization: Bearer $API_KEY"
    fi
}

# Function to create executive summary dashboard
create_executive_dashboard() {
    echo "📈 Creating Executive Summary Dashboard..."
    
    mkdir -p "$DASHBOARD_DIR"
    
    cat > "$DASHBOARD_DIR/executive-summary.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Executive Summary - OpenWebUI Monitoring",
    "tags": ["executive", "summary", "overview"],
    "style": "dark",
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-24h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "📊 Key Performance Indicators",
        "type": "stat",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "opshub_active_users",
            "legendFormat": "Active Users",
            "refId": "A"
          },
          {
            "expr": "rate(opshub_requests_total[5m]) * 60",
            "legendFormat": "Requests/Min",
            "refId": "B"
          },
          {
            "expr": "avg(DCGM_FI_DEV_GPU_UTIL)",
            "legendFormat": "GPU Usage %",
            "refId": "C"
          },
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %",
            "refId": "D"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {"displayMode": "basic"},
            "mappings": [],
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 2,
        "title": "👥 User Activity Trends (24h)",
        "type": "timeseries",
        "gridPos": {"h": 9, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "opshub_active_users",
            "legendFormat": "Active Users",
            "refId": "A"
          },
          {
            "expr": "opshub_peak_users",
            "legendFormat": "Peak Users",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {
              "drawStyle": "line",
              "lineInterpolation": "linear",
              "barAlignment": 0,
              "lineWidth": 2,
              "fillOpacity": 10,
              "gradientMode": "none",
              "spanNulls": false,
              "insertNulls": false,
              "showPoints": "never",
              "pointSize": 5,
              "stacking": {"mode": "none", "group": "A"},
              "axisPlacement": "auto",
              "axisLabel": "",
              "scaleDistribution": {"type": "linear"},
              "hideFrom": {"legend": false, "tooltip": false, "vis": false},
              "thresholdsStyle": {"mode": "off"}
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "red", "value": 80}
              ]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 3,
        "title": "🎮 GPU Utilization",
        "type": "gauge",
        "gridPos": {"h": 9, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "avg(DCGM_FI_DEV_GPU_UTIL)",
            "legendFormat": "GPU Usage",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "custom": {
              "displayMode": "basic",
              "orientation": "auto",
              "reduceOptions": {
                "values": false,
                "calcs": ["lastNotNull"],
                "fields": ""
              }
            },
            "mappings": [],
            "max": 100,
            "min": 0,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 60},
                {"color": "orange", "value": 80},
                {"color": "red", "value": 95}
              ]
            },
            "unit": "percent"
          }
        }
      },
      {
        "id": 4,
        "title": "🤖 Model Usage Distribution",
        "type": "piechart",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 17},
        "targets": [
          {
            "expr": "sum by (model_name) (opshub_model_requests_total)",
            "legendFormat": "{{model_name}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {
              "displayMode": "basic",
              "hideFrom": {"legend": false, "tooltip": false, "vis": false}
            },
            "mappings": [],
            "unit": "short"
          }
        }
      },
      {
        "id": 5,
        "title": "📊 System Resource Overview",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 17},
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU %",
            "refId": "A"
          },
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory %",
            "refId": "B"
          },
          {
            "expr": "avg(DCGM_FI_DEV_GPU_UTIL)",
            "legendFormat": "GPU %",
            "refId": "C"
          }
        ]
      },
      {
        "id": 6,
        "title": "⚡ Performance Metrics",
        "type": "table",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 25},
        "targets": [
          {
            "expr": "avg_over_time(opshub_response_time_seconds[1h]) * 1000",
            "legendFormat": "Avg Response Time (ms)",
            "refId": "A",
            "format": "table"
          },
          {
            "expr": "rate(opshub_errors_total[5m]) / rate(opshub_requests_total[5m]) * 100",
            "legendFormat": "Error Rate %",
            "refId": "B",
            "format": "table"
          },
          {
            "expr": "opshub_queue_size",
            "legendFormat": "Queue Size",
            "refId": "C",
            "format": "table"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "displayMode": "basic",
              "inspect": false
            },
            "mappings": [],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "red", "value": 80}
              ]
            }
          }
        }
      }
    ],
    "time": {"from": "now-24h", "to": "now"},
    "timepicker": {},
    "timezone": "",
    "refresh": "30s",
    "schemaVersion": 27,
    "version": 1
  }
}
EOF

    # Import dashboard
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d @"$DASHBOARD_DIR/executive-summary.json" \
        "${GRAFANA_URL}/api/dashboards/db"
    
    echo "✅ Executive Summary Dashboard created"
}

# Function to create detailed monitoring dashboard
create_detailed_monitoring_dashboard() {
    echo "🔍 Creating Detailed Monitoring Dashboard..."
    
    cat > "$DASHBOARD_DIR/detailed-monitoring.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Detailed System Monitoring - p3.24xlarge",
    "tags": ["detailed", "monitoring", "technical"],
    "style": "dark",
    "timezone": "browser",
    "refresh": "10s",
    "time": {"from": "now-6h", "to": "now"},
    "panels": [
      {
        "id": 1,
        "title": "🖥️ CPU Usage by Core",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "100 - (avg by (cpu) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU {{cpu}}",
            "refId": "A"
          }
        ]
      },
      {
        "id": 2,
        "title": "🧠 Memory Usage Details",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes",
            "legendFormat": "Used Memory",
            "refId": "A"
          },
          {
            "expr": "node_memory_Buffers_bytes",
            "legendFormat": "Buffers",
            "refId": "B"
          },
          {
            "expr": "node_memory_Cached_bytes",
            "legendFormat": "Cached",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {"unit": "bytes"}
        }
      },
      {
        "id": 3,
        "title": "🎮 GPU Metrics - All Cards",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "DCGM_FI_DEV_GPU_UTIL",
            "legendFormat": "GPU {{gpu}} Utilization",
            "refId": "A"
          },
          {
            "expr": "DCGM_FI_DEV_MEM_COPY_UTIL",
            "legendFormat": "GPU {{gpu}} Memory Util",
            "refId": "B"
          },
          {
            "expr": "DCGM_FI_DEV_GPU_TEMP",
            "legendFormat": "GPU {{gpu}} Temperature",
            "refId": "C"
          }
        ]
      },
      {
        "id": 4,
        "title": "📊 Container Resource Usage",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total[5m]) * 100",
            "legendFormat": "{{name}} CPU %",
            "refId": "A"
          }
        ]
      },
      {
        "id": 5,
        "title": "💾 Container Memory Usage",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16},
        "targets": [
          {
            "expr": "container_memory_working_set_bytes",
            "legendFormat": "{{name}} Memory",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {"unit": "bytes"}
        }
      },
      {
        "id": 6,
        "title": "🌐 Network Traffic",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 24},
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total[5m])",
            "legendFormat": "{{device}} RX",
            "refId": "A"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total[5m])",
            "legendFormat": "{{device}} TX",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {"unit": "Bps"}
        }
      },
      {
        "id": 7,
        "title": "💿 Disk I/O",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 24},
        "targets": [
          {
            "expr": "rate(node_disk_read_bytes_total[5m])",
            "legendFormat": "{{device}} Read",
            "refId": "A"
          },
          {
            "expr": "rate(node_disk_written_bytes_total[5m])",
            "legendFormat": "{{device}} Write",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {"unit": "Bps"}
        }
      }
    ]
  }
}
EOF

    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d @"$DASHBOARD_DIR/detailed-monitoring.json" \
        "${GRAFANA_URL}/api/dashboards/db"
    
    echo "✅ Detailed Monitoring Dashboard created"
}

# Function to create user analytics dashboard
create_user_analytics_dashboard() {
    echo "👥 Creating User Analytics Dashboard..."
    
    cat > "$DASHBOARD_DIR/user-analytics.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "OpenWebUI User Analytics - 200+ Users",
    "tags": ["users", "analytics", "openwebui"],
    "style": "dark",
    "timezone": "browser",
    "refresh": "1m",
    "time": {"from": "now-24h", "to": "now"},
    "panels": [
      {
        "id": 1,
        "title": "📈 User Growth Metrics",
        "type": "stat",
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "opshub_total_users",
            "legendFormat": "Total Registered Users",
            "refId": "A"
          },
          {
            "expr": "opshub_active_users",
            "legendFormat": "Currently Active",
            "refId": "B"
          },
          {
            "expr": "max_over_time(opshub_active_users[24h])",
            "legendFormat": "24h Peak",
            "refId": "C"
          },
          {
            "expr": "increase(opshub_new_users_total[24h])",
            "legendFormat": "New Users (24h)",
            "refId": "D"
          }
        ]
      },
      {
        "id": 2,
        "title": "👥 Active Users Timeline",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 16, "x": 0, "y": 6},
        "targets": [
          {
            "expr": "opshub_active_users",
            "legendFormat": "Active Users",
            "refId": "A"
          },
          {
            "expr": "opshub_concurrent_sessions",
            "legendFormat": "Concurrent Sessions",
            "refId": "B"
          }
        ]
      },
      {
        "id": 3,
        "title": "⚡ User Activity Heatmap",
        "type": "heatmap",
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 6},
        "targets": [
          {
            "expr": "sum by (hour) (opshub_requests_per_hour)",
            "legendFormat": "Requests",
            "refId": "A"
          }
        ]
      },
      {
        "id": 4,
        "title": "🤖 Model Usage by Users",
        "type": "bargauge",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 14},
        "targets": [
          {
            "expr": "topk(10, sum by (model_name) (opshub_model_requests_total))",
            "legendFormat": "{{model_name}}",
            "refId": "A"
          }
        ]
      },
      {
        "id": 5,
        "title": "📊 Session Duration Distribution",
        "type": "histogram",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 14},
        "targets": [
          {
            "expr": "histogram_quantile(0.50, opshub_session_duration_seconds_bucket)",
            "legendFormat": "50th percentile",
            "refId": "A"
          },
          {
            "expr": "histogram_quantile(0.90, opshub_session_duration_seconds_bucket)",
            "legendFormat": "90th percentile",
            "refId": "B"
          },
          {
            "expr": "histogram_quantile(0.99, opshub_session_duration_seconds_bucket)",
            "legendFormat": "99th percentile",
            "refId": "C"
          }
        ]
      },
      {
        "id": 6,
        "title": "🔥 Top Active Users",
        "type": "table",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 22},
        "targets": [
          {
            "expr": "topk(20, sum by (user_id) (opshub_user_requests_total))",
            "legendFormat": "{{user_id}}",
            "refId": "A",
            "format": "table"
          }
        ]
      },
      {
        "id": 7,
        "title": "📱 Usage by Platform",
        "type": "piechart",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 22},
        "targets": [
          {
            "expr": "sum by (platform) (opshub_sessions_by_platform)",
            "legendFormat": "{{platform}}",
            "refId": "A"
          }
        ]
      },
      {
        "id": 8,
        "title": "⚠️ Error Rates by User",
        "type": "timeseries",
        "gridPos": {"h": 6, "w": 24, "x": 0, "y": 30},
        "targets": [
          {
            "expr": "rate(opshub_user_errors_total[5m]) / rate(opshub_user_requests_total[5m]) * 100",
            "legendFormat": "Error Rate %",
            "refId": "A"
          }
        ]
      }
    ]
  }
}
EOF

    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d @"$DASHBOARD_DIR/user-analytics.json" \
        "${GRAFANA_URL}/api/dashboards/db"
    
    echo "✅ User Analytics Dashboard created"
}

# Function to create capacity planning dashboard
create_capacity_planning_dashboard() {
    echo "📈 Creating Capacity Planning Dashboard..."
    
    cat > "$DASHBOARD_DIR/capacity-planning.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Capacity Planning & Forecasting",
    "tags": ["capacity", "planning", "forecasting"],
    "style": "dark",
    "timezone": "browser",
    "refresh": "5m",
    "time": {"from": "now-7d", "to": "now"},
    "panels": [
      {
        "id": 1,
        "title": "📊 Resource Utilization Trends (7 days)",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "avg_over_time(system:cpu_usage_percent[1h])",
            "legendFormat": "CPU Usage %",
            "refId": "A"
          },
          {
            "expr": "avg_over_time(system:memory_usage_percent[1h])",
            "legendFormat": "Memory Usage %",
            "refId": "B"
          },
          {
            "expr": "avg_over_time(DCGM_FI_DEV_GPU_UTIL[1h])",
            "legendFormat": "GPU Usage %",
            "refId": "C"
          }
        ]
      },
      {
        "id": 2,
        "title": "👥 User Growth Projection",
        "type": "timeseries", 
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "deriv(opshub_total_users[1h]) * 24 * 7",
            "legendFormat": "Weekly Growth Rate",
            "refId": "A"
          },
          {
            "expr": "predict_linear(opshub_total_users[7d], 7*24*3600)",
            "legendFormat": "7-day Forecast",
            "refId": "B"
          }
        ]
      },
      {
        "id": 3,
        "title": "⚡ Performance vs Load",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "opshub_response_time_seconds * 1000",
            "legendFormat": "Response Time (ms)",
            "refId": "A"
          },
          {
            "expr": "rate(opshub_requests_total[1m]) * 60",
            "legendFormat": "Requests/min",
            "refId": "B"
          }
        ]
      },
      {
        "id": 4,
        "title": "💾 Storage Growth Prediction",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "predict_linear(node_filesystem_size_bytes - node_filesystem_avail_bytes[7d], 30*24*3600)",
            "legendFormat": "30-day Storage Forecast",
            "refId": "A"
          },
          {
            "expr": "node_filesystem_size_bytes - node_filesystem_avail_bytes",
            "legendFormat": "Current Usage",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {"unit": "bytes"}
        }
      },
      {
        "id": 5,
        "title": "🎯 Resource Thresholds",
        "type": "stat",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16},
        "targets": [
          {
            "expr": "(200 - opshub_active_users) / 200 * 100",
            "legendFormat": "User Capacity Remaining %",
            "refId": "A"
          },
          {
            "expr": "100 - avg(DCGM_FI_DEV_GPU_UTIL)",
            "legendFormat": "GPU Capacity Remaining %",
            "refId": "B"
          },
          {
            "expr": "100 - system:memory_usage_percent",
            "legendFormat": "Memory Capacity Remaining %",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 20},
                {"color": "green", "value": 40}
              ]
            }
          }
        }
      },
      {
        "id": 6,
        "title": "📈 Peak Usage Analysis",
        "type": "table",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 24},
        "targets": [
          {
            "expr": "max_over_time(opshub_active_users[24h])",
            "legendFormat": "24h Peak Users",
            "refId": "A",
            "format": "table"
          },
          {
            "expr": "max_over_time(DCGM_FI_DEV_GPU_UTIL[24h])",
            "legendFormat": "24h Peak GPU %",
            "refId": "B",
            "format": "table"
          },
          {
            "expr": "max_over_time(system:cpu_usage_percent[24h])",
            "legendFormat": "24h Peak CPU %",
            "refId": "C",
            "format": "table"
          }
        ]
      }
    ]
  }
}
EOF

    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d @"$DASHBOARD_DIR/capacity-planning.json" \
        "${GRAFANA_URL}/api/dashboards/db"
    
    echo "✅ Capacity Planning Dashboard created"
}

# Function to create dashboard folders
create_dashboard_folders() {
    echo "📁 Creating dashboard folders..."
    
    # Create Executive folder
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{"title":"Executive Dashboards"}' \
        "${GRAFANA_URL}/api/folders"
    
    # Create Technical folder
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{"title":"Technical Monitoring"}' \
        "${GRAFANA_URL}/api/folders"
    
    # Create Analytics folder
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{"title":"User Analytics"}' \
        "${GRAFANA_URL}/api/folders"
    
    echo "✅ Dashboard folders created"
}

# Function to setup dashboard permissions
setup_dashboard_permissions() {
    echo "🔐 Setting up dashboard permissions..."
    
    # Create read-only user for executives
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "name": "Executive View",
            "email": "executive@company.com",
            "login": "executive",
            "password": "executive123",
            "orgId": 1
        }' \
        "${GRAFANA_URL}/api/admin/users"
    
    echo "✅ Dashboard permissions configured"
}

# Main execution
main() {
    echo "🚀 Starting custom dashboard creation..."
    
    # Wait for Grafana to be ready
    echo "⏳ Waiting for Grafana to be ready..."
    until curl -s -f "${GRAFANA_URL}/api/health" > /dev/null; do
        echo "Waiting for Grafana..."
        sleep 5
    done
    
    create_api_key
    create_dashboard_folders
    create_executive_dashboard
    create_detailed_monitoring_dashboard
    create_user_analytics_dashboard
    create_capacity_planning_dashboard
    setup_dashboard_permissions
    
    echo ""
    echo "🎉 Custom dashboards created successfully!"
    echo ""
    echo "📊 Available Dashboards:"
    echo "  • Executive Summary - High-level KPIs and business metrics"
    echo "  • Detailed Monitoring - Technical system metrics for p3.24xlarge"
    echo "  • User Analytics - OpenWebUI user behavior and patterns"
    echo "  • Capacity Planning - Growth forecasting and resource planning"
    echo ""
    echo "🔗 Access URLs:"
    echo "  • Grafana: http://your-instance-ip:3001"
    echo "  • Login: admin/admin"
    echo ""
    echo "👤 User Accounts:"
    echo "  • Admin: admin/admin (full access)"
    echo "  • Executive: executive/executive123 (read-only)"
    echo ""
    echo "📁 Dashboard Organization:"
    echo "  • Executive Dashboards - C-level overview"
    echo "  • Technical Monitoring - DevOps and system admin"
    echo "  • User Analytics - Product and user experience teams"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Customize dashboard variables for your environment"
    echo "  2. Set up SMTP for dashboard sharing via email"
    echo "  3. Configure dashboard annotations for deployments"
    echo "  4. Create scheduled dashboard reports"
}

# Run the configuration
main "$@"
