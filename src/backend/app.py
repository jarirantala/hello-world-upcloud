import http.server
import json
import sys
import os
import redis

# Valkey configuration from environment variables
VALKEY_HOST = os.getenv('VALKEY_HOST', 'localhost')
VALKEY_PORT = int(os.getenv('VALKEY_PORT', 6379))
VALKEY_USER = os.getenv('VALKEY_USER', 'default')
VALKEY_PASSWORD = os.getenv('VALKEY_PASSWORD', '')

# Initialize Valkey client
try:
    r = redis.Redis(
        host=VALKEY_HOST,
        port=VALKEY_PORT,
        username=VALKEY_USER,
        password=VALKEY_PASSWORD,
        decode_responses=True,
        socket_timeout=5
    )
    print(f"Connected to Valkey at {VALKEY_HOST}:{VALKEY_PORT}")
    # Initialize initial greeting if it doesn't exist (SETNX)
    r.setnx('greeting', 'hello valkey')
except Exception as e:
    print(f"Initial Valkey connection failed: {e}")
    r = None

class MyHandler(http.server.BaseHTTPRequestHandler):
    def send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()

    def do_GET(self):
        visit_count = 0
        greeting = "N/A"
        valkey_status = "Disconnected"
        
        if r:
            try:
                visit_count = r.incr('visit_count')
                greeting = r.get('greeting')
                valkey_status = "Connected"
            except Exception as e:
                print(f"Valkey error: {e}")
                valkey_status = f"Error: {e}"

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_cors_headers()
        self.end_headers()
        
        response = {
            "message": "Hello from UpCloud Kubernetes with Valkey!",
            "greeting": greeting,
            "visit_count": visit_count,
            "valkey_status": valkey_status,
            "status": "success"
        }
        self.wfile.write(json.dumps(response).encode())

if __name__ == '__main__':
    port = 5000
    print(f"Starting Valkey-enabled server on port {port}...")
    sys.stdout.flush()
    server = http.server.HTTPServer(('0.0.0.0', port), MyHandler)
    server.serve_forever()