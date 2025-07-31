#!/bin/bash

# DJ Calendar VPS Deployment Script
# Run this on your VPS (162.19.248.178)

set -e  # Exit on any error

echo "🚀 Starting DJ Calendar deployment on VPS..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "⚠️  Please log out and back in for Docker group changes to take effect"
    exit 1
fi

# Install Docker Compose if not already installed
if ! command -v docker compose &> /dev/null; then
    echo "📋 Installing Docker Compose..."
    sudo apt install docker-compose-plugin -y
fi

# Create deployment directory
DEPLOY_DIR="/opt/dj-calendar"
echo "📁 Creating deployment directory: $DEPLOY_DIR"
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR

# Clone or update repository
if [ -d "$DEPLOY_DIR/.git" ]; then
    echo "🔄 Updating existing repository..."
    cd $DEPLOY_DIR
    git pull origin main
else
    echo "📥 Cloning repository..."
    cd /opt
    git clone https://github.com/yourusername/dj-calendar.git dj-calendar
    cd dj-calendar
fi

# Stop existing container if running
echo "🛑 Stopping existing containers..."
docker compose down || true

# Build and start the container
echo "🔨 Building and starting Docker container..."
docker compose up -d --build

# Wait for container to start
echo "⏳ Waiting for container to start..."
sleep 10

# Check if container is running
if docker ps | grep -q dj-calendar; then
    echo "✅ Container is running successfully!"
    echo "🌐 Calendar should be accessible at: http://162.19.248.178:5000"
    echo "🔗 NPMplus should proxy to: https://calendar.djmarkuss.de"
else
    echo "❌ Container failed to start. Checking logs..."
    docker compose logs
    exit 1
fi

# Test the endpoint
echo "🧪 Testing endpoint..."
if curl -f http://localhost:5000 > /dev/null 2>&1; then
    echo "✅ Endpoint is responding correctly!"
else
    echo "❌ Endpoint is not responding. Checking container logs..."
    docker compose logs
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Check NPMplus configuration points to: http://162.19.248.178:5000"
echo "2. Test the calendar at: https://calendar.djmarkuss.de"
echo "3. Monitor logs with: docker compose logs -f" 