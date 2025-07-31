FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY event_calendar_minified.html .
COPY server.py .

# Expose port 5000 for Flask app
EXPOSE 5000

# Start the Flask application directly
CMD ["python", "server.py"] 