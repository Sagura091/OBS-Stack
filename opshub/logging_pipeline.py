import docker, datetime, json, os, re, threading, time, gzip, tarfile, shutil
from pathlib import Path
from rich.console import Console
from rich.theme import Theme
from .config import target_containers, LOG_BASE, RETENTION_ACTIVE_DAYS
from .database import store_log_entry, get_logs as get_logs_db
import os, re, docker

console = Console(theme=Theme({
    "INFO": "dim",
    "SUCCESS": "green",
    "WARN": "yellow",
    "ERROR": "bold red"
}))

LEVEL_PATTERNS = {
    "ERROR": re.compile(r"\b(ERROR|ERR|CRITICAL|FATAL|EXCEPTION|Failed|failed|FAILED)\b", re.I),
    "CRITICAL": re.compile(r"\b(CRITICAL|FATAL|PANIC)\b", re.I),
    "WARNING": re.compile(r"\b(WARN|WARNING|CAUTION)\b", re.I),
    "SUCCESS": re.compile(r"\b(SUCCESS|OK|COMPLETED|FINISHED|DONE|✓|✅)\b", re.I),
    "INFO": re.compile(r"\b(INFO|INFORMATION|DEBUG|TRACE)\b", re.I),
}

# Enhanced patterns for specific services
OPENWEBUI_PATTERNS = {
    "user_login": re.compile(r"user\s+(\w+)\s+(logged\s+in|authenticated)", re.I),
    "model_usage": re.compile(r"model[:\s]+(\w+)", re.I),
    "api_request": re.compile(r"(GET|POST|PUT|DELETE)\s+/api/", re.I),
    "error": re.compile(r"(error|exception|failed)", re.I),
}

OLLAMA_PATTERNS = {
    "model_load": re.compile(r"loaded\s+model[:\s]+(\w+)", re.I),
    "model_request": re.compile(r"(generating|processing)\s+for\s+model[:\s]+(\w+)", re.I),
    "gpu_usage": re.compile(r"GPU\s+(\d+).*?(\d+)%", re.I),
}

def classify(line: str) -> str:
    """Classify log line by level"""
    for lvl, pat in LEVEL_PATTERNS.items():
        if pat.search(line):
            return lvl
    return "INFO"

def extract_metadata(container_name: str, line: str) -> dict:
    """Extract metadata from log lines based on container type"""
    metadata = {}
    
    if "openwebui" in container_name.lower():
        # Extract user login info
        match = OPENWEBUI_PATTERNS["user_login"].search(line)
        if match:
            metadata["user"] = match.group(1)
            metadata["action"] = "login"
        
        # Extract model usage
        match = OPENWEBUI_PATTERNS["model_usage"].search(line)
        if match:
            metadata["model"] = match.group(1)
        
        # Extract API requests
        match = OPENWEBUI_PATTERNS["api_request"].search(line)
        if match:
            metadata["method"] = match.group(1)
            metadata["endpoint"] = "api"
    
    elif "ollama" in container_name.lower():
        # Extract model loading
        match = OLLAMA_PATTERNS["model_load"].search(line)
        if match:
            metadata["model"] = match.group(1)
            metadata["action"] = "model_load"
        
        # Extract model requests
        match = OLLAMA_PATTERNS["model_request"].search(line)
        if match:
            metadata["model"] = match.group(2)
            metadata["action"] = match.group(1)
        
        # Extract GPU usage
        match = OLLAMA_PATTERNS["gpu_usage"].search(line)
        if match:
            metadata["gpu_id"] = match.group(1)
            metadata["gpu_usage"] = match.group(2)
    
    return metadata

def tail_container(name: str):
    """Tail logs for a container and process them"""
    client = docker.from_env()
    try:
        c = client.containers.get(name)
        container_id = c.id
        
        # Get recent logs first
        for raw in c.logs(stream=False, tail=100):
            line = raw.decode(errors="ignore").rstrip("\n")
            if line:
                process_log_line(name, container_id, line)
        
        # Follow new logs
        for raw in c.logs(stream=True, follow=True, since=int(time.time())):
            line = raw.decode(errors="ignore").rstrip("\n")
            if line:
                process_log_line(name, container_id, line)
                
    except docker.errors.NotFound:
        console.print(f"[ERROR]Container {name} not found", style="ERROR")
    except Exception as e:
        console.print(f"[ERROR]Error tailing {name}: {e}", style="ERROR")

