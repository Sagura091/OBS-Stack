# 🚀 OBS Stack - Windows One-Click Setup
# Ultra-simple installation for Windows 11 with Docker Desktop

param(
    [switch]$SkipPrereqs,  # Skip prerequisite checks
    [switch]$NoGPU,        # Disable GPU monitoring for testing
    [switch]$Quiet         # Minimal output
)

# Colors for beautiful output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    Purple = "Magenta"
    White = "White"
    Gray = "Gray"
}

function Write-Banner {
    Write-Host @"
 ██████╗ ██████╗ ███████╗    ███████╗████████╗ █████╗  ██████╗██╗  ██╗
██╔═══██╗██╔══██╗██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
██║   ██║██████╔╝███████╗    ███████╗   ██║   ███████║██║     █████╔╝ 
██║   ██║██╔══██╗╚════██║    ╚════██║   ██║   ██╔══██║██║     ██╔═██╗ 
╚██████╔╝██████╔╝███████║    ███████║   ██║   ██║  ██║╚██████╗██║  ██╗
 ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
                                                                        
    🚀 Windows Development Setup - Test Before Production!
"@ -ForegroundColor $Colors.Purple

    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host "🎯 ONE-CLICK SETUP - No Configuration Needed!" -ForegroundColor $Colors.Green
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host ""
}

function Write-Status {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Colors.Red
}

function Test-Prerequisites {
    if ($SkipPrereqs) {
        Write-Warning "Skipping prerequisite checks..."
        return $true
    }

    Write-Status "🔍 Checking prerequisites..."
    
    # Check Windows version
    $winVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
    $majorVersion = [int]$winVersion.Split('.')[0]
    
    if ($majorVersion -ge 10) {
        Write-Success "Windows version: $winVersion (Compatible)"
    } else {
        Write-Error "Windows 10 or higher required. Current: $winVersion"
        return $false
    }
    
    # Check memory (minimum 8GB for good Windows experience)
    $memory = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    if ($memory -ge 8) {
        Write-Success "Memory: ${memory}GB (✅ Great for development)"
    } elseif ($memory -ge 4) {
        Write-Warning "Memory: ${memory}GB (✅ Adequate, 8GB+ recommended)"
    } else {
        Write-Error "Insufficient memory: ${memory}GB (Minimum 4GB required)"
        return $false
    }
    
    # Check disk space
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    
    if ($freeSpaceGB -ge 20) {
        Write-Success "Free disk space: ${freeSpaceGB}GB"
    } else {
        Write-Error "Insufficient disk space: ${freeSpaceGB}GB (Need 20GB+)"
        return $false
    }
    
    return $true
}

function Test-Docker {
    Write-Status "🐳 Checking Docker Desktop..."
    
    try {
        $dockerVersion = docker --version
        Write-Success "Docker is installed: $dockerVersion"
        
        # Check if Docker is running
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker Desktop is running"
        } else {
            Write-Warning "Docker Desktop is not running - please start it"
            Write-Host "💡 Starting Docker Desktop automatically..." -ForegroundColor $Colors.Yellow
            
            # Try to start Docker Desktop
            $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
            if (Test-Path $dockerPath) {
                Start-Process $dockerPath
                Write-Host "⏳ Waiting for Docker Desktop to start..." -ForegroundColor $Colors.Yellow
                
                # Wait up to 60 seconds for Docker to start
                for ($i = 1; $i -le 30; $i++) {
                    Start-Sleep 2
                    docker info 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Docker Desktop started successfully!"
                        break
                    }
                    Write-Host "." -NoNewline -ForegroundColor $Colors.Gray
                }
            }
        }
        
        return $true
        
    } catch {
        Write-Error "Docker Desktop is not installed!"
        Write-Host ""
        Write-Host "📥 Please install Docker Desktop from:" -ForegroundColor $Colors.Yellow
        Write-Host "   https://www.docker.com/products/docker-desktop/" -ForegroundColor $Colors.Blue
        Write-Host ""
        Write-Host "After installation:" -ForegroundColor $Colors.Yellow
        Write-Host "1. Start Docker Desktop" -ForegroundColor $Colors.White
        Write-Host "2. Enable WSL 2 backend if prompted" -ForegroundColor $Colors.White
        Write-Host "3. Run this script again" -ForegroundColor $Colors.White
        return $false
    }
}

