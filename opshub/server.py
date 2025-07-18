from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import PlainTextResponse, StreamingResponse
from prometheus_client import generate_latest
import uvicorn
import json
import asyncio
from datetime import datetime, timedelta
from typing import List, Optional
import docker
import psutil
import sqlite3
import os
from contextlib import asynccontextmanager

from .logging_pipeline import start as start_logs, get_logs
from .metrics_host import start as start_metrics_host, get_system_metrics
from .metrics_gpu import start as start_metrics_gpu, get_gpu_metrics
from .database import init_db, store_user_session, get_user_sessions, store_log_entry

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    init_db()
    start_logs()
    start_metrics_host() 
    start_metrics_gpu()
    yield
    # Shutdown
    pass

app = FastAPI(title="OpsHub - Docker Logger & Monitor", lifespan=lifespan)
docker_client = docker.from_env()

@app.get("/health")
def health():
    return {"status": "ok", "timestamp": datetime.now().isoformat()}

@app.get("/metrics")
def metrics():
    return PlainTextResponse(generate_latest().decode())

@app.get("/logs/{container}")
async def get_container_logs(
    container: str,
    level: str = Query("all", regex="^(all|info|warning|error|success|critical)$"),
    tail: int = Query(100, ge=1, le=10000),
    follow: bool = Query(False)
):
    """Get logs for a specific container or 'all' containers"""
    try:
        if follow:
            return StreamingResponse(
                stream_logs(container, level, tail),
                media_type="application/x-ndjson"
            )
        else:
            logs = get_logs(container, level, tail)
            return {"logs": logs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def stream_logs(container: str, level: str, tail: int):
    """Stream logs in real-time"""
    # Get initial logs
    initial_logs = get_logs(container, level, tail)
    for log in initial_logs:
        yield f"{json.dumps(log)}\n"
    
    # Stream new logs
    while True:
        await asyncio.sleep(1)
        new_logs = get_logs(container, level, 10, since=datetime.now() - timedelta(seconds=1))
        for log in new_logs:
            yield f"{json.dumps(log)}\n"

@app.get("/containers/status")
def get_containers_status():
    """Get status of all containers"""
    containers = []
    try:
        for container in docker_client.containers.list(all=True):
            stats = None
            if container.status == 'running':
                try:
                    stats = container.stats(stream=False)
                    cpu_percent = calculate_cpu_percent(stats)
                    memory_usage = format_memory(stats['memory_stats'])
                    network_io = format_network_io(stats.get('networks', {}))
                except:
                    cpu_percent = "N/A"
                    memory_usage = "N/A" 
                    network_io = "N/A"
            else:
                cpu_percent = "0"
                memory_usage = "0 MB"
                network_io = "0 B"
            
            containers.append({
                "name": container.name,
                "status": container.status,
                "image": container.image.tags[0] if container.image.tags else "Unknown",
                "created": container.attrs['Created'],
                "cpu_percent": cpu_percent,
                "memory_usage": memory_usage,
                "network_io": network_io,
                "uptime": calculate_uptime(container.attrs['State'].get('StartedAt')) if container.status == 'running' else "N/A"
            })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting container status: {e}")
    
    return containers

@app.get("/users/sessions")
def get_openwebui_sessions():
    """Get OpenWebUI user sessions and activity"""
    try:
        sessions = get_user_sessions()
        return sessions
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting user sessions: {e}")

@app.post("/users/session")
def track_user_session(username: str, model: str, action: str):
    """Track user session activity"""
    try:
        store_user_session(username, model, action)
        return {"status": "recorded"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error tracking session: {e}")

@app.get("/metrics/performance")
def get_performance_metrics():
    """Get system and GPU performance metrics"""
    try:
        system_metrics = get_system_metrics()
        gpu_metrics = get_gpu_metrics()
        
        return {
            "timestamp": datetime.now().isoformat(),
            "cpu_percent": system_metrics.get("cpu_percent"),
            "memory_percent": system_metrics.get("memory_percent"), 
            "disk_percent": system_metrics.get("disk_percent"),
            "load_avg": system_metrics.get("load_avg"),
            "gpus": gpu_metrics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting performance metrics: {e}")

@app.get("/search/logs")
def search_logs(
    query: str,
    container: Optional[str] = None,
    level: Optional[str] = None,
    start_time: Optional[str] = None,
    end_time: Optional[str] = None,
    limit: int = Query(1000, ge=1, le=10000)
):
    """Search logs with filters"""
    try:
        # Implementation for log search
        results = search_logs_db(query, container, level, start_time, end_time, limit)
        return {"results": results, "count": len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error searching logs: {e}")

def calculate_cpu_percent(stats):
    """Calculate CPU percentage from Docker stats"""
    try:
        cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - \
                   stats['precpu_stats']['cpu_usage']['total_usage']
        system_cpu_delta = stats['cpu_stats']['system_cpu_usage'] - \
                          stats['precpu_stats']['system_cpu_usage']
        number_cpus = stats['cpu_stats']['online_cpus']
        
        if system_cpu_delta > 0:
            cpu_percent = (cpu_delta / system_cpu_delta) * number_cpus * 100.0
            return f"{cpu_percent:.1f}"
        return "0.0"
    except:
        return "N/A"

def format_memory(memory_stats):
    """Format memory usage"""
    try:
        usage = memory_stats['usage']
        limit = memory_stats['limit'] 
        percent = (usage / limit) * 100
        return f"{usage / (1024**2):.1f} MB ({percent:.1f}%)"
    except:
        return "N/A"

def format_network_io(networks):
    """Format network I/O"""
    try:
        total_rx = sum(net['rx_bytes'] for net in networks.values())
        total_tx = sum(net['tx_bytes'] for net in networks.values())
        return f"RX: {total_rx / (1024**2):.1f} MB, TX: {total_tx / (1024**2):.1f} MB"
    except:
        return "N/A"

def calculate_uptime(started_at):
    """Calculate container uptime"""
    try:
        started = datetime.fromisoformat(started_at.replace('Z', '+00:00'))
        uptime = datetime.now(started.tzinfo) - started
        days = uptime.days
        hours, remainder = divmod(uptime.seconds, 3600)
        minutes, _ = divmod(remainder, 60)
        return f"{days}d {hours}h {minutes}m"
    except:
        return "N/A"

def search_logs_db(query, container, level, start_time, end_time, limit):
    """Search logs in database"""
    # Placeholder - implement actual database search
    return []

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8089)
