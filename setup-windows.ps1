# 🪟 Windows 11 Setup Script for OBS Stack Testing
# This script sets up the complete observability stack on Windows for development/testing

param(
    [switch]$SkipPrereqs,
    [switch]$SimulateUsers,
    [int]$UserCount = 50
)

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Blue = "Cyan"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorText "🔍 Checking prerequisites..." $Blue
    
    # Check Docker Desktop
    try {
        $dockerVersion = docker --version
        Write-ColorText "✅ Docker found: $dockerVersion" $Green
    } catch {
        Write-ColorText "❌ Docker Desktop not found or not running" $Red
        Write-ColorText "Please install Docker Desktop and ensure it's running" $Yellow
        exit 1
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version
        Write-ColorText "✅ Docker Compose found: $composeVersion" $Green
    } catch {
        Write-ColorText "❌ Docker Compose not found" $Red
        exit 1
    }
    
    # Check Python
    try {
        $pythonVersion = python --version
        Write-ColorText "✅ Python found: $pythonVersion" $Green
    } catch {
        Write-ColorText "❌ Python not found" $Red
        Write-ColorText "Please install Python 3.11+" $Yellow
        exit 1
    }
    
    # Check available memory
    $memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $memoryGB = [math]::Round($memory.Sum / 1GB, 2)
    
    if ($memoryGB -lt 8) {
        Write-ColorText "⚠️ Warning: Only ${memoryGB}GB RAM available. 8GB+ recommended" $Yellow
    } else {
        Write-ColorText "✅ Memory: ${memoryGB}GB available" $Green
    }
    
    Write-ColorText "✅ Prerequisites check completed" $Green
}

function Setup-WindowsEnvironment {
    Write-ColorText "🔧 Setting up Windows environment..." $Blue
    
    # Create necessary directories
    $directories = @(
        ".\grafana_data",
        ".\prometheus_data", 
        ".\loki_data",
        ".\opshub_data",
        ".\logs"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorText "✅ Created directory: $dir" $Green
        }
    }
    
    # Set proper permissions (Windows equivalent)
    try {
        icacls ".\grafana_data" /grant Everyone:F /T | Out-Null
        icacls ".\prometheus_data" /grant Everyone:F /T | Out-Null
        icacls ".\loki_data" /grant Everyone:F /T | Out-Null
        icacls ".\opshub_data" /grant Everyone:F /T | Out-Null
        Write-ColorText "✅ Directory permissions set" $Green
    } catch {
        Write-ColorText "⚠️ Warning: Could not set directory permissions" $Yellow
    }
}

function Create-WindowsComposeFile {
    Write-ColorText "🐳 Creating Windows Docker Compose configuration..." $Blue
    
    # The docker-compose.windows.yml should already exist
    if (!(Test-Path "docker-compose.windows.yml")) {
        Write-ColorText "❌ docker-compose.windows.yml not found" $Red
        Write-ColorText "Please ensure you have the Windows compose override file" $Yellow
        exit 1
    }
    
    Write-ColorText "✅ Windows Docker Compose file found" $Green
}

function Start-Services {
    Write-ColorText "🚀 Starting services..." $Blue
    
    try {
        # Pull latest images
        Write-ColorText "📥 Pulling Docker images..." $Blue
        docker-compose -f docker-compose.yml -f docker-compose.windows.yml pull
        
        # Start services
        Write-ColorText "🔄 Starting containers..." $Blue
        docker-compose -f docker-compose.yml -f docker-compose.windows.yml up -d
        
        # Wait for services to start
        Write-ColorText "⏳ Waiting for services to start..." $Blue
        Start-Sleep -Seconds 30
        
        # Check service status
        $status = docker-compose ps
        Write-ColorText "📊 Service status:" $Blue
        Write-Host $status
        
        Write-ColorText "✅ Services started successfully" $Green
        
    } catch {
        Write-ColorText "❌ Failed to start services: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Test-ServiceHealth {
    Write-ColorText "🏥 Testing service health..." $Blue
    
    $services = @(
        @{Name="Grafana"; URL="http://localhost:3001/api/health"; Expected="200"},
        @{Name="Prometheus"; URL="http://localhost:9090/-/healthy"; Expected="200"},
        @{Name="OpsHub"; URL="http://localhost:8089/health"; Expected="200"}
    )
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq $service.Expected) {
                Write-ColorText "✅ $($service.Name) is healthy" $Green
            } else {
                Write-ColorText "⚠️ $($service.Name) returned status $($response.StatusCode)" $Yellow
            }
        } catch {
            Write-ColorText "❌ $($service.Name) health check failed" $Red
        }
    }
}

function Install-PythonDependencies {
    Write-ColorText "🐍 Installing Python dependencies..." $Blue
    
    try {
        # Create requirements.txt for Windows testing
        $requirements = @"
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
prometheus-client>=0.19.0
docker>=6.1.0
sqlite3
asyncio
typer>=0.9.0
rich>=13.0.0
requests>=2.31.0
aiofiles>=23.0.0
python-multipart>=0.0.6
"@
        
        Set-Content -Path "requirements-windows.txt" -Value $requirements
        
        # Install dependencies
        python -m pip install --user -r requirements-windows.txt
        Write-ColorText "✅ Python dependencies installed" $Green
        
    } catch {
        Write-ColorText "❌ Failed to install Python dependencies: $($_.Exception.Message)" $Red
    }
}

