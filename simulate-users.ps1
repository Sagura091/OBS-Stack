# 👥 Windows User Simulation Script
# Simulates 200+ OpenWebUI users for testing

param(
    [int]$UserCount = 200,
    [int]$Duration = 600,  # 10 minutes
    [string]$LogLevel = "INFO"
)

$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Blue = "Cyan"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host "$(Get-Date -Format 'HH:mm:ss') $Text" -ForegroundColor $Color
}

# Create Python simulation script
$simulationScript = @"
import asyncio
import aiohttp
import sqlite3
import random
import json
import time
from datetime import datetime, timedelta
from typing import List, Dict
import logging

# Configure logging
logging.basicConfig(
    level=logging.$LogLevel,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class UserSimulator:
    def __init__(self, user_count: int, duration: int):
        self.user_count = user_count
        self.duration = duration
        self.api_base = "http://localhost:8089"
        self.session = None
        self.active_users = []
        self.stats = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'users_created': 0,
            'sessions_started': 0,
            'chat_messages': 0,
            'model_requests': 0
        }
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def generate_user_data(self, user_id: int) -> Dict:
        """Generate realistic user data"""
        names = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
        departments = ["Engineering", "Sales", "Marketing", "Support", "Research", "Admin"]
        models = ["gpt-4", "claude-3", "llama-2", "mistral", "codellama"]
        
        return {
            'user_id': f"sim_user_{user_id:04d}",
            'username': f"{random.choice(names)}{user_id}",
            'email': f"user{user_id}@testcompany.com",
            'department': random.choice(departments),
            'preferred_model': random.choice(models),
            'session_id': f"sess_{user_id}_{int(time.time())}",
            'ip_address': f"192.168.1.{random.randint(100, 254)}",
            'user_agent': "OpenWebUI/1.0 Test Client"
        }
    
    async def create_user(self, user_data: Dict) -> bool:
        """Create a user in the system"""
        try:
            async with self.session.post(
                f"{self.api_base}/api/users",
                json=user_data
            ) as response:
                self.stats['total_requests'] += 1
                
                if response.status in [200, 201]:
                    self.stats['successful_requests'] += 1
                    self.stats['users_created'] += 1
                    logger.debug(f"✅ Created user: {user_data['username']}")
                    return True
                else:
                    self.stats['failed_requests'] += 1
                    logger.warning(f"❌ Failed to create user {user_data['username']}: {response.status}")
                    return False
                    
        except Exception as e:
            self.stats['failed_requests'] += 1
            logger.error(f"❌ Error creating user {user_data['username']}: {e}")
            return False
    
    async def start_session(self, user_data: Dict) -> bool:
        """Start a user session"""
        try:
            session_data = {
                'user_id': user_data['user_id'],
                'session_id': user_data['session_id'],
                'ip_address': user_data['ip_address'],
                'user_agent': user_data['user_agent']
            }
            
            async with self.session.post(
                f"{self.api_base}/api/sessions/start",
                json=session_data
            ) as response:
                self.stats['total_requests'] += 1
                
                if response.status in [200, 201]:
                    self.stats['successful_requests'] += 1
                    self.stats['sessions_started'] += 1
                    logger.debug(f"🔐 Started session for: {user_data['username']}")
                    return True
                else:
                    self.stats['failed_requests'] += 1
                    return False
                    
        except Exception as e:
            self.stats['failed_requests'] += 1
            logger.error(f"❌ Error starting session for {user_data['username']}: {e}")
            return False
    
    async def send_chat_message(self, user_data: Dict) -> bool:
        """Simulate sending a chat message"""
        try:
            messages = [
                "Hello, how are you today?",
                "Can you help me write a Python function?",
                "What's the weather like?",
                "Explain quantum computing",
                "Write a haiku about programming",
                "How do I deploy a Docker container?",
                "What are the best practices for API design?",
                "Can you summarize this document for me?",
                "Help me debug this code",
                "What's the latest in AI research?"
            ]
            
            chat_data = {
                'user_id': user_data['user_id'],
                'session_id': user_data['session_id'],
                'message': random.choice(messages),
                'model': user_data['preferred_model'],
                'timestamp': datetime.utcnow().isoformat()
            }
            
            async with self.session.post(
                f"{self.api_base}/api/chat",
                json=chat_data
            ) as response:
                self.stats['total_requests'] += 1
                
                if response.status in [200, 201]:
                    self.stats['successful_requests'] += 1
                    self.stats['chat_messages'] += 1
                    logger.debug(f"💬 Chat message from: {user_data['username']}")
                    return True
                else:
                    self.stats['failed_requests'] += 1
                    return False
                    
        except Exception as e:
            self.stats['failed_requests'] += 1
            logger.error(f"❌ Error sending chat for {user_data['username']}: {e}")
            return False
    
    async def make_model_request(self, user_data: Dict) -> bool:
        """Simulate a model inference request"""
        try:
            request_data = {
                'user_id': user_data['user_id'],
                'session_id': user_data['session_id'],
                'model': user_data['preferred_model'],
                'prompt_tokens': random.randint(50, 500),
                'completion_tokens': random.randint(100, 1000),
                'total_tokens': random.randint(150, 1500),
                'processing_time': random.uniform(0.5, 5.0),
                'gpu_utilization': random.uniform(0.6, 0.95),
                'memory_usage': random.uniform(0.4, 0.8)
            }
            
            async with self.session.post(
                f"{self.api_base}/api/model-requests",
                json=request_data
            ) as response:
                self.stats['total_requests'] += 1
                
                if response.status in [200, 201]:
                    self.stats['successful_requests'] += 1
                    self.stats['model_requests'] += 1
                    logger.debug(f"🤖 Model request from: {user_data['username']}")
                    return True
                else:
                    self.stats['failed_requests'] += 1
                    return False
                    
        except Exception as e:
            self.stats['failed_requests'] += 1
            logger.error(f"❌ Error with model request for {user_data['username']}: {e}")
            return False
    
    async def simulate_user_activity(self, user_data: Dict):
        """Simulate realistic user activity patterns"""
        logger.info(f"🚀 Starting activity for user: {user_data['username']}")
        
        # Create user and start session
        if not await self.create_user(user_data):
            return
            
        if not await self.start_session(user_data):
            return
        
        # Activity loop
        start_time = time.time()
        last_activity = start_time
        
        while (time.time() - start_time) < self.duration:
            try:
                # Random activity patterns
                activity_type = random.choices(
                    ['chat', 'model_request', 'idle'],
                    weights=[0.4, 0.3, 0.3]
                )[0]
                
                if activity_type == 'chat':
                    await self.send_chat_message(user_data)
                elif activity_type == 'model_request':
                    await self.make_model_request(user_data)
                else:
                    # Idle time
                    await asyncio.sleep(random.uniform(1, 5))
                
                # Variable delay between activities
                delay = random.uniform(0.5, 3.0)
                await asyncio.sleep(delay)
                
                last_activity = time.time()
                
            except asyncio.CancelledError:
                logger.info(f"🛑 User {user_data['username']} activity cancelled")
                break
            except Exception as e:
                logger.error(f"❌ Error in user activity for {user_data['username']}: {e}")
                await asyncio.sleep(1)
        
        logger.info(f"✅ Completed activity for user: {user_data['username']}")
    
    async def run_simulation(self):
        """Run the full user simulation"""
        logger.info(f"🎬 Starting simulation: {self.user_count} users for {self.duration} seconds")
        
        # Generate all user data
        users = [self.generate_user_data(i) for i in range(1, self.user_count + 1)]
        
        # Create tasks for all users
        tasks = []
        
        # Stagger user creation to avoid overwhelming the system
        batch_size = 20
        for i in range(0, len(users), batch_size):
            batch = users[i:i + batch_size]
            
            # Start batch of users
            for user_data in batch:
                task = asyncio.create_task(self.simulate_user_activity(user_data))
                tasks.append(task)
            
            # Small delay between batches
            await asyncio.sleep(2)
            logger.info(f"📊 Started batch {i//batch_size + 1}/{(len(users)-1)//batch_size + 1}")
        
        # Monitor progress
        start_time = time.time()
        while tasks and (time.time() - start_time) < self.duration + 30:  # Grace period
            # Print stats every 30 seconds
            await asyncio.sleep(30)
            self.print_stats()
            
            # Remove completed tasks
            tasks = [task for task in tasks if not task.done()]
        
        # Cancel remaining tasks
        for task in tasks:
            task.cancel()
        
        # Wait for cleanup
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
        
        logger.info("🏁 Simulation completed!")
        self.print_final_stats()
    
    def print_stats(self):
        """Print current statistics"""
        success_rate = (self.stats['successful_requests'] / max(self.stats['total_requests'], 1)) * 100
        
        logger.info("📊 Current Stats:")
        logger.info(f"  👥 Users Created: {self.stats['users_created']}")
        logger.info(f"  🔐 Sessions Started: {self.stats['sessions_started']}")
        logger.info(f"  💬 Chat Messages: {self.stats['chat_messages']}")
        logger.info(f"  🤖 Model Requests: {self.stats['model_requests']}")
        logger.info(f"  📡 Total Requests: {self.stats['total_requests']}")
        logger.info(f"  ✅ Success Rate: {success_rate:.1f}%")
    
    def print_final_stats(self):
        """Print final simulation statistics"""
        success_rate = (self.stats['successful_requests'] / max(self.stats['total_requests'], 1)) * 100
        
        logger.info("🎉 Final Simulation Results:")
        logger.info("=" * 50)
        logger.info(f"  Target Users: {self.user_count}")
        logger.info(f"  Duration: {self.duration} seconds")
        logger.info(f"  Users Created: {self.stats['users_created']}")
        logger.info(f"  Sessions Started: {self.stats['sessions_started']}")
        logger.info(f"  Chat Messages: {self.stats['chat_messages']}")
        logger.info(f"  Model Requests: {self.stats['model_requests']}")
        logger.info(f"  Total API Requests: {self.stats['total_requests']}")
        logger.info(f"  Successful Requests: {self.stats['successful_requests']}")
        logger.info(f"  Failed Requests: {self.stats['failed_requests']}")
        logger.info(f"  Success Rate: {success_rate:.1f}%")
        logger.info("=" * 50)

