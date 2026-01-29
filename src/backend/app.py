import http.server
import json
import os

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_GET(self):
        if self.path == '/api/hello':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            # Explicitly allow all origins for debugging
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "message": "Hello from UpCloud Native Python!",
                "status": "success"
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    print("Starting native Python server on port 5000...")
    server = http.server.HTTPServer(('0.0.0.0', 5000), MyHandler)
    server.serve_forever()