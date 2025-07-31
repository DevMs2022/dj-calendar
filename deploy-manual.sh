#!/bin/bash

# Manual Deployment Script for DJ Calendar
# Run this on your VPS

echo "🚀 Starting manual deployment..."

# Navigate to project directory
cd /opt/dj-calendar

# Pull latest changes
echo "📥 Pulling latest changes from git..."
git pull origin master

# Stop existing container
echo "🛑 Stopping existing container..."
docker compose down

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
echo ""
echo "⚠️  Don't forget to update your NPMplus configuration to use port 3000!" 