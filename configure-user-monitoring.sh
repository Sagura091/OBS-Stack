#!/bin/bash

# 👥 OpenWebUI User Monitoring Setup Script
# Configures comprehensive user tracking for 200+ users

set -e

OPSHUB_DIR="/opt/obs-stack/opshub"
GRAFANA_URL="http://localhost:3001"

echo "👥 Setting up OpenWebUI user monitoring for 200+ users..."

# Function to configure user tracking in OpsHub
configure_user_tracking() {
    echo "🔧 Configuring user tracking system..."
    
    cat > "${OPSHUB_DIR}/user_tracking.py" << 'EOF'
"""
OpenWebUI User Tracking Module
Monitors and analyzes user behavior for 200+ users
"""

import asyncio
import json
import sqlite3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass
from collections import defaultdict

@dataclass
class UserSession:
    """User session data structure"""
    user_id: str
    session_id: str
    start_time: datetime
    last_activity: datetime
    ip_address: str
    user_agent: str
    model_requests: int = 0
    total_tokens: int = 0
    active: bool = True

@dataclass
class ModelUsage:
    """Model usage tracking"""
    model_name: str
    user_id: str
    request_count: int
    total_tokens: int
    avg_response_time: float
    error_count: int = 0

class UserTracker:
    """Advanced user tracking and analytics"""
    
    def __init__(self, db_path: str = "/data/opshub.db"):
        self.db_path = db_path
        self.active_sessions: Dict[str, UserSession] = {}
        self.user_analytics = defaultdict(dict)
        self.setup_database()
    
    def setup_database(self):
        """Initialize user tracking database tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Enhanced user sessions table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_sessions_enhanced (
                session_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                username TEXT,
                email TEXT,
                start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                end_time TIMESTAMP,
                last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ip_address TEXT,
                user_agent TEXT,
                country TEXT,
                city TEXT,
                device_type TEXT,
                browser TEXT,
                os TEXT,
                duration_minutes INTEGER DEFAULT 0,
                requests_count INTEGER DEFAULT 0,
                tokens_used INTEGER DEFAULT 0,
                models_used TEXT, -- JSON array of models
                session_quality REAL DEFAULT 0.0, -- Success rate
                bandwidth_used INTEGER DEFAULT 0,
                active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Model usage analytics
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS model_usage_analytics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                model_name TEXT NOT NULL,
                request_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                response_time_ms INTEGER,
                input_tokens INTEGER,
                output_tokens INTEGER,
                total_tokens INTEGER,
                cost_estimate REAL,
                success BOOLEAN DEFAULT 1,
                error_message TEXT,
                prompt_category TEXT, -- code, chat, creative, etc.
                quality_score REAL, -- User feedback
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # User behavior patterns
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_behavior_patterns (
                user_id TEXT NOT NULL,
                pattern_date DATE NOT NULL,
                peak_hour INTEGER, -- Hour of most activity
                session_count INTEGER DEFAULT 0,
                avg_session_duration REAL DEFAULT 0,
                favorite_model TEXT,
                primary_use_case TEXT,
                activity_level TEXT, -- low, medium, high
                weekend_user BOOLEAN DEFAULT 0,
                night_owl BOOLEAN DEFAULT 0,
                power_user BOOLEAN DEFAULT 0,
                collaboration_score REAL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (user_id, pattern_date)
            )
        """)
        
        # Real-time user activity
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS realtime_user_activity (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                activity_type TEXT NOT NULL, -- login, logout, request, error
                activity_data TEXT, -- JSON data
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                processed BOOLEAN DEFAULT 0
            )
        """)
        
        # User satisfaction metrics
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_satisfaction (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                session_id TEXT,
                rating INTEGER CHECK (rating >= 1 AND rating <= 5),
                feedback_text TEXT,
                response_time_rating INTEGER,
                accuracy_rating INTEGER,
                ease_of_use_rating INTEGER,
                recommendation_score INTEGER, -- NPS
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Create indexes for performance
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions_enhanced(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_sessions_start_time ON user_sessions_enhanced(start_time)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_model_usage_user_id ON model_usage_analytics(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_model_usage_timestamp ON model_usage_analytics(request_timestamp)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_realtime_activity_timestamp ON realtime_user_activity(timestamp)")
        
        conn.commit()
        conn.close()
        
        logging.info("User tracking database initialized")
    
    async def track_user_login(self, user_data: dict) -> str:
        """Track user login and start session"""
        session_id = f"session_{user_data['user_id']}_{int(datetime.now().timestamp())}"
        
        session = UserSession(
            user_id=user_data['user_id'],
            session_id=session_id,
            start_time=datetime.now(),
            last_activity=datetime.now(),
            ip_address=user_data.get('ip_address', ''),
            user_agent=user_data.get('user_agent', '')
        )
        
        self.active_sessions[session_id] = session
        
        # Store in database
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO user_sessions_enhanced 
            (session_id, user_id, username, email, ip_address, user_agent, 
             device_type, browser, os, country, city)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            session_id,
            user_data['user_id'],
            user_data.get('username', ''),
            user_data.get('email', ''),
            user_data.get('ip_address', ''),
            user_data.get('user_agent', ''),
            user_data.get('device_type', ''),
            user_data.get('browser', ''),
            user_data.get('os', ''),
            user_data.get('country', ''),
            user_data.get('city', '')
        ))
        
        # Log activity
        cursor.execute("""
            INSERT INTO realtime_user_activity (user_id, activity_type, activity_data)
            VALUES (?, ?, ?)
        """, (user_data['user_id'], 'login', json.dumps(user_data)))
        
        conn.commit()
        conn.close()
        
        logging.info(f"User login tracked: {user_data['user_id']}")
        return session_id
    
    async def track_model_request(self, request_data: dict):
        """Track model usage request"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO model_usage_analytics 
            (user_id, model_name, response_time_ms, input_tokens, output_tokens, 
             total_tokens, cost_estimate, success, prompt_category)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            request_data['user_id'],
            request_data['model_name'],
            request_data.get('response_time_ms', 0),
            request_data.get('input_tokens', 0),
            request_data.get('output_tokens', 0),
            request_data.get('total_tokens', 0),
            request_data.get('cost_estimate', 0.0),
            request_data.get('success', True),
            request_data.get('prompt_category', 'general')
        ))
        
        # Update session statistics
        if 'session_id' in request_data:
            cursor.execute("""
                UPDATE user_sessions_enhanced 
                SET requests_count = requests_count + 1,
                    tokens_used = tokens_used + ?,
                    last_activity = CURRENT_TIMESTAMP
                WHERE session_id = ?
            """, (request_data.get('total_tokens', 0), request_data['session_id']))
        
        conn.commit()
        conn.close()
    
    async def analyze_user_patterns(self):
        """Analyze user behavior patterns"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Analyze daily patterns for each user
        cursor.execute("""
            SELECT 
                user_id,
                DATE(start_time) as activity_date,
                COUNT(*) as session_count,
                AVG(duration_minutes) as avg_duration,
                HOUR(start_time) as hour_activity,
                COUNT(CASE WHEN HOUR(start_time) BETWEEN 22 AND 6 THEN 1 END) as night_sessions,
                COUNT(CASE WHEN strftime('%w', start_time) IN ('0', '6') THEN 1 END) as weekend_sessions
            FROM user_sessions_enhanced 
            WHERE start_time >= date('now', '-7 days')
            GROUP BY user_id, DATE(start_time)
        """)
        
        patterns = cursor.fetchall()
        
        for pattern in patterns:
            user_id, date, session_count, avg_duration, peak_hour, night_sessions, weekend_sessions = pattern
            
            # Determine user characteristics
            night_owl = (night_sessions / session_count) > 0.3 if session_count > 0 else False
            weekend_user = (weekend_sessions / session_count) > 0.4 if session_count > 0 else False
            power_user = session_count > 10 or avg_duration > 60
            
            activity_level = "high" if session_count > 5 else "medium" if session_count > 2 else "low"
            
            # Get favorite model
            cursor.execute("""
                SELECT model_name, COUNT(*) as usage_count
                FROM model_usage_analytics 
                WHERE user_id = ? AND DATE(request_timestamp) = ?
                GROUP BY model_name 
                ORDER BY usage_count DESC 
                LIMIT 1
            """, (user_id, date))
            
            favorite_model_result = cursor.fetchone()
            favorite_model = favorite_model_result[0] if favorite_model_result else "unknown"
            
            # Store pattern analysis
            cursor.execute("""
                INSERT OR REPLACE INTO user_behavior_patterns 
                (user_id, pattern_date, peak_hour, session_count, avg_session_duration,
                 favorite_model, activity_level, weekend_user, night_owl, power_user)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id, date, peak_hour, session_count, avg_duration,
                favorite_model, activity_level, weekend_user, night_owl, power_user
            ))
        
        conn.commit()
        conn.close()
        
        logging.info("User behavior patterns analyzed")
    
    async def get_active_users_count(self) -> int:
        """Get current active users count"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Consider users active if they had activity in last 5 minutes
        cursor.execute("""
            SELECT COUNT(DISTINCT user_id) 
            FROM user_sessions_enhanced 
            WHERE last_activity >= datetime('now', '-5 minutes') AND active = 1
        """)
        
        count = cursor.fetchone()[0]
        conn.close()
        
        return count
    
    async def get_user_analytics(self) -> dict:
        """Get comprehensive user analytics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        analytics = {}
        
        # Active users metrics
        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM user_sessions_enhanced WHERE last_activity >= datetime('now', '-5 minutes')")
        analytics['active_users'] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM user_sessions_enhanced WHERE DATE(start_time) = DATE('now')")
        analytics['daily_active_users'] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM user_sessions_enhanced")
        analytics['total_users'] = cursor.fetchone()[0]
        
        # Model usage statistics
        cursor.execute("""
            SELECT model_name, COUNT(*) as requests, AVG(response_time_ms) as avg_response_time
            FROM model_usage_analytics 
            WHERE DATE(request_timestamp) = DATE('now')
            GROUP BY model_name 
            ORDER BY requests DESC
        """)
        analytics['model_usage'] = cursor.fetchall()
        
        # User activity by hour
        cursor.execute("""
            SELECT HOUR(start_time) as hour, COUNT(*) as sessions
            FROM user_sessions_enhanced 
            WHERE DATE(start_time) = DATE('now')
            GROUP BY HOUR(start_time)
            ORDER BY hour
        """)
        analytics['hourly_activity'] = cursor.fetchall()
        
        # Performance metrics
        cursor.execute("""
            SELECT 
                AVG(response_time_ms) as avg_response_time,
                COUNT(CASE WHEN success = 1 THEN 1 END) * 100.0 / COUNT(*) as success_rate,
                COUNT(*) as total_requests
            FROM model_usage_analytics 
            WHERE DATE(request_timestamp) = DATE('now')
        """)
        perf_metrics = cursor.fetchone()
        analytics['performance'] = {
            'avg_response_time': perf_metrics[0] or 0,
            'success_rate': perf_metrics[1] or 0,
            'total_requests': perf_metrics[2] or 0
        }
        
        conn.close()
        return analytics

