from flask import Flask, send_from_directory
import os

app = Flask(__name__)

@app.route('/')
def index():
    return send_from_directory('.', 'event_calendar_minified.html')

@app.route('/calendar')
def calendar():
    # Serve the same file but with a different context
    return send_from_directory('.', 'event_calendar_minified.html')

@app.route('/calendar/')
def calendar_slash():
    # Handle trailing slash
    return send_from_directory('.', 'event_calendar_minified.html')

@app.route('/<path:filename>')
def serve_file(filename):
    return send_from_directory('.', filename)

if __name__ == '__main__':
    # Use environment variable for port, default to 5000
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False) 