from flask import Flask, send_from_directory, render_template_string
import os

app = Flask(__name__)

@app.route('/')
def index():
    return send_from_directory('.', 'event_calendar_minified.html')

@app.route('/calendar')
def calendar():
    return send_from_directory('.', 'event_calendar_minified.html')

@app.route('/404')
def error_404():
    return send_from_directory('.', '404.html')

@app.route('/<path:filename>')
def serve_file(filename):
    if os.path.exists(filename):
        return send_from_directory('.', filename)
    else:
        return send_from_directory('.', '404.html'), 404

@app.errorhandler(404)
def not_found(error):
    return send_from_directory('.', '404.html'), 404

if __name__ == '__main__':
    # Use environment variable for port, default to 5000
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False) 