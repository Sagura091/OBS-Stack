# 🤝 Contributing to OBS Stack

We welcome contributions to the OBS Stack project! This guide will help you get started with contributing to our comprehensive observability and monitoring solution.

## 📋 Table of Contents

- [🎯 Ways to Contribute](#-ways-to-contribute)
- [🛠️ Development Setup](#️-development-setup)
- [📝 Contribution Guidelines](#-contribution-guidelines)
- [🐛 Reporting Issues](#-reporting-issues)
- [✨ Feature Requests](#-feature-requests)
- [🔄 Pull Request Process](#-pull-request-process)
- [📚 Documentation](#-documentation)
- [🧪 Testing](#-testing)
- [💬 Community](#-community)

## 🎯 Ways to Contribute

### 🐛 **Bug Reports**
- Report issues with existing functionality
- Provide detailed reproduction steps
- Include system information and logs

### ✨ **Feature Development**
- Add new monitoring capabilities
- Enhance existing dashboards
- Improve performance and scalability

### 📚 **Documentation**
- Improve installation guides
- Add usage examples
- Create tutorials and how-tos

### 🧪 **Testing**
- Write unit tests for new features
- Test on different environments
- Improve test coverage

### 🎨 **UI/UX Improvements**
- Enhance Grafana dashboards
- Improve CLI tool usability
- Design better visualizations

## 🛠️ Development Setup

### Prerequisites

- **Docker & Docker Compose** - Latest versions
- **Python 3.11+** - For OpsHub development
- **Node.js 18+** - For frontend development (if applicable)
- **Git** - Version control

### 🐧 **Linux Development Setup**

```bash
# Clone your fork
git clone https://github.com/yourusername/obs-stack.git
cd obs-stack

# Set up development environment
chmod +x scripts/setup-dev.sh
./scripts/setup-dev.sh

# Start development stack
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Install development dependencies
cd opshub
pip install -e ".[dev]"

# Run tests
pytest tests/
```

### 🪟 **Windows Development Setup**

```powershell
# Clone your fork
git clone https://github.com/yourusername/obs-stack.git
cd obs-stack

# Set up Windows development environment
.\scripts\setup-dev-windows.ps1

# Start development stack with Windows overrides
docker-compose -f docker-compose.yml -f docker-compose.windows.yml -f docker-compose.dev.yml up -d

# Install development dependencies
cd opshub
pip install -e ".[dev]"

# Run tests
pytest tests/
```

### 🔧 **Development Environment Verification**

```bash
# Check all services are running
docker-compose ps

# Test CLI tools
docker-logger status

# Verify API endpoints
curl http://localhost:8089/health

# Check Grafana access
curl http://localhost:3001/api/health
```

## 📝 Contribution Guidelines

### 🎨 **Code Style**

#### Python (OpsHub/CLI)
```python
# Use Black for formatting
black opshub/ tests/

# Use isort for imports
isort opshub/ tests/

# Follow PEP 8 guidelines
flake8 opshub/ tests/
```

#### Shell Scripts
```bash
# Use ShellCheck for validation
shellcheck scripts/*.sh

# Follow Google Shell Style Guide
# Use 2-space indentation
# Add descriptive comments
```

#### Documentation
```markdown
# Use consistent markdown formatting
# Include code examples
# Add screenshots for UI features
# Keep line length under 100 characters
```

### 🏗️ **Project Structure**

```
obs-stack/
├── 📁 opshub/                    # Main FastAPI application
│   ├── 📄 server.py              # FastAPI server
│   ├── 📄 cli.py                 # CLI commands
│   ├── 📄 metrics_*.py           # Metrics collectors
│   └── 📁 tests/                 # Unit tests
├── 📁 grafana/                   # Grafana configuration
│   ├── 📁 provisioning/          # Automated provisioning
│   └── 📁 dashboards/            # Dashboard definitions
├── 📁 scripts/                   # Setup and utility scripts
├── 📁 docs/                      # Documentation
└── 📁 tests/                     # Integration tests
```

### 🔄 **Git Workflow**

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Write tests** for new functionality
5. **Run the test suite**
   ```bash
   ./scripts/test-all.sh
   ```
6. **Commit with descriptive messages**
   ```bash
   git commit -m "feat: add user session timeout monitoring"
   ```
7. **Push to your fork**
8. **Create a Pull Request**

### 📝 **Commit Message Convention**

```
type(scope): description

feat(monitoring): add GPU temperature alerts
fix(cli): resolve user count calculation bug  
docs(readme): update installation instructions
test(api): add user analytics endpoint tests
refactor(opshub): improve database connection handling
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`

## 🐛 Reporting Issues

### 🔍 **Before Reporting**

1. **Search existing issues** to avoid duplicates
2. **Check documentation** for known solutions
3. **Test with latest version** to ensure issue persists
4. **Gather system information**

### 📋 **Issue Template**

```markdown
## 🐛 Bug Report

### Description
Clear description of the issue

### Environment
- OS: [e.g., Ubuntu 20.04, Windows 11]
- Docker Version: [e.g., 24.0.7]
- Python Version: [e.g., 3.11.5]
- Browser: [e.g., Chrome 120] (if applicable)

### Steps to Reproduce
1. Step one
2. Step two
3. Step three

### Expected Behavior
What should happen

### Actual Behavior
What actually happens

### Logs
```bash
# Include relevant logs
docker-compose logs opshub
```

### Screenshots
If applicable, add screenshots

### Additional Context
Any other context about the problem
```

## ✨ Feature Requests

### 💡 **Feature Request Template**

```markdown
## ✨ Feature Request

### Summary
Brief description of the feature

### Problem
What problem does this solve?

### Proposed Solution
Detailed description of the proposed feature

### Alternatives Considered
Other solutions you've considered

### Implementation Ideas
Technical suggestions for implementation

### Examples
Examples or mockups if applicable
```

## 🔄 Pull Request Process

### 📋 **PR Checklist**

- [ ] **Code follows style guidelines**
- [ ] **Tests added for new functionality**
- [ ] **All tests pass locally**
- [ ] **Documentation updated**
- [ ] **CHANGELOG.md updated** (for significant changes)
- [ ] **Screenshots included** (for UI changes)

### 🧪 **Testing Requirements**

```bash
# Run full test suite
./scripts/test-all.sh

# Test specific components
pytest tests/test_opshub.py
pytest tests/test_cli.py

# Integration tests
./scripts/test-integration.sh

# Windows-specific tests
.\test-windows.ps1 -FullTest
```

### 📝 **PR Template**

```markdown
## 📝 Pull Request

### Description
Brief description of changes

### Type of Change
- [ ] Bug fix
- [ ] New feature  
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

### Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

### Screenshots
Include screenshots for UI changes

### Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## 📚 Documentation

### 📖 **Documentation Standards**

- **Clear and concise** language
- **Code examples** for all features
- **Screenshots** for UI components
- **Step-by-step guides** for complex procedures
- **Cross-references** between related topics

### 📁 **Documentation Structure**

```
docs/
├── 📄 installation.md           # Installation guides
├── 📄 configuration.md          # Configuration options
├── 📄 api.md                   # API documentation
├── 📄 dashboards.md            # Dashboard guides
├── 📄 troubleshooting.md       # Common issues
├── 📄 scaling.md               # Scaling guides
└── 📁 images/                  # Screenshots and diagrams
```

## 🧪 Testing

### 🔬 **Test Categories**

#### Unit Tests
```python
# Test individual functions
def test_user_count_calculation():
    assert calculate_active_users(test_data) == 42

# Test API endpoints
def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
```

#### Integration Tests
```bash
# Test complete workflows
./scripts/test-user-monitoring.sh
./scripts/test-alerting.sh
./scripts/test-scaling.sh
```

#### Performance Tests
```python
# Load testing
async def test_concurrent_users():
    # Simulate 200+ concurrent users
    tasks = [simulate_user() for _ in range(200)]
    results = await asyncio.gather(*tasks)
    assert all(r.success for r in results)
```

### 📊 **Test Coverage**

```bash
# Generate coverage report
pytest --cov=opshub tests/
coverage html

# View detailed coverage
open htmlcov/index.html
```

## 💬 Community

### 🌐 **Communication Channels**

- **GitHub Discussions** - General questions and community support
- **GitHub Issues** - Bug reports and feature requests
- **Pull Requests** - Code contributions and reviews

### 🎯 **Community Guidelines**

- **Be respectful** and constructive
- **Help others** learn and contribute
- **Share knowledge** and best practices
- **Provide feedback** on proposals and PRs
- **Follow** our Code of Conduct

### 🏆 **Recognition**

Contributors will be recognized in:
- **README.md** contributors section
- **CHANGELOG.md** for significant contributions
- **GitHub Discussions** community highlights

## 🚀 Development Roadmap

### 🎯 **Current Priorities**

1. **Enhanced User Analytics** - Advanced behavior pattern analysis
2. **Improved Scaling** - More intelligent auto-scaling algorithms
3. **Additional Integrations** - Support for more monitoring tools
4. **Performance Optimization** - Reduced resource usage
5. **Security Enhancements** - Advanced security monitoring

### 💡 **Areas for Contribution**

- **Grafana Dashboards** - New visualization types
- **Alert Rules** - Smart alerting conditions
- **CLI Enhancements** - Additional commands and features
- **Documentation** - More examples and tutorials
- **Testing** - Improved test coverage and scenarios

---

## 🙏 Thank You!

Thank you for contributing to OBS Stack! Your contributions help make enterprise-scale OpenWebUI monitoring better for everyone.

**Questions?** Feel free to reach out through GitHub Discussions or create an issue.

---

**Happy Contributing! 🚀**