async def main():
    import sys
    
    # Get parameters from command line or use defaults
    user_count = $UserCount if len(sys.argv) < 2 else int(sys.argv[1])
    duration = $Duration if len(sys.argv) < 3 else int(sys.argv[2])
    
    async with UserSimulator(user_count, duration) as simulator:
        await simulator.run_simulation()

if __name__ == "__main__":
    asyncio.run(main())
"@

Write-ColorText "👥 Starting Windows User Simulation" $Blue
Write-ColorText "===================================" $Blue
Write-Host ""

# Create the simulation script
Write-ColorText "📝 Creating Python simulation script..." $Yellow
Set-Content -Path "user_simulation.py" -Value $simulationScript

# Install required packages
Write-ColorText "📦 Installing required Python packages..." $Yellow
try {
    pip install aiohttp sqlite3 --quiet
    Write-ColorText "✅ Packages installed successfully" $Green
} catch {
    Write-ColorText "❌ Failed to install packages: $($_.Exception.Message)" $Red
    exit 1
}

# Start simulation
Write-ColorText "🚀 Starting user simulation..." $Blue
Write-ColorText "  👥 Users: $UserCount" $Yellow
Write-ColorText "  ⏱️ Duration: $Duration seconds" $Yellow
Write-ColorText "  📊 Log Level: $LogLevel" $Yellow
Write-Host ""

try {
    python user_simulation.py $UserCount $Duration
    Write-ColorText "✅ User simulation completed successfully!" $Green
} catch {
    Write-ColorText "❌ User simulation failed: $($_.Exception.Message)" $Red
    exit 1
}

Write-ColorText "🎉 Windows user simulation finished!" $Green