# Global user tracker instance
user_tracker = UserTracker()
EOF

    echo "✅ User tracking module created"
}

# Function to create user monitoring API endpoints
create_user_api_endpoints() {
    echo "🔌 Creating user monitoring API endpoints..."
    
    cat > "${OPSHUB_DIR}/user_api.py" << 'EOF'
"""
User Monitoring API Endpoints
Provides real-time user analytics and monitoring
"""

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from typing import List, Dict, Optional
import json
from datetime import datetime, timedelta
from .user_tracking import user_tracker

router = APIRouter(prefix="/api/users", tags=["user-monitoring"])

@router.get("/active")
async def get_active_users():
    """Get current active users count"""
    try:
        count = await user_tracker.get_active_users_count()
        return {"active_users": count, "timestamp": datetime.now().isoformat()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/analytics")
async def get_user_analytics():
    """Get comprehensive user analytics"""
    try:
        analytics = await user_tracker.get_user_analytics()
        return analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login")
async def track_user_login(user_data: dict):
    """Track user login"""
    try:
        session_id = await user_tracker.track_user_login(user_data)
        return {"session_id": session_id, "status": "tracked"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/model-request")
async def track_model_request(request_data: dict):
    """Track model usage request"""
    try:
        await user_tracker.track_model_request(request_data)
        return {"status": "tracked"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/patterns/{user_id}")
async def get_user_patterns(user_id: str):
    """Get user behavior patterns"""
    try:
        # Implementation for specific user patterns
        return {"user_id": user_id, "patterns": "analysis_data"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/top-users")
async def get_top_users(limit: int = 20):
    """Get top active users"""
    try:
        import sqlite3
        conn = sqlite3.connect(user_tracker.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT user_id, username, COUNT(*) as request_count,
                   SUM(total_tokens) as total_tokens,
                   AVG(response_time_ms) as avg_response_time
            FROM model_usage_analytics mua
            JOIN user_sessions_enhanced use ON mua.user_id = use.user_id
            WHERE DATE(mua.request_timestamp) >= DATE('now', '-7 days')
            GROUP BY mua.user_id, use.username
            ORDER BY request_count DESC
            LIMIT ?
        """, (limit,))
        
        results = cursor.fetchall()
        conn.close()
        
        return {
            "top_users": [
                {
                    "user_id": row[0],
                    "username": row[1],
                    "request_count": row[2],
                    "total_tokens": row[3],
                    "avg_response_time": row[4]
                }
                for row in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/model-usage")
async def get_model_usage_stats():
    """Get model usage statistics"""
    try:
        import sqlite3
        conn = sqlite3.connect(user_tracker.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                model_name,
                COUNT(*) as request_count,
                COUNT(DISTINCT user_id) as unique_users,
                AVG(response_time_ms) as avg_response_time,
                SUM(total_tokens) as total_tokens,
                AVG(CASE WHEN success = 1 THEN 1.0 ELSE 0.0 END) * 100 as success_rate
            FROM model_usage_analytics
            WHERE DATE(request_timestamp) >= DATE('now', '-7 days')
            GROUP BY model_name
            ORDER BY request_count DESC
        """)
        
        results = cursor.fetchall()
        conn.close()
        
        return {
            "model_stats": [
                {
                    "model_name": row[0],
                    "request_count": row[1],
                    "unique_users": row[2],
                    "avg_response_time": row[3],
                    "total_tokens": row[4],
                    "success_rate": row[5]
                }
                for row in results
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/capacity-analysis")
async def get_capacity_analysis():
    """Analyze system capacity vs user load"""
    try:
        import sqlite3
        conn = sqlite3.connect(user_tracker.db_path)
        cursor = conn.cursor()
        
        # Current capacity metrics
        active_users = await user_tracker.get_active_users_count()
        
        # Historical peak analysis
        cursor.execute("""
            SELECT 
                DATE(start_time) as date,
                MAX(COUNT(*)) as peak_concurrent_users
            FROM user_sessions_enhanced
            WHERE start_time >= date('now', '-30 days')
            GROUP BY DATE(start_time), HOUR(start_time)
            ORDER BY peak_concurrent_users DESC
            LIMIT 1
        """)
        
        peak_data = cursor.fetchone()
        historical_peak = peak_data[1] if peak_data else 0
        
        # Growth trend
        cursor.execute("""
            SELECT 
                DATE(start_time) as date,
                COUNT(DISTINCT user_id) as daily_users
            FROM user_sessions_enhanced
            WHERE start_time >= date('now', '-14 days')
            GROUP BY DATE(start_time)
            ORDER BY date
        """)
        
        growth_data = cursor.fetchall()
        conn.close()
        
        # Calculate growth rate
        if len(growth_data) >= 7:
            recent_avg = sum(row[1] for row in growth_data[-7:]) / 7
            earlier_avg = sum(row[1] for row in growth_data[:7]) / 7
            growth_rate = ((recent_avg - earlier_avg) / earlier_avg * 100) if earlier_avg > 0 else 0
        else:
            growth_rate = 0
        
        return {
            "capacity_analysis": {
                "current_active_users": active_users,
                "target_capacity": 200,
                "capacity_utilization": (active_users / 200) * 100,
                "historical_peak": historical_peak,
                "growth_rate_percent": growth_rate,
                "projected_users_30d": active_users * (1 + growth_rate/100) ** 30,
                "capacity_warning": active_users > 160,
                "capacity_critical": active_users > 180
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
EOF

    echo "✅ User monitoring API endpoints created"
}

# Function to setup Prometheus metrics for users
setup_prometheus_user_metrics() {
    echo "📊 Setting up Prometheus metrics for user monitoring..."
    
    cat > "${OPSHUB_DIR}/user_metrics.py" << 'EOF'
"""
Prometheus Metrics for User Monitoring
Custom metrics for 200+ user tracking
"""

from prometheus_client import Counter, Gauge, Histogram, Summary
import time
from .user_tracking import user_tracker

# User activity metrics
active_users_gauge = Gauge('opshub_active_users', 'Number of currently active users')
total_users_gauge = Gauge('opshub_total_users', 'Total number of registered users')
daily_active_users_gauge = Gauge('opshub_daily_active_users', 'Daily active users')
new_users_counter = Counter('opshub_new_users_total', 'Total number of new user registrations')

# Session metrics
user_sessions_gauge = Gauge('opshub_user_sessions', 'Current number of active sessions')
session_duration_histogram = Histogram('opshub_session_duration_seconds', 'User session duration')
concurrent_sessions_gauge = Gauge('opshub_concurrent_sessions', 'Number of concurrent sessions')

# Model usage metrics
model_requests_counter = Counter('opshub_model_requests_total', 'Total model requests', ['model_name', 'user_id'])
model_response_time = Histogram('opshub_model_response_time_seconds', 'Model response time', ['model_name'])
model_tokens_counter = Counter('opshub_tokens_used_total', 'Total tokens used', ['model_name', 'user_id'])
model_errors_counter = Counter('opshub_model_errors_total', 'Model request errors', ['model_name', 'error_type'])

# User behavior metrics
user_requests_counter = Counter('opshub_user_requests_total', 'Total requests per user', ['user_id'])
user_errors_counter = Counter('opshub_user_errors_total', 'Total errors per user', ['user_id'])
user_activity_gauge = Gauge('opshub_user_activity', 'User activity level', ['user_id', 'activity_type'])

# System capacity metrics
capacity_utilization_gauge = Gauge('opshub_capacity_utilization_percent', 'System capacity utilization percentage')
queue_size_gauge = Gauge('opshub_queue_size', 'Processing queue size')
response_time_summary = Summary('opshub_response_time_seconds', 'Request response time')

# Performance metrics
requests_per_minute_gauge = Gauge('opshub_requests_per_minute', 'Requests per minute')
error_rate_gauge = Gauge('opshub_error_rate_percent', 'Error rate percentage')
throughput_gauge = Gauge('opshub_throughput_requests_per_second', 'System throughput')

# User satisfaction metrics
satisfaction_rating_histogram = Histogram('opshub_satisfaction_rating', 'User satisfaction ratings', buckets=[1, 2, 3, 4, 5])
nps_score_gauge = Gauge('opshub_nps_score', 'Net Promoter Score')

async def update_metrics():
    """Update all user-related metrics"""
    try:
        # Get analytics data
        analytics = await user_tracker.get_user_analytics()
        
        # Update basic user metrics
        active_users_gauge.set(analytics.get('active_users', 0))
        daily_active_users_gauge.set(analytics.get('daily_active_users', 0))
        total_users_gauge.set(analytics.get('total_users', 0))
        
        # Update capacity metrics
        active_users = analytics.get('active_users', 0)
        capacity_utilization_gauge.set((active_users / 200) * 100)
        
        # Update performance metrics
        perf = analytics.get('performance', {})
        if perf.get('avg_response_time'):
            response_time_summary.observe(perf['avg_response_time'] / 1000)  # Convert to seconds
        
        error_rate_gauge.set(100 - perf.get('success_rate', 100))
        requests_per_minute_gauge.set(perf.get('total_requests', 0) / (24 * 60))  # Rough estimate
        
        # Update model usage metrics
        for model_name, requests, avg_time in analytics.get('model_usage', []):
            # Note: In real implementation, you'd track these incrementally
            pass
        
    except Exception as e:
        print(f"Error updating metrics: {e}")

class MetricsTracker:
    """Handles metric tracking for user events"""
    
    @staticmethod
    def track_user_login(user_id: str):
        """Track user login event"""
        user_activity_gauge.labels(user_id=user_id, activity_type='login').set(1)
    
    @staticmethod
    def track_user_logout(user_id: str):
        """Track user logout event"""
        user_activity_gauge.labels(user_id=user_id, activity_type='login').set(0)
    
    @staticmethod
    def track_model_request(user_id: str, model_name: str, response_time: float):
        """Track model request"""
        model_requests_counter.labels(model_name=model_name, user_id=user_id).inc()
        model_response_time.labels(model_name=model_name).observe(response_time)
        user_requests_counter.labels(user_id=user_id).inc()
    
    @staticmethod
    def track_model_error(user_id: str, model_name: str, error_type: str):
        """Track model error"""
        model_errors_counter.labels(model_name=model_name, error_type=error_type).inc()
        user_errors_counter.labels(user_id=user_id).inc()
    
    @staticmethod
    def track_session_duration(duration_seconds: float):
        """Track session duration"""
        session_duration_histogram.observe(duration_seconds)
    
    @staticmethod
    def track_user_satisfaction(rating: int):
        """Track user satisfaction rating"""
        satisfaction_rating_histogram.observe(rating)

# Create global metrics tracker
metrics_tracker = MetricsTracker()
EOF

    echo "✅ Prometheus user metrics setup created"
}

# Function to create resource scaling script
create_scaling_script() {
    echo "📈 Creating resource scaling automation..."
    
    cat > "/opt/obs-stack/scale-resources.sh" << 'EOF'
#!/bin/bash

# Resource Scaling Script for 200+ Users
# Automatically scales resources based on user load

set -e

GRAFANA_URL="http://localhost:3001"
OPSHUB_URL="http://localhost:8089"
ALERT_THRESHOLD_USERS=180
SCALE_UP_THRESHOLD=160
SCALE_DOWN_THRESHOLD=50

# Logging
LOG_FILE="/var/log/obs-stack-scaling.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get current active users
get_active_users() {
    curl -s "${OPSHUB_URL}/api/users/active" | jq -r '.active_users' 2>/dev/null || echo "0"
}

# Get system resource usage
get_resource_usage() {
    # CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    
    # Memory usage
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # GPU usage (if available)
    GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1 2>/dev/null || echo "0")
    
    echo "$CPU_USAGE,$MEMORY_USAGE,$GPU_USAGE"
}

# Scale Docker containers
scale_containers() {
    local action=$1
    local scale_factor=$2
    
    log "Scaling containers: $action (factor: $scale_factor)"
    
    cd /opt/obs-stack
    
    case $action in
        "up")
            # Scale up critical services
            docker-compose up -d --scale opshub=$scale_factor
            
            # Increase resource limits
            docker update --memory=4g --cpus=2.0 obs-stack_opshub_1 2>/dev/null || true
            ;;
        "down")
            # Scale down to normal
            docker-compose up -d --scale opshub=1
            
            # Reset resource limits
            docker update --memory=2g --cpus=1.0 obs-stack_opshub_1 2>/dev/null || true
            ;;
    esac
}

# Send alert notification
send_alert() {
    local message=$1
    local severity=$2
    
    log "ALERT [$severity]: $message"
    
    # Send to Grafana alerting (if configured)
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"$message\", \"severity\": \"$severity\"}" \
        "${GRAFANA_URL}/api/alerts/test" 2>/dev/null || true
    
    # Log to system
    logger -t obs-stack-scaling "$severity: $message"
}

# Check if scaling is needed
check_scaling_requirements() {
    local active_users=$1
    local cpu_usage=$2
    local memory_usage=$3
    local gpu_usage=$4
    
    log "Current metrics - Users: $active_users, CPU: $cpu_usage%, Memory: $memory_usage%, GPU: $gpu_usage%"
    
    # Critical alert threshold
    if [ "$active_users" -gt "$ALERT_THRESHOLD_USERS" ]; then
        send_alert "User count critical: $active_users users (threshold: $ALERT_THRESHOLD_USERS)" "critical"
    fi
    
    # Scale up conditions
    if [ "$active_users" -gt "$SCALE_UP_THRESHOLD" ] || 
       [ "$(echo "$cpu_usage > 75" | bc)" -eq 1 ] || 
       [ "$(echo "$memory_usage > 80" | bc)" -eq 1 ]; then
        
        log "Scale up conditions met"
        scale_containers "up" 2
        send_alert "Scaled up due to high load - Users: $active_users, CPU: $cpu_usage%, Memory: $memory_usage%" "warning"
        return
    fi
    
    # Scale down conditions
    if [ "$active_users" -lt "$SCALE_DOWN_THRESHOLD" ] && 
       [ "$(echo "$cpu_usage < 30" | bc)" -eq 1 ] && 
       [ "$(echo "$memory_usage < 40" | bc)" -eq 1 ]; then
        
        log "Scale down conditions met"
        scale_containers "down" 1
        send_alert "Scaled down due to low load - Users: $active_users, CPU: $cpu_usage%, Memory: $memory_usage%" "info"
        return
    fi
    
    log "No scaling action required"
}

# Generate capacity report
generate_capacity_report() {
    local active_users=$1
    
    REPORT_FILE="/tmp/capacity-report-$(date +%Y%m%d-%H%M).json"
    
    cat > "$REPORT_FILE" << EOL
{
  "timestamp": "$(date --iso-8601=seconds)",
  "active_users": $active_users,
  "capacity_utilization": $(echo "scale=2; $active_users / 200 * 100" | bc),
  "resource_usage": $(get_resource_usage),
  "scaling_thresholds": {
    "alert_threshold": $ALERT_THRESHOLD_USERS,
    "scale_up_threshold": $SCALE_UP_THRESHOLD,
    "scale_down_threshold": $SCALE_DOWN_THRESHOLD
  },
  "recommendations": [
    $([ "$active_users" -gt 150 ] && echo '"Consider adding more GPU resources",' || echo '')
    $([ "$active_users" -gt 180 ] && echo '"Prepare for emergency scaling",' || echo '')
    "Monitor user growth trends"
  ]
}
EOL
    
    log "Capacity report generated: $REPORT_FILE"
}

# Main monitoring loop
main() {
    log "=== Starting resource scaling check ==="
    
    # Get current metrics
    ACTIVE_USERS=$(get_active_users)
    RESOURCE_USAGE=$(get_resource_usage)
    
    IFS=',' read -r CPU_USAGE MEMORY_USAGE GPU_USAGE <<< "$RESOURCE_USAGE"
    
    # Check scaling requirements
    check_scaling_requirements "$ACTIVE_USERS" "$CPU_USAGE" "$MEMORY_USAGE" "$GPU_USAGE"
    
    # Generate capacity report
    generate_capacity_report "$ACTIVE_USERS"
    
    log "=== Resource scaling check completed ==="
}

# Run the scaling check
main "$@"
EOF

    chmod +x "/opt/obs-stack/scale-resources.sh"
    echo "✅ Resource scaling script created"
}

# Function to setup cron jobs for user monitoring
setup_user_monitoring_cron() {
    echo "⏰ Setting up user monitoring cron jobs..."
    
    # Add cron jobs for user monitoring
    (crontab -l 2>/dev/null; echo "*/1 * * * * /opt/obs-stack/scale-resources.sh") | crontab -
    (crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://localhost:8089/api/users/analytics > /dev/null") | crontab -
    (crontab -l 2>/dev/null; echo "0 */6 * * * python3 -c 'from opshub.user_tracking import user_tracker; import asyncio; asyncio.run(user_tracker.analyze_user_patterns())'") | crontab -
    
    echo "✅ User monitoring cron jobs configured:"
    echo "  • Resource scaling check every minute"
    echo "  • User analytics refresh every 5 minutes"
    echo "  • Pattern analysis every 6 hours"
}

# Main execution
main() {
    echo "🚀 Starting OpenWebUI user monitoring setup..."
    
    configure_user_tracking
    create_user_api_endpoints
    setup_prometheus_user_metrics
    create_scaling_script
    setup_user_monitoring_cron
    
    echo ""
    echo "🎉 OpenWebUI user monitoring configured successfully!"
    echo ""
    echo "👥 User Monitoring Features:"
    echo "  • Real-time user session tracking"
    echo "  • Model usage analytics per user"
    echo "  • Behavior pattern analysis"
    echo "  • Capacity utilization monitoring"
    echo "  • Automatic resource scaling"
    echo "  • User satisfaction tracking"
    echo ""
    echo "📊 Available APIs:"
    echo "  • GET /api/users/active - Current active users"
    echo "  • GET /api/users/analytics - Comprehensive analytics"
    echo "  • GET /api/users/top-users - Most active users"
    echo "  • GET /api/users/model-usage - Model usage statistics"
    echo "  • GET /api/users/capacity-analysis - Capacity analysis"
    echo ""
    echo "📈 Monitoring Capabilities:"
    echo "  • Track 200+ concurrent users"
    echo "  • Monitor individual user sessions"
    echo "  • Analyze model usage patterns"
    echo "  • Predict capacity requirements"
    echo "  • Automatic scaling at 160+ users"
    echo "  • Critical alerts at 180+ users"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Restart OpsHub service: docker-compose restart opshub"
    echo "  2. Test user tracking: curl http://localhost:8089/api/users/active"
    echo "  3. Monitor scaling logs: tail -f /var/log/obs-stack-scaling.log"
    echo "  4. Set up user analytics dashboard in Grafana"
}

# Run the configuration
main "$@"