function Install-CLITools {
    Write-ColorText "🛠️ Installing CLI tools..." $Blue
    
    try {
        # Create a Windows-compatible CLI script
        $cliScript = @"
@echo off
python "%~dp0\opshub\cli.py" %*
"@
        
        Set-Content -Path "docker-logger.bat" -Value $cliScript
        
        # Add to PATH (user PATH)
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $scriptDir = (Get-Location).Path
        
        if ($currentPath -notlike "*$scriptDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$scriptDir", "User")
            Write-ColorText "✅ CLI tools added to PATH" $Green
        } else {
            Write-ColorText "✅ CLI tools already in PATH" $Green
        }
        
        # Test CLI
        cmd /c "docker-logger.bat --help" | Out-Null
        Write-ColorText "✅ CLI tools installed and working" $Green
        
    } catch {
        Write-ColorText "⚠️ CLI tools installation had issues: $($_.Exception.Message)" $Yellow
    }
}

function Start-UserSimulation {
    param([int]$Users = 50)
    
    Write-ColorText "👥 Starting user simulation with $Users users..." $Blue
    
    # Create user simulation script
    $simulationScript = @"
import asyncio
import random
import time
import requests
import json
from datetime import datetime, timedelta

async def simulate_user_activity():
    base_url = "http://localhost:8089"
    
    # Simulate user logins
    for i in range($Users):
        user_data = {
            "user_id": f"test_user_{i:03d}",
            "username": f"testuser{i:03d}",
            "email": f"user{i:03d}@example.com",
            "ip_address": f"192.168.1.{random.randint(10, 254)}",
            "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "device_type": random.choice(["desktop", "mobile", "tablet"]),
            "browser": random.choice(["chrome", "firefox", "edge", "safari"]),
            "os": "Windows 11"
        }
        
        try:
            response = requests.post(f"{base_url}/api/users/login", json=user_data)
            if response.status_code == 200:
                print(f"✅ User {user_data['username']} logged in")
                
                # Simulate model requests for this user
                for j in range(random.randint(1, 10)):
                    model_data = {
                        "user_id": user_data["user_id"],
                        "model_name": random.choice(["llama2", "codellama", "mistral", "mixtral"]),
                        "response_time_ms": random.randint(500, 5000),
                        "input_tokens": random.randint(10, 500),
                        "output_tokens": random.randint(50, 1000),
                        "total_tokens": random.randint(60, 1500),
                        "success": random.choice([True, True, True, False]),  # 75% success rate
                        "prompt_category": random.choice(["chat", "code", "creative", "analysis"])
                    }
                    model_data["total_tokens"] = model_data["input_tokens"] + model_data["output_tokens"]
                    
                    requests.post(f"{base_url}/api/users/model-request", json=model_data)
                    
                    await asyncio.sleep(random.uniform(0.1, 2.0))  # Random delay between requests
                    
            else:
                print(f"❌ Failed to login user {user_data['username']}")
                
        except Exception as e:
            print(f"⚠️ Error simulating user {user_data['username']}: {e}")
        
        await asyncio.sleep(random.uniform(0.1, 1.0))  # Random delay between user logins

if __name__ == "__main__":
    print(f"🚀 Starting simulation with $Users users...")
    asyncio.run(simulate_user_activity())
    print("✅ User simulation completed")
"@
    
    Set-Content -Path "simulate_users.py" -Value $simulationScript
    
    # Run simulation
    try {
        python simulate_users.py
        Write-ColorText "✅ User simulation completed" $Green
    } catch {
        Write-ColorText "❌ User simulation failed: $($_.Exception.Message)" $Red
    }
}

function Show-AccessInformation {
    Write-ColorText "🌐 Access Information:" $Blue
    Write-ColorText "===================" $Blue
    Write-Host ""
    Write-ColorText "📊 Grafana Dashboard: http://localhost:3001" $Green
    Write-ColorText "   Username: admin" $Yellow
    Write-ColorText "   Password: admin" $Yellow
    Write-Host ""
    Write-ColorText "📈 Prometheus: http://localhost:9090" $Green
    Write-Host ""
    Write-ColorText "🔧 OpsHub API: http://localhost:8089" $Green
    Write-Host ""
    Write-ColorText "📊 cAdvisor: http://localhost:8085" $Green
    Write-Host ""
    Write-ColorText "🛠️ CLI Commands:" $Blue
    Write-ColorText "   docker-logger status" $Yellow
    Write-ColorText "   docker-logger users" $Yellow
    Write-ColorText "   docker-logger performance" $Yellow
    Write-ColorText "   docker-logger monitor" $Yellow
    Write-Host ""
}

function Main {
    Write-ColorText "🪟 Starting Windows 11 OBS Stack Setup" $Blue
    Write-ColorText "=====================================" $Blue
    Write-Host ""
    
    if (!$SkipPrereqs) {
        Test-Prerequisites
    }
    
    Setup-WindowsEnvironment
    Create-WindowsComposeFile
    Install-PythonDependencies
    Start-Services
    
    # Wait a bit more for services to fully start
    Write-ColorText "⏳ Waiting for services to fully initialize..." $Blue
    Start-Sleep -Seconds 60
    
    Test-ServiceHealth
    Install-CLITools
    
    if ($SimulateUsers) {
        Start-UserSimulation -Users $UserCount
    }
    
    Show-AccessInformation
    
    Write-ColorText "🎉 Windows setup completed successfully!" $Green
    Write-ColorText "Your observability stack is ready for testing!" $Green
    Write-Host ""
    Write-ColorText "🔄 Next steps:" $Blue
    Write-ColorText "1. Open Grafana at http://localhost:3001" $Yellow
    Write-ColorText "2. Test CLI tools: docker-logger status" $Yellow
    Write-ColorText "3. Run user simulation: .\simulate-users.ps1" $Yellow
    Write-ColorText "4. When ready, deploy to production EC2!" $Yellow
}

# Run main function
Main
