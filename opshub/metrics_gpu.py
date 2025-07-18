import time, threading
from .database import store_performance_metric

try:
    import pynvml
    from prometheus_client import Gauge
    pynvml.nvmlInit()
    GPU_COUNT = pynvml.nvmlDeviceGetCount()

    g_gpu_util = Gauge("gpu_utilization_percent", "GPU util %", ["gpu"])
    g_gpu_mem = Gauge("gpu_mem_percent", "GPU memory %", ["gpu"])
    g_gpu_temp = Gauge("gpu_temperature_celsius", "GPU temperature °C", ["gpu"])
    g_gpu_power = Gauge("gpu_power_watts", "GPU power consumption W", ["gpu"])
    g_gpu_clock = Gauge("gpu_clock_mhz", "GPU clock speed MHz", ["gpu", "type"])
    
except Exception as e:
    print(f"GPU monitoring not available: {e}")
    GPU_COUNT = 0

# Global storage for latest GPU metrics
_latest_gpu_metrics = []

def collect():
    """Collect GPU metrics continuously"""
    global _latest_gpu_metrics
    
    while True:
        try:
            gpu_data = []
            
            for idx in range(GPU_COUNT):
                h = pynvml.nvmlDeviceGetHandleByIndex(idx)
                
                # Utilization
                util = pynvml.nvmlDeviceGetUtilizationRates(h)
                gpu_util = util.gpu
                memory_util = util.memory
                
                # Memory info
                mem = pynvml.nvmlDeviceGetMemoryInfo(h)
                memory_used_mb = mem.used / (1024**2)
                memory_total_mb = mem.total / (1024**2)
                memory_percent = (mem.used / mem.total) * 100
                
                # Temperature
                try:
                    temp = pynvml.nvmlDeviceGetTemperature(h, pynvml.NVML_TEMPERATURE_GPU)
                except:
                    temp = None
                
                # Power
                try:
                    power = pynvml.nvmlDeviceGetPowerUsage(h) / 1000.0  # Convert to watts
                except:
                    power = None
                
                # Clock speeds
                try:
                    graphics_clock = pynvml.nvmlDeviceGetClockInfo(h, pynvml.NVML_CLOCK_GRAPHICS)
                    memory_clock = pynvml.nvmlDeviceGetClockInfo(h, pynvml.NVML_CLOCK_MEM)
                except:
                    graphics_clock = None
                    memory_clock = None
                
                # GPU name
                try:
                    name = pynvml.nvmlDeviceGetName(h).decode('utf-8')
                except:
                    name = f"GPU {idx}"
                
                # Update Prometheus metrics
                g_gpu_util.labels(gpu=str(idx)).set(gpu_util)
                g_gpu_mem.labels(gpu=str(idx)).set(memory_percent)
                if temp is not None:
                    g_gpu_temp.labels(gpu=str(idx)).set(temp)
                if power is not None:
                    g_gpu_power.labels(gpu=str(idx)).set(power)
                if graphics_clock is not None:
                    g_gpu_clock.labels(gpu=str(idx), type="graphics").set(graphics_clock)
                if memory_clock is not None:
                    g_gpu_clock.labels(gpu=str(idx), type="memory").set(memory_clock)
                
                # Store in database
                store_performance_metric("gpu", f"gpu_{idx}_utilization", gpu_util, "percent")
                store_performance_metric("gpu", f"gpu_{idx}_memory_percent", memory_percent, "percent")
                store_performance_metric("gpu", f"gpu_{idx}_memory_used", memory_used_mb, "MB")
                if temp is not None:
                    store_performance_metric("gpu", f"gpu_{idx}_temperature", temp, "celsius")
                if power is not None:
                    store_performance_metric("gpu", f"gpu_{idx}_power", power, "watts")
                
                # Collect data for API
                gpu_info = {
                    "index": idx,
                    "name": name,
                    "utilization": gpu_util,
                    "memory_utilization": memory_util,
                    "memory_used": memory_used_mb,
                    "memory_total": memory_total_mb,
                    "memory_percent": memory_percent,
                    "temperature": temp,
                    "power_draw": power,
                    "graphics_clock": graphics_clock,
                    "memory_clock": memory_clock
                }
                gpu_data.append(gpu_info)
            
            _latest_gpu_metrics = gpu_data
            
        except Exception as e:
            print(f"Error collecting GPU metrics: {e}")
        
        time.sleep(5)

