#!/bin/bash

# Auto-Redeploy Script for DJ Calendar
# This script updates git, builds, and redeploys automatically

set -e  # Exit on any error

echo "🚀 Starting automatic redeployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project directory."
    exit 1
fi

# Step 1: Git operations
print_status "📥 Updating git repository..."
git add .
git commit -m "Auto-redeploy: Update port configuration and redeploy" || {
    print_warning "No changes to commit or git not configured"
}

print_status "📤 Pushing to git..."
git push origin master || {
    print_warning "Git push failed or no remote configured"
}

# Step 2: Deploy to VPS
print_status "🌐 Deploying to VPS..."

# Deploy to VPS using SSH
ssh ubuntu@162.19.248.178 << 'EOF'
    set -e
    
    echo "📁 Updating project on VPS..."
    cd /opt/dj-calendar
    
    # Pull latest changes
    git pull origin master || {
        echo "⚠️  Git pull failed, continuing with existing code"
    }
    
    # Stop existing container
    echo "🛑 Stopping existing container..."
    docker compose down || true
    
    # Build and start new container
    echo "🔨 Building and starting new container..."
    docker compose up -d --build
    
    # Wait for container to start
    echo "⏳ Waiting for container to start..."
    sleep 10
    
    # Check if container is running
    if docker ps | grep -q dj-calendar; then
        echo "✅ Container is running successfully!"
        echo "🌐 Calendar should be accessible at: http://162.19.248.178:3000"
        echo "🔗 NPMplus should proxy to: https://calendar.djmarkuss.de"
    else
        echo "❌ Container failed to start. Checking logs..."
        docker compose logs
        exit 1
    fi
    
    # Test the endpoint
    echo "🧪 Testing endpoint..."
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Endpoint is responding correctly!"
    else
        echo "❌ Endpoint is not responding. Checking container logs..."
        docker compose logs
        exit 1
    fi
    
    echo "🎉 Deployment completed successfully!"
EOF

# Step 3: Update firewall if needed
print_status "🔥 Updating firewall rules..."
ssh ubuntu@162.19.248.178 "sudo ufw allow 3000 2>/dev/null || echo 'Port 3000 already allowed'"

# Step 4: Test deployment
print_status "🧪 Testing deployment..."
sleep 5

if curl -f http://162.19.248.178:3000 > /dev/null 2>&1; then
    print_status "✅ Deployment successful! Calendar is accessible at:"
    echo "   Direct: http://162.19.248.178:3000"
    echo "   Domain: https://calendar.djmarkuss.de"
else
    print_error "❌ Deployment failed! Calendar is not accessible."
    exit 1
fi

print_status "🎉 Auto-redeployment completed successfully!"
print_warning "⚠️  Don't forget to update your NPMplus configuration to use port 3000!" 