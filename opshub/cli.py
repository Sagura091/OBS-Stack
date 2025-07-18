import typer, requests, os, json
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.live import Live
from rich.text import Text

app = typer.Typer(help="Docker Logger - Monitor all your containers")
console = Console()

def get_base_url():
    return f"http://{os.getenv('OPSHUB_HOST','localhost')}:8089"

@app.command()
def logs(
    container: str = typer.Argument(help="Container name or 'all' for all containers"),
    level: str = typer.Option("all", help="Log level: info, warning, error, success, all"),
    follow: bool = typer.Option(False, "-f", "--follow", help="Follow log output"),
    tail: int = typer.Option(100, help="Number of lines to show from the end")
):
    """Stream logs from containers with filtering"""
    url = f"{get_base_url()}/logs/{container}"
    params = {"level": level, "tail": tail, "follow": follow}
    
    try:
        r = requests.get(url, params=params, stream=follow)
        r.raise_for_status()
        
        for line in r.iter_lines():
            if line:
                try:
                    log_entry = json.loads(line.decode())
                    timestamp = log_entry.get('timestamp', '')
                    level = log_entry.get('level', 'INFO')
                    message = log_entry.get('message', '')
                    container_name = log_entry.get('container', '')
                    
                    # Color code by level
                    color = {
                        'INFO': 'blue',
                        'SUCCESS': 'green', 
                        'WARNING': 'yellow',
                        'ERROR': 'red',
                        'CRITICAL': 'bright_red'
                    }.get(level.upper(), 'white')
                    
                    console.print(f"[{color}]{timestamp} [{container_name}] {level}: {message}[/{color}]")
                except json.JSONDecodeError:
                    console.print(line.decode())
                    
    except requests.exceptions.RequestException as e:
        console.print(f"[red]Error connecting to OpsHub: {e}[/red]")

@app.command()
def status():
    """Show status of all containers"""
    try:
        r = requests.get(f"{get_base_url()}/containers/status")
        r.raise_for_status()
        containers = r.json()
        
        table = Table(title="Container Status")
        table.add_column("Container", style="cyan")
        table.add_column("Status", style="green")
        table.add_column("CPU %", style="yellow")
        table.add_column("Memory", style="blue")
        table.add_column("Network I/O", style="magenta")
        table.add_column("Uptime", style="white")
        
        for container in containers:
            status_color = "green" if container['status'] == 'running' else "red"
            table.add_row(
                container['name'],
                f"[{status_color}]{container['status']}[/{status_color}]",
                f"{container.get('cpu_percent', 'N/A')}%",
                container.get('memory_usage', 'N/A'),
                container.get('network_io', 'N/A'),
                container.get('uptime', 'N/A')
            )
        
        console.print(table)
        
    except requests.exceptions.RequestException as e:
        console.print(f"[red]Error: {e}[/red]")

@app.command()
def users():
    """Show OpenWebUI user sessions and activity"""
    try:
        r = requests.get(f"{get_base_url()}/users/sessions")
        r.raise_for_status()
        sessions = r.json()
        
        table = Table(title="OpenWebUI User Sessions")
        table.add_column("User", style="cyan")
        table.add_column("Model", style="green")
        table.add_column("Status", style="yellow")
        table.add_column("Started", style="blue")
        table.add_column("Last Activity", style="magenta")
        table.add_column("Requests", style="white")
        
        for session in sessions:
            table.add_row(
                session.get('username', 'Unknown'),
                session.get('model', 'N/A'),
                session.get('status', 'Unknown'),
                session.get('started_at', 'N/A'),
                session.get('last_activity', 'N/A'),
                str(session.get('request_count', 0))
            )
        
        console.print(table)
        
    except requests.exceptions.RequestException as e:
        console.print(f"[red]Error: {e}[/red]")

@app.command()
def performance():
    """Show system performance metrics"""
    try:
        r = requests.get(f"{get_base_url()}/metrics/performance")
        r.raise_for_status()
        metrics = r.json()
        
        # System overview
        console.print("\n[bold blue]System Performance[/bold blue]")
        console.print(f"CPU Usage: [yellow]{metrics.get('cpu_percent', 'N/A')}%[/yellow]")
        console.print(f"Memory Usage: [yellow]{metrics.get('memory_percent', 'N/A')}%[/yellow]")
        console.print(f"Disk Usage: [yellow]{metrics.get('disk_percent', 'N/A')}%[/yellow]")
        
        # GPU metrics
        if 'gpus' in metrics:
            console.print("\n[bold green]GPU Status[/bold green]")
            gpu_table = Table()
            gpu_table.add_column("GPU", style="cyan")
            gpu_table.add_column("Utilization", style="green")
            gpu_table.add_column("Memory", style="yellow")
            gpu_table.add_column("Temperature", style="red")
            gpu_table.add_column("Power", style="blue")
            
            for gpu in metrics['gpus']:
                gpu_table.add_row(
                    f"GPU {gpu.get('index', 'N/A')}",
                    f"{gpu.get('utilization', 'N/A')}%",
                    f"{gpu.get('memory_used', 'N/A')}/{gpu.get('memory_total', 'N/A')} MB",
                    f"{gpu.get('temperature', 'N/A')}°C",
                    f"{gpu.get('power_draw', 'N/A')}W"
                )
            
            console.print(gpu_table)
        
    except requests.exceptions.RequestException as e:
        console.print(f"[red]Error: {e}[/red]")

@app.command()
def monitor(
    interval: int = typer.Option(5, help="Refresh interval in seconds")
):
    """Live monitoring dashboard"""
    def generate_dashboard():
        try:
            # Get container status
            r = requests.get(f"{get_base_url()}/containers/status")
            containers = r.json() if r.status_code == 200 else []
            
            # Get performance metrics
            r = requests.get(f"{get_base_url()}/metrics/performance")
            metrics = r.json() if r.status_code == 200 else {}
            
            # Create layout
            table = Table(title=f"Live Monitor - {datetime.now().strftime('%H:%M:%S')}")
            table.add_column("Metric", style="cyan")
            table.add_column("Value", style="green")
            
            table.add_row("System CPU", f"{metrics.get('cpu_percent', 'N/A')}%")
            table.add_row("System Memory", f"{metrics.get('memory_percent', 'N/A')}%")
            table.add_row("Running Containers", str(len([c for c in containers if c.get('status') == 'running'])))
            table.add_row("Total Containers", str(len(containers)))
            
            if 'gpus' in metrics:
                for i, gpu in enumerate(metrics['gpus']):
                    table.add_row(f"GPU {i} Util", f"{gpu.get('utilization', 'N/A')}%")
                    table.add_row(f"GPU {i} Temp", f"{gpu.get('temperature', 'N/A')}°C")
            
            return table
            
        except Exception as e:
            return Text(f"Error: {e}", style="red")
    
    with Live(generate_dashboard(), refresh_per_second=1/interval) as live:
        try:
            while True:
                live.update(generate_dashboard())
        except KeyboardInterrupt:
            console.print("\n[yellow]Monitoring stopped[/yellow]")

if __name__ == "__main__":
    app()