def process_log_line(container_name: str, container_id: str, line: str):
    """Process a single log line"""
    try:
        lvl = classify(line)
        metadata = extract_metadata(container_name, line)
        timestamp = datetime.datetime.now().isoformat()
        
        # Display in console
        console.print(f"[{lvl}][{container_name}] {line}", style=lvl)
        
        # Write to file
        write_line(container_name, lvl, line)
        
        # Store in database
        store_log_entry(
            container_name=container_name,
            container_id=container_id,
            level=lvl,
            message=line,
            raw_log=line,
            source="docker_logs",
            timestamp=timestamp
        )
        
        # Handle special cases for user tracking
        if metadata.get("user") and metadata.get("action") == "login":
            from .database import store_user_session
            store_user_session(
                username=metadata["user"],
                model=metadata.get("model"),
                action="login",
                metadata=metadata
            )
            
    except Exception as e:
        console.print(f"[ERROR]Error processing log line: {e}", style="ERROR")

def write_line(container: str, lvl: str, line: str):
    """Write log line to file"""
    day = datetime.datetime.now().strftime("%Y-%m-%d")
    base = Path(LOG_BASE) / container
    base.mkdir(parents=True, exist_ok=True)
    
    # Write to daily log
    with (base / f"{day}.log").open("a") as fh:
        fh.write(f"{datetime.datetime.now().isoformat()} [{lvl}] {line}\n")
    
    # Write to level-specific log
    with (base / f"{day}_{lvl}.log").open("a") as fh:
        fh.write(f"{datetime.datetime.now().isoformat()} {line}\n")

def get_logs(container: str = None, level: str = "all", limit: int = 100, since: datetime.datetime = None):
    """Get logs from database with filtering"""
    return get_logs_db(container, level, limit, since)

def discover_containers():
    """Discover containers to monitor"""
    include_pat = re.compile(os.getenv("OPS_INCLUDE_REGEX", ".*"))
    exclude_pat = re.compile(os.getenv("OPS_EXCLUDE_REGEX", "^$"))  # match nothing by default
    include_stopped = os.getenv("OPS_INCLUDE_STOPPED", "false").lower() in ("1","true","yes")

    client = docker.from_env()
    all_conts = client.containers.list(all=True) if include_stopped else client.containers.list()
    selected = []
    for c in all_conts:
        name = c.name
        if not include_pat.search(name):
            continue
        if exclude_pat.search(name):
            continue
        selected.append(name)
    return selected

def start():
    """Start log monitoring for all discovered containers"""
    names = discover_containers()
    console.print(f"[bold cyan]OpsHub monitoring containers:[/bold cyan] {', '.join(names)}")
    for name in names:
        threading.Thread(target=tail_container, args=(name,), daemon=True).start()
    
    # Start cleanup thread
    threading.Thread(target=cleanup_worker, daemon=True).start()

def cleanup_worker():
    """Background worker for cleanup tasks"""
    while True:
        try:
            time.sleep(3600)  # Run every hour
            cleanup_old_logs()
            from .database import cleanup_old_data
            cleanup_old_data()
        except Exception as e:
            console.print(f"[ERROR]Cleanup error: {e}", style="ERROR")

def cleanup_old_logs():
    """Clean up old log files"""
    try:
        cutoff_date = datetime.datetime.now() - datetime.timedelta(days=RETENTION_ACTIVE_DAYS)
        
        for container_dir in Path(LOG_BASE).iterdir():
            if container_dir.is_dir():
                for log_file in container_dir.glob("*.log"):
                    if log_file.stat().st_mtime < cutoff_date.timestamp():
                        log_file.unlink()
                        
    except Exception as e:
        console.print(f"[ERROR]Log cleanup error: {e}", style="ERROR")