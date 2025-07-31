#!/bin/bash

echo "🏥 Health Check for DJ Calendar..."

# Check if container is running
if docker ps | grep -q "dj-calendar"; then
    echo "✅ Container is running"
else
    echo "❌ Container is not running"
    exit 1
fi

# Check if port 80 is accessible
if curl -s http://localhost/health > /dev/null; then
    echo "✅ Health endpoint is responding"
else
    echo "❌ Health endpoint is not responding"
fi

# Check if calendar is accessible
if curl -s http://localhost/calendar > /dev/null; then
    echo "✅ Calendar endpoint is responding"
else
    echo "❌ Calendar endpoint is not responding"
fi

# Check container logs for errors
echo "📋 Recent container logs:"
docker logs --tail 10 dj-calendar

echo "🎉 Health check complete!" 