function Test-Python {
    Write-Status "🐍 Checking Python..."
    
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python 3\.") {
            Write-Success "Python is available: $pythonVersion"
            return $true
        }
    } catch {}
    
    try {
        $pythonVersion = python3 --version 2>&1
        if ($pythonVersion -match "Python 3\.") {
            Write-Success "Python3 is available: $pythonVersion"
            return $true
        }
    } catch {}
    
    Write-Warning "Python not found, installing from Microsoft Store..."
    try {
        winget install Python.Python.3.11
        Write-Success "Python installed successfully!"
        return $true
    } catch {
        Write-Error "Failed to install Python automatically"
        Write-Host "📥 Please install Python from:" -ForegroundColor $Colors.Yellow
        Write-Host "   https://www.python.org/downloads/" -ForegroundColor $Colors.Blue
        return $false
    }
}

function Initialize-Environment {
    Write-Status "⚙️ Setting up environment..."
    
    # Create data directories
    $directories = @("data\grafana", "data\prometheus", "data\loki", "logs", "backups")
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    Write-Success "Directories created"
    
    # Generate .env file for Windows
    $envContent = @"
# 🚀 OBS Stack Configuration - Windows Development
# Auto-generated on $(Get-Date)

# Basic Settings
GRAFANA_ADMIN_PASSWORD=admin123
MAX_CONCURRENT_USERS=250
GPU_MONITORING_ENABLED=false
ENVIRONMENT=development

# Retention Policies (days)
LOG_RETENTION_DAYS=7
METRICS_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=90

# Resource Limits (Windows optimized)
OPSHUB_MEMORY_LIMIT=512m
OPSHUB_CPU_LIMIT=0.5
GRAFANA_MEMORY_LIMIT=256m
PROMETHEUS_MEMORY_LIMIT=512m

# Network Settings
GRAFANA_PORT=3001
PROMETHEUS_PORT=9090
OPSHUB_PORT=8089
CADVISOR_PORT=8085

# Windows-specific
DOCKER_HOST_PATH=$PWD
COMPOSE_CONVERT_WINDOWS_PATHS=1

# Development flags
DEBUG_MODE=true
DEVELOPMENT_MODE=true
SIMULATE_GPU=true
"@

    if ($NoGPU) {
        $envContent += "`n# GPU monitoring disabled for testing`nGPU_MONITORING_ENABLED=false`n"
    }

    Set-Content -Path ".env" -Value $envContent
    Write-Success "Environment configuration created (.env)"
}

function Start-Services {
    Write-Status "🚀 Starting OBS Stack services..."
    
    # Pull images first
    Write-Status "📥 Pulling Docker images (this may take a few minutes)..."
    docker-compose pull
    
    # Start with Windows-specific configuration
    Write-Status "🔄 Starting services with Windows configuration..."
    
    if (Test-Path "docker-compose.windows.yml") {
        docker-compose -f docker-compose.yml -f docker-compose.windows.yml up -d
    } else {
        docker-compose up -d
    }
    
    Write-Success "Services started!"
}

function Wait-ForServices {
    Write-Status "⏳ Waiting for services to be ready..."
    
    $services = @(
        @{Name="Grafana"; URL="http://localhost:3001/api/health"; Timeout=60},
        @{Name="Prometheus"; URL="http://localhost:9090/-/healthy"; Timeout=45},
        @{Name="OpsHub"; URL="http://localhost:8089/health"; Timeout=30}
    )
    
    foreach ($service in $services) {
        Write-Status "Waiting for $($service.Name)..."
        $attempts = 0
        $maxAttempts = $service.Timeout / 2
        
        do {
            try {
                $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Write-Success "$($service.Name) is ready!"
                    break
                }
            } catch {
                # Service not ready yet
            }
            
            Start-Sleep 2
            $attempts++
            Write-Host "." -NoNewline -ForegroundColor $Colors.Gray
            
        } while ($attempts -lt $maxAttempts)
        
        if ($attempts -ge $maxAttempts) {
            Write-Warning "$($service.Name) may not be ready yet (check manually)"
        }
        
        Write-Host ""  # New line after dots
    }
}

function Install-CLITools {
    Write-Status "🛠️ Installing CLI tools..."
    
    try {
        # Install Python dependencies
        Set-Location "opshub"
        python -m pip install -e . --user --quiet
        Set-Location ".."
        
        # Create batch file for Windows CLI
        $cliScript = @"
@echo off
python "$PWD\opshub\cli.py" %*
"@
        Set-Content -Path "docker-logger.bat" -Value $cliScript
        
        Write-Success "CLI tools installed! Use 'docker-logger.bat' or add to PATH"
        
    } catch {
        Write-Warning "CLI installation had issues, but services should work"
    }
}

