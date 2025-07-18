#!/usr/bin/env bash
set -e

echo "Starting OpsHub Docker Logger & Monitor..."

# Install the package in development mode
pip install -e .

# Create data directory
mkdir -p /data

# Set environment variables
export PYTHONPATH="${PYTHONPATH}:/app"
export OPS_DATA_DIR="/data"

# Display configuration
echo "Configuration:"
echo "  OPS_DISCOVER: ${OPS_DISCOVER:-all}"
echo "  OPS_INCLUDE_REGEX: ${OPS_INCLUDE_REGEX:-.*}"
echo "  OPS_EXCLUDE_REGEX: ${OPS_EXCLUDE_REGEX:-^$}"
echo "  OPS_INCLUDE_STOPPED: ${OPS_INCLUDE_STOPPED:-false}"
echo "  OPS_RETENTION_ACTIVE_DAYS: ${OPS_RETENTION_ACTIVE_DAYS:-7}"
echo "  Data directory: /data"

# Initialize database
echo "Initializing database..."
python -c "from opshub.database import init_db; init_db()"

# Run FastAPI server with background workers
echo "Starting OpsHub server on port 8089..."
echo "API endpoints:"
echo "  http://localhost:8089/health - Health check"
echo "  http://localhost:8089/metrics - Prometheus metrics"
echo "  http://localhost:8089/containers/status - Container status"
echo "  http://localhost:8089/users/sessions - User sessions"
echo "  http://localhost:8089/metrics/performance - Performance metrics"

exec python -m opshub.server
