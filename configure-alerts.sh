#!/bin/bash

# 🚨 Grafana Alert Configuration Script
# This script configures comprehensive alerts for your monitoring stack

set -e

GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
API_KEY_FILE="/tmp/grafana_api_key.txt"

echo "🚨 Setting up Grafana alerts for critical monitoring..."

# Function to create API key
create_api_key() {
    echo "Creating Grafana API key..."
    
    API_KEY=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"name":"alert-config","role":"Admin"}' \
        -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
        "${GRAFANA_URL}/api/auth/keys" | jq -r '.key')
    
    if [ "$API_KEY" = "null" ] || [ -z "$API_KEY" ]; then
        echo "❌ Failed to create API key. Using basic auth..."
        AUTH_HEADER="Authorization: Basic $(echo -n ${GRAFANA_USER}:${GRAFANA_PASS} | base64)"
    else
        echo "✅ API key created successfully"
        AUTH_HEADER="Authorization: Bearer $API_KEY"
    fi
}

# Function to create notification channel
create_notification_channel() {
    echo "📧 Creating notification channels..."
    
    # Email notification (configure with your SMTP)
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "name": "email-alerts",
            "type": "email",
            "settings": {
                "addresses": "admin@yourdomain.com",
                "singleEmail": true,
                "subject": "[ALERT] {{.GroupLabels.alertname}} - {{.CommonLabels.instance}}",
                "body": "Alert: {{.GroupLabels.alertname}}\nSeverity: {{.CommonLabels.severity}}\nInstance: {{.CommonLabels.instance}}\nDescription: {{.CommonAnnotations.description}}\nTime: {{.FiringAlerts | len}} firing, {{.ResolvedAlerts | len}} resolved"
            }
        }' \
        "${GRAFANA_URL}/api/alert-notifications"
    
    # Slack notification (configure with your webhook)
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "name": "slack-alerts",
            "type": "slack",
            "settings": {
                "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
                "username": "Grafana",
                "channel": "#alerts",
                "title": "{{.GroupLabels.alertname}}",
                "text": "{{range .Alerts}}{{.Annotations.description}}{{end}}",
                "iconEmoji": ":exclamation:",
                "color": "danger"
            }
        }' \
        "${GRAFANA_URL}/api/alert-notifications"
    
    echo "✅ Notification channels created"
}

# Function to create alert rules
create_alert_rules() {
    echo "⚠️ Creating alert rules..."
    
    # 1. High CPU Usage Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "High CPU Usage",
                "message": "CPU usage is above 80% for more than 5 minutes",
                "frequency": "30s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [80],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "no_data",
                "for": "5m"
            },
            "notificationChannels": ["email-alerts", "slack-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    # 2. High Memory Usage Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "High Memory Usage",
                "message": "Memory usage is above 85% for more than 5 minutes",
                "frequency": "30s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [85],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "no_data",
                "for": "5m"
            },
            "notificationChannels": ["email-alerts", "slack-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    # 3. Container Down Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "Container Down",
                "message": "Critical container is not running",
                "frequency": "30s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "up{job=\"cadvisor\"} == 0",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [0.5],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "alerting",
                "for": "1m"
            },
            "notificationChannels": ["email-alerts", "slack-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    # 4. High GPU Usage Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "High GPU Usage",
                "message": "GPU utilization is above 90% for more than 10 minutes",
                "frequency": "30s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "DCGM_FI_DEV_GPU_UTIL > 90",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [90],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "no_data",
                "for": "10m"
            },
            "notificationChannels": ["email-alerts", "slack-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    # 5. Disk Space Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "Low Disk Space",
                "message": "Disk space is below 15% free",
                "frequency": "60s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "(node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\"}) * 100 < 15",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [0.5],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "no_data",
                "for": "5m"
            },
            "notificationChannels": ["email-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    # 6. High User Activity Alert
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alert": {
                "name": "High User Activity",
                "message": "Active user sessions exceed 250",
                "frequency": "60s",
                "conditions": [
                    {
                        "query": {
                            "queryType": "",
                            "refId": "A",
                            "model": {
                                "expr": "opshub_active_users > 250",
                                "intervalMs": 1000,
                                "maxDataPoints": 43200,
                                "refId": "A"
                            }
                        },
                        "reducer": {
                            "params": [],
                            "type": "last"
                        },
                        "evaluator": {
                            "params": [250],
                            "type": "gt"
                        }
                    }
                ],
                "executionErrorState": "alerting",
                "noDataState": "no_data",
                "for": "5m"
            },
            "notificationChannels": ["email-alerts"]
        }' \
        "${GRAFANA_URL}/api/alerts"
    
    echo "✅ Alert rules created successfully"
}

# Function to configure alert manager settings
configure_alertmanager() {
    echo "⚙️ Configuring alert manager settings..."
    
    curl -s -X PUT \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{
            "alertmanager": {
                "enabled": true,
                "configSource": "file",
                "settings": {
                    "alertmanagerUrl": "http://localhost:9093",
                    "basicAuthUser": "",
                    "basicAuthPassword": "",
                    "timeout": "30s"
                }
            }
        }' \
        "${GRAFANA_URL}/api/admin/settings"
    
    echo "✅ Alert manager configured"
}

# Main execution
main() {
    echo "🚀 Starting Grafana alert configuration..."
    
    # Wait for Grafana to be ready
    echo "⏳ Waiting for Grafana to be ready..."
    until curl -s -f "${GRAFANA_URL}/api/health" > /dev/null; do
        echo "Waiting for Grafana..."
        sleep 5
    done
    
    create_api_key
    create_notification_channel
    create_alert_rules
    configure_alertmanager
    
    echo ""
    echo "🎉 Alert configuration completed successfully!"
    echo ""
    echo "📊 Configured Alerts:"
    echo "  • High CPU Usage (>80% for 5min)"
    echo "  • High Memory Usage (>85% for 5min)"
    echo "  • Container Down (immediate)"
    echo "  • High GPU Usage (>90% for 10min)"
    echo "  • Low Disk Space (<15% free)"
    echo "  • High User Activity (>250 users)"
    echo ""
    echo "📧 Notification Channels:"
    echo "  • Email alerts (configure SMTP in Grafana)"
    echo "  • Slack alerts (configure webhook URL)"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Configure SMTP settings in Grafana for email alerts"
    echo "  2. Add Slack webhook URL for Slack notifications"
    echo "  3. Test alerts with: curl http://localhost:3001/api/alerts/test"
    echo "  4. View alerts in Grafana: http://your-ip:3001/alerting"
}

# Run the configuration
main "$@"
