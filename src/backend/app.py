from flask import Flask, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)
# Enable CORS for all domains as per spec (or specific bucket domain if passed via env)
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/hello', methods=['GET'])
def hello():
    response = jsonify({
        "message": "Hello from UpCloud Kubernetes!",
        "status": "success"
    })
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)