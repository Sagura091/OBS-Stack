import sqlite3
import json
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import threading

DB_PATH = "/data/opshub.db"
_db_lock = threading.Lock()

def get_connection():
    """Get database connection with proper configuration"""
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initialize database with required tables"""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    with _db_lock:
        conn = get_connection()
        try:
            # Logs table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    container_name TEXT NOT NULL,
                    container_id TEXT NOT NULL,
                    level TEXT NOT NULL,
                    message TEXT NOT NULL,
                    raw_log TEXT,
                    source TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    INDEX(timestamp),
                    INDEX(container_name),
                    INDEX(level),
                    INDEX(created_at)
                )
            """)
            
            # User sessions table for OpenWebUI tracking
            conn.execute("""
                CREATE TABLE IF NOT EXISTS user_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT NOT NULL,
                    model TEXT,
                    action TEXT NOT NULL,
                    session_id TEXT,
                    ip_address TEXT,
                    user_agent TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    metadata TEXT,
                    INDEX(username),
                    INDEX(model),
                    INDEX(timestamp)
                )
            """)
            
            # Performance metrics table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS performance_metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    metric_type TEXT NOT NULL,
                    metric_name TEXT NOT NULL,
                    value REAL NOT NULL,
                    unit TEXT,
                    container_name TEXT,
                    metadata TEXT,
                    INDEX(timestamp),
                    INDEX(metric_type),
                    INDEX(container_name)
                )
            """)
            
            # Container status history
            conn.execute("""
                CREATE TABLE IF NOT EXISTS container_status (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    container_name TEXT NOT NULL,
                    container_id TEXT NOT NULL,
                    status TEXT NOT NULL,
                    cpu_percent REAL,
                    memory_usage_mb REAL,
                    memory_percent REAL,
                    network_rx_mb REAL,
                    network_tx_mb REAL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    INDEX(container_name),
                    INDEX(timestamp)
                )
            """)
            
            # Alert history
            conn.execute("""
                CREATE TABLE IF NOT EXISTS alerts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    alert_type TEXT NOT NULL,
                    severity TEXT NOT NULL,
                    message TEXT NOT NULL,
                    container_name TEXT,
                    metric_value REAL,
                    threshold_value REAL,
                    resolved BOOLEAN DEFAULT FALSE,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    resolved_at DATETIME,
                    INDEX(alert_type),
                    INDEX(severity),
                    INDEX(timestamp),
                    INDEX(resolved)
                )
            """)
            
            conn.commit()
            
        finally:
            conn.close()

def store_log_entry(container_name: str, container_id: str, level: str, 
                   message: str, raw_log: str = None, source: str = None,
                   timestamp: str = None):
    """Store log entry in database"""
    if not timestamp:
        timestamp = datetime.now().isoformat()
    
    with _db_lock:
        conn = get_connection()
        try:
            conn.execute("""
                INSERT INTO logs (timestamp, container_name, container_id, level, message, raw_log, source)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (timestamp, container_name, container_id, level, message, raw_log, source))
            conn.commit()
        finally:
            conn.close()

def get_logs(container: str = None, level: str = "all", limit: int = 100, 
            since: datetime = None) -> List[Dict]:
    """Get logs with filtering"""
    with _db_lock:
        conn = get_connection()
        try:
            query = "SELECT * FROM logs WHERE 1=1"
            params = []
            
            if container and container != "all":
                query += " AND container_name = ?"
                params.append(container)
            
            if level != "all":
                query += " AND level = ?"
                params.append(level.upper())
            
            if since:
                query += " AND timestamp >= ?"
                params.append(since.isoformat())
            
            query += " ORDER BY timestamp DESC LIMIT ?"
            params.append(limit)
            
            cursor = conn.execute(query, params)
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
            
        finally:
            conn.close()

