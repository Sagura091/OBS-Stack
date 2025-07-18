# 🚀 Quick GitHub Repository Setup Script

Write-Host "🚀 Setting up OBS Stack GitHub Repository..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (!(Test-Path "docker-compose.yml")) {
    Write-Host "❌ Error: Please run this script from the OBS-stack directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "📁 Current directory: $(Get-Location)" -ForegroundColor Green

# Configure Git (you can update these values)
$gitName = Read-Host "Enter your Git username (e.g., 'John Doe')"
$gitEmail = Read-Host "Enter your Git email (e.g., 'john@example.com')"

Write-Host "⚙️ Configuring Git..." -ForegroundColor Yellow
git config user.name "$gitName"
git config user.email "$gitEmail"

Write-Host "✅ Git configured locally for this repository" -ForegroundColor Green

# Check Git status
Write-Host "📊 Git status:" -ForegroundColor Yellow
git status --short

# Create initial commit
Write-Host "📝 Creating initial commit..." -ForegroundColor Yellow
try {
    git commit -m "feat: initial commit - complete OBS stack observability solution

✨ Production-ready monitoring stack for 200+ OpenWebUI users
🔧 Complete Docker observability with Grafana, Prometheus, Loki
👥 Advanced user analytics and behavior tracking
🎯 AWS EC2 p3.24xlarge optimized with GPU monitoring
🪟 Windows 11 development environment for testing
⚡ Intelligent alerting and automatic scaling
📊 Executive dashboards and comprehensive CLI tools
🚀 Enterprise-scale monitoring capabilities"
    
    Write-Host "✅ Initial commit created successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creating commit: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show commit info
Write-Host "📋 Commit details:" -ForegroundColor Yellow
git log --oneline -1

Write-Host ""
Write-Host "🎉 Repository is ready for GitHub!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Create a new repository on GitHub (https://github.com/new)" -ForegroundColor White
Write-Host "   - Repository name: obs-stack" -ForegroundColor Yellow
Write-Host "   - Description: Complete observability & monitoring for 200+ OpenWebUI users" -ForegroundColor Yellow
Write-Host "   - Public or Private (your choice)" -ForegroundColor Yellow
Write-Host "   - Don't initialize with README (we already have one)" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Add the remote and push:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/yourusername/obs-stack.git" -ForegroundColor Yellow
Write-Host "   git branch -M main" -ForegroundColor Yellow
Write-Host "   git push -u origin main" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 Repository features:" -ForegroundColor Cyan
Write-Host "   ✅ Complete .gitignore for Docker/Python/monitoring" -ForegroundColor Green
Write-Host "   ✅ Comprehensive README with badges and documentation" -ForegroundColor Green
Write-Host "   ✅ MIT License with project details" -ForegroundColor Green
Write-Host "   ✅ Contributing guidelines for community" -ForegroundColor Green
Write-Host "   ✅ All source code and scripts organized" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Your OBS stack is ready to share with the world!" -ForegroundColor Magenta
