FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY event_calendar_minified.html .
COPY server.py .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Create nginx log directory
RUN mkdir -p /var/log/nginx

# Expose port 80
EXPOSE 80

# Create startup script
RUN echo '#!/bin/bash\n\
service nginx start\n\
python server.py\n\
' > /app/start.sh && chmod +x /app/start.sh

# Start nginx and the application
CMD ["/app/start.sh"] 