def store_user_session(username: str, model: str = None, action: str = "login",
                      session_id: str = None, ip_address: str = None,
                      user_agent: str = None, metadata: Dict = None):
    """Store user session activity"""
    with _db_lock:
        conn = get_connection()
        try:
            conn.execute("""
                INSERT INTO user_sessions (username, model, action, session_id, ip_address, user_agent, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (username, model, action, session_id, ip_address, user_agent, 
                  json.dumps(metadata) if metadata else None))
            conn.commit()
        finally:
            conn.close()

def get_user_sessions(active_only: bool = False, hours: int = 24) -> List[Dict]:
    """Get user sessions"""
    with _db_lock:
        conn = get_connection()
        try:
            if active_only:
                # Get currently active sessions (login without logout in last X hours)
                query = """
                    SELECT DISTINCT username, model, session_id, ip_address,
                           MAX(timestamp) as last_activity,
                           MIN(timestamp) as started_at,
                           COUNT(*) as request_count
                    FROM user_sessions
                    WHERE timestamp >= datetime('now', '-{} hours')
                    GROUP BY username, session_id
                    HAVING NOT EXISTS (
                        SELECT 1 FROM user_sessions us2 
                        WHERE us2.username = user_sessions.username 
                        AND us2.session_id = user_sessions.session_id
                        AND us2.action = 'logout'
                        AND us2.timestamp > MAX(user_sessions.timestamp)
                    )
                    ORDER BY last_activity DESC
                """.format(hours)
            else:
                # Get all sessions in time period
                query = """
                    SELECT username, model, action, session_id, ip_address, timestamp,
                           metadata
                    FROM user_sessions
                    WHERE timestamp >= datetime('now', '-{} hours')
                    ORDER BY timestamp DESC
                """.format(hours)
            
            cursor = conn.execute(query)
            rows = cursor.fetchall()
            
            sessions = []
            for row in rows:
                session = dict(row)
                if session.get('metadata'):
                    try:
                        session['metadata'] = json.loads(session['metadata'])
                    except:
                        pass
                sessions.append(session)
            
            return sessions
            
        finally:
            conn.close()

def store_performance_metric(metric_type: str, metric_name: str, value: float,
                           unit: str = None, container_name: str = None,
                           metadata: Dict = None):
    """Store performance metric"""
    with _db_lock:
        conn = get_connection()
        try:
            conn.execute("""
                INSERT INTO performance_metrics (metric_type, metric_name, value, unit, container_name, metadata)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (metric_type, metric_name, value, unit, container_name,
                  json.dumps(metadata) if metadata else None))
            conn.commit()
        finally:
            conn.close()

def store_container_status(container_name: str, container_id: str, status: str,
                          cpu_percent: float = None, memory_usage_mb: float = None,
                          memory_percent: float = None, network_rx_mb: float = None,
                          network_tx_mb: float = None):
    """Store container status"""
    with _db_lock:
        conn = get_connection()
        try:
            conn.execute("""
                INSERT INTO container_status 
                (container_name, container_id, status, cpu_percent, memory_usage_mb, 
                 memory_percent, network_rx_mb, network_tx_mb)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (container_name, container_id, status, cpu_percent, memory_usage_mb,
                  memory_percent, network_rx_mb, network_tx_mb))
            conn.commit()
        finally:
            conn.close()

def create_alert(alert_type: str, severity: str, message: str,
                container_name: str = None, metric_value: float = None,
                threshold_value: float = None):
    """Create alert"""
    with _db_lock:
        conn = get_connection()
        try:
            conn.execute("""
                INSERT INTO alerts (alert_type, severity, message, container_name, metric_value, threshold_value)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (alert_type, severity, message, container_name, metric_value, threshold_value))
            conn.commit()
        finally:
            conn.close()

def get_alerts(severity: str = None, resolved: bool = None, hours: int = 24) -> List[Dict]:
    """Get alerts"""
    with _db_lock:
        conn = get_connection()
        try:
            query = "SELECT * FROM alerts WHERE timestamp >= datetime('now', '-{} hours')".format(hours)
            params = []
            
            if severity:
                query += " AND severity = ?"
                params.append(severity)
            
            if resolved is not None:
                query += " AND resolved = ?"
                params.append(resolved)
            
            query += " ORDER BY timestamp DESC"
            
            cursor = conn.execute(query, params)
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
            
        finally:
            conn.close()

def cleanup_old_data(days: int = 30):
    """Clean up old data from database"""
    with _db_lock:
        conn = get_connection()
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            # Clean up old logs
            conn.execute("DELETE FROM logs WHERE created_at < ?", (cutoff_date,))
            
            # Clean up old metrics (keep longer for trends)
            conn.execute("DELETE FROM performance_metrics WHERE timestamp < ?", 
                        (cutoff_date - timedelta(days=30),))
            
            # Clean up old container status
            conn.execute("DELETE FROM container_status WHERE timestamp < ?", (cutoff_date,))
            
            # Clean up resolved alerts
            conn.execute("DELETE FROM alerts WHERE resolved = TRUE AND resolved_at < ?", 
                        (cutoff_date,))
            
            conn.commit()
            
        finally:
            conn.close()

def get_database_stats() -> Dict:
    """Get database statistics"""
    with _db_lock:
        conn = get_connection()
        try:
            stats = {}
            
            # Count records in each table
            tables = ['logs', 'user_sessions', 'performance_metrics', 'container_status', 'alerts']
            for table in tables:
                cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
                stats[f"{table}_count"] = cursor.fetchone()[0]
            
            # Database size
            cursor = conn.execute("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()")
            stats['database_size_bytes'] = cursor.fetchone()[0]
            
            return stats
            
        finally:
            conn.close()