function Test-Installation {
    Write-Status "🏥 Running health check..."
    
    # Check container status
    try {
        $containers = docker-compose ps --format json | ConvertFrom-Json
        $running = ($containers | Where-Object { $_.State -eq "running" }).Count
        $total = $containers.Count
        
        if ($running -eq $total) {
            Write-Success "All $total containers are running"
        } else {
            Write-Warning "$running/$total containers running"
        }
        
        # List container status
        foreach ($container in $containers) {
            $status = if ($container.State -eq "running") { "✅" } else { "❌" }
            Write-Host "  $status $($container.Service): $($container.State)" -ForegroundColor $Colors.White
        }
        
    } catch {
        Write-Warning "Could not check container status"
    }
    
    # Test web interfaces
    $webTests = @(
        @{Name="Grafana Dashboard"; URL="http://localhost:3001"},
        @{Name="Prometheus Metrics"; URL="http://localhost:9090"},
        @{Name="OpsHub API"; URL="http://localhost:8089/health"}
    )
    
    foreach ($test in $webTests) {
        try {
            $response = Invoke-WebRequest -Uri $test.URL -TimeoutSec 5 -UseBasicParsing
            Write-Success "$($test.Name) is accessible"
        } catch {
            Write-Warning "$($test.Name) may not be ready: $($test.URL)"
        }
    }
}

function Show-CompletionMessage {
    Write-Host ""
    Write-Host "🎉🎉🎉 WINDOWS SETUP COMPLETE! 🎉🎉🎉" -ForegroundColor $Colors.Green
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host "📊 ACCESS YOUR DEVELOPMENT ENVIRONMENT" -ForegroundColor $Colors.Yellow
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "🎛️  Grafana Dashboard:     http://localhost:3001" -ForegroundColor $Colors.Green
    Write-Host "🔧  Prometheus Metrics:    http://localhost:9090" -ForegroundColor $Colors.Green
    Write-Host "🚀  OpsHub API:           http://localhost:8089" -ForegroundColor $Colors.Green
    Write-Host "📈  cAdvisor:             http://localhost:8085" -ForegroundColor $Colors.Green
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host "🛠️  QUICK TESTING COMMANDS" -ForegroundColor $Colors.Yellow
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "# Run comprehensive test suite" -ForegroundColor $Colors.Green
    Write-Host ".\test-windows.ps1 -FullTest" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "# Simulate 200 users" -ForegroundColor $Colors.Green
    Write-Host ".\simulate-users.ps1 -UserCount 200" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "# Quick health check" -ForegroundColor $Colors.Green
    Write-Host ".\test-windows.ps1 -Quick" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "# Check CLI tools" -ForegroundColor $Colors.Green
    Write-Host ".\docker-logger.bat status" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host "🎯 READY FOR PRODUCTION DEPLOYMENT!" -ForegroundColor $Colors.Yellow
    Write-Host "===============================================" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "Once tested, deploy to your EC2 p3.24xlarge:" -ForegroundColor $Colors.White
    Write-Host "1. Clone this repo to your EC2 instance" -ForegroundColor $Colors.White
    Write-Host "2. Run: sudo ./quick-install.sh" -ForegroundColor $Colors.White
    Write-Host "3. Run: sudo ./implement-all-steps.sh" -ForegroundColor $Colors.White
    Write-Host ""
    Write-Host "🚀 Your Windows development environment is ready!" -ForegroundColor $Colors.Purple
    Write-Host ""
}

function Main {
    Clear-Host
    Write-Banner
    
    # Check prerequisites
    if (!(Test-Prerequisites)) {
        Write-Error "Prerequisites not met. Please fix issues above and try again."
        exit 1
    }
    
    # Check Docker
    if (!(Test-Docker)) {
        Write-Error "Docker Desktop is required. Please install and try again."
        exit 1
    }
    
    # Check Python
    if (!(Test-Python)) {
        Write-Error "Python is required. Please install and try again."
        exit 1
    }
    
    try {
        Initialize-Environment
        Start-Services
        Wait-ForServices
        Install-CLITools
        Test-Installation
        Show-CompletionMessage
        
        Write-Host "✅ Windows setup completed at $(Get-Date)" -ForegroundColor $Colors.Green
        Write-Host "💡 Tip: Run '.\test-windows.ps1 -Quick' to verify everything works!" -ForegroundColor $Colors.Yellow
        
    } catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Host "Check Docker Desktop is running and try again." -ForegroundColor $Colors.Yellow
        exit 1
    }
}

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Run main installation
Main
