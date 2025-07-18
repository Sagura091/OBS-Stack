@echo off
REM 🚀 OBS Stack - Simple Windows Commands

if "%1"=="" goto usage
if "%1"=="help" goto usage

if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="status" goto status
if "%1"=="logs" goto logs
if "%1"=="test" goto test
if "%1"=="install" goto install
if "%1"=="monitor" goto monitor

echo ❌ Unknown command: %1
goto usage

:start
echo 🚀 Starting OBS Stack services...
docker-compose -f docker-compose.yml -f docker-compose.windows.yml up -d
echo ✅ Services started!
echo.
echo Access your dashboards:
echo   Grafana: http://localhost:3001 (admin/admin)
echo   Prometheus: http://localhost:9090
echo   OpsHub API: http://localhost:8089
goto end

:stop
echo 🛑 Stopping OBS Stack services...
docker-compose down
echo ✅ Services stopped!
goto end

:restart
echo 🔄 Restarting OBS Stack services...
docker-compose down
timeout 3 >nul
call %0 start
goto end

:status
echo 📊 Service Status:
docker-compose ps
echo.
echo 🔗 Quick Links:
echo   Grafana: http://localhost:3001
echo   Prometheus: http://localhost:9090
echo   OpsHub API: http://localhost:8089
goto end

:logs
if "%2"=="" (
    echo 📋 Showing logs for all services:
    docker-compose logs -f
) else (
    echo 📋 Showing logs for service: %2
    docker-compose logs -f %2
)
goto end

:test
echo 🧪 Running comprehensive tests...
powershell -ExecutionPolicy Bypass -File "test-windows.ps1" -FullTest
goto end

:install
echo 🔧 Running Windows installation...
powershell -ExecutionPolicy Bypass -File "quick-install-windows.ps1"
goto end

:monitor
echo 🖥️ Opening monitoring dashboards...
start http://localhost:3001
echo ✅ Grafana dashboard opened in browser
goto end

:usage
echo.
echo 🚀 OBS Stack - Simple Windows Commands
echo.
echo Usage: obs.bat [command]
echo.
echo Commands:
echo   start     - Start all services
echo   stop      - Stop all services  
echo   restart   - Restart all services
echo   status    - Show service status
echo   logs      - Show logs from all services
echo   logs [service] - Show logs from specific service
echo   test      - Run comprehensive tests
echo   install   - Run full installation
echo   monitor   - Open monitoring dashboards
echo.
echo Examples:
echo   obs.bat start
echo   obs.bat logs opshub
echo   obs.bat test
echo.

:end
