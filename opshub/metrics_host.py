import psutil, time, threading
from prometheus_client import Gauge
from .database import store_performance_metric

g_cpu = Gauge("host_cpu_percent", "Host CPU utilisation %")
g_mem = Gauge("host_mem_percent", "Host memory utilisation %")
g_disk = Gauge("host_disk_percent", "Host disk utilisation %")
g_load = Gauge("host_load_avg", "Host load average", ["interval"])
g_network_rx = Gauge("host_network_rx_bytes", "Host network RX bytes", ["interface"])
g_network_tx = Gauge("host_network_tx_bytes", "Host network TX bytes", ["interface"])

# Global storage for latest metrics
_latest_metrics = {}

def collect():
    """Collect system metrics continuously"""
    while True:
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            g_cpu.set(cpu_percent)
            store_performance_metric("system", "cpu_percent", cpu_percent, "percent")
            
            # Memory metrics
            memory = psutil.virtual_memory()
            g_mem.set(memory.percent)
            store_performance_metric("system", "memory_percent", memory.percent, "percent")
            store_performance_metric("system", "memory_available", memory.available / (1024**3), "GB")
            
            # Disk metrics
            disk = psutil.disk_usage('/')
            disk_percent = (disk.used / disk.total) * 100
            g_disk.set(disk_percent)
            store_performance_metric("system", "disk_percent", disk_percent, "percent")
            
            # Load average
            if hasattr(psutil, 'getloadavg'):
                load_1, load_5, load_15 = psutil.getloadavg()
                g_load.labels(interval="1m").set(load_1)
                g_load.labels(interval="5m").set(load_5)
                g_load.labels(interval="15m").set(load_15)
                store_performance_metric("system", "load_avg_1m", load_1, "load")
                store_performance_metric("system", "load_avg_5m", load_5, "load")
                store_performance_metric("system", "load_avg_15m", load_15, "load")
            
            # Network metrics
            network = psutil.net_io_counters(pernic=True)
            for interface, stats in network.items():
                g_network_rx.labels(interface=interface).set(stats.bytes_recv)
                g_network_tx.labels(interface=interface).set(stats.bytes_sent)
                store_performance_metric("network", f"{interface}_rx_bytes", stats.bytes_recv, "bytes")
                store_performance_metric("network", f"{interface}_tx_bytes", stats.bytes_sent, "bytes")
            
            # Update global metrics cache
            _latest_metrics.update({
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_available_gb": memory.available / (1024**3),
                "memory_total_gb": memory.total / (1024**3),
                "disk_percent": disk_percent,
                "disk_free_gb": disk.free / (1024**3),
                "disk_total_gb": disk.total / (1024**3),
                "load_avg": [load_1, load_5, load_15] if hasattr(psutil, 'getloadavg') else None,
                "network_interfaces": {
                    iface: {
                        "rx_bytes": stats.bytes_recv,
                        "tx_bytes": stats.bytes_sent,
                        "rx_packets": stats.packets_recv,
                        "tx_packets": stats.packets_sent
                    } for iface, stats in network.items()
                }
            })
            
        except Exception as e:
            print(f"Error collecting host metrics: {e}")
        
        time.sleep(5)

def get_system_metrics():
    """Get latest system metrics"""
    return _latest_metrics.copy()

def get_process_metrics():
    """Get process-level metrics"""
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'memory_info']):
        try:
            pinfo = proc.info
            if pinfo['cpu_percent'] > 1.0 or pinfo['memory_percent'] > 1.0:  # Only high-usage processes
                processes.append({
                    "pid": pinfo['pid'],
                    "name": pinfo['name'],
                    "cpu_percent": pinfo['cpu_percent'],
                    "memory_percent": pinfo['memory_percent'],
                    "memory_mb": pinfo['memory_info'].rss / (1024**2) if pinfo['memory_info'] else 0
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    return sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)[:20]

def get_system_info():
    """Get static system information"""
    try:
        return {
            "cpu_count": psutil.cpu_count(),
            "cpu_count_logical": psutil.cpu_count(logical=True),
            "memory_total_gb": psutil.virtual_memory().total / (1024**3),
            "disk_total_gb": psutil.disk_usage('/').total / (1024**3),
            "boot_time": psutil.boot_time(),
            "platform": psutil.os.name if hasattr(psutil, 'os') else 'unknown'
        }
    except Exception as e:
        print(f"Error getting system info: {e}")
        return {}

def start():
    """Start metrics collection"""
    threading.Thread(target=collect, daemon=True).start()
        