def get_gpu_metrics():
    """Get latest GPU metrics"""
    return _latest_gpu_metrics.copy()

def get_gpu_info():
    """Get static GPU information"""
    if GPU_COUNT == 0:
        return []
    
    gpu_info = []
    try:
        for idx in range(GPU_COUNT):
            h = pynvml.nvmlDeviceGetHandleByIndex(idx)
            
            name = pynvml.nvmlDeviceGetName(h).decode('utf-8')
            
            # Memory info
            mem = pynvml.nvmlDeviceGetMemoryInfo(h)
            
            # Driver version
            try:
                driver_version = pynvml.nvmlSystemGetDriverVersion().decode('utf-8')
            except:
                driver_version = "Unknown"
            
            # CUDA version
            try:
                cuda_version = pynvml.nvmlSystemGetCudaDriverVersion()
                cuda_major = cuda_version // 1000
                cuda_minor = (cuda_version % 1000) // 10
                cuda_version_str = f"{cuda_major}.{cuda_minor}"
            except:
                cuda_version_str = "Unknown"
            
            # Power limits
            try:
                power_limit = pynvml.nvmlDeviceGetPowerManagementLimitConstraints(h)[1] / 1000.0
            except:
                power_limit = None
            
            gpu_info.append({
                "index": idx,
                "name": name,
                "memory_total_mb": mem.total / (1024**2),
                "driver_version": driver_version,
                "cuda_version": cuda_version_str,
                "power_limit_watts": power_limit
            })
            
    except Exception as e:
        print(f"Error getting GPU info: {e}")
    
    return gpu_info

def check_gpu_alerts():
    """Check for GPU-related alerts"""
    alerts = []
    
    for gpu in _latest_gpu_metrics:
        gpu_idx = gpu["index"]
        
        # High utilization alert
        if gpu["utilization"] > 95:
            alerts.append({
                "type": "gpu_high_utilization",
                "severity": "warning",
                "message": f"GPU {gpu_idx} utilization is {gpu['utilization']}%",
                "gpu": gpu_idx,
                "value": gpu["utilization"]
            })
        
        # High memory usage alert
        if gpu["memory_percent"] > 90:
            alerts.append({
                "type": "gpu_high_memory",
                "severity": "warning", 
                "message": f"GPU {gpu_idx} memory usage is {gpu['memory_percent']:.1f}%",
                "gpu": gpu_idx,
                "value": gpu["memory_percent"]
            })
        
        # High temperature alert
        if gpu["temperature"] and gpu["temperature"] > 80:
            alerts.append({
                "type": "gpu_high_temperature",
                "severity": "critical" if gpu["temperature"] > 90 else "warning",
                "message": f"GPU {gpu_idx} temperature is {gpu['temperature']}°C",
                "gpu": gpu_idx,
                "value": gpu["temperature"]
            })
    
    return alerts

def start():
    """Start GPU metrics collection"""
    if GPU_COUNT:
        threading.Thread(target=collect, daemon=True).start()
        threading.Thread(target=alert_monitor, daemon=True).start()
    else:
        print("No GPUs detected for monitoring")

def alert_monitor():
    """Monitor for GPU alerts"""
    while True:
        try:
            alerts = check_gpu_alerts()
            for alert in alerts:
                from .database import create_alert
                create_alert(
                    alert_type=alert["type"],
                    severity=alert["severity"], 
                    message=alert["message"],
                    container_name=f"gpu_{alert['gpu']}",
                    metric_value=alert["value"]
                )
        except Exception as e:
            print(f"Error in GPU alert monitor: {e}")
        
        time.sleep(60)  # Check every minute
