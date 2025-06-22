from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os

# Import utility functions (placeholders)
from utils.suggest import get_suggestion
from utils.language import detect_language
from utils.linter import lint_code
from utils.score import calculate_score

# Load .env variables
load_dotenv()
API_KEY = os.getenv("COHERE_API_KEY")

# Flask setup
app = Flask(__name__)

# CORS Configuration
CORS(app, resources={r"/*": {"origins": [
    "http://localhost:3000",
    "https://web.postman.co",
    "https://static-code-analyzer.netlify.app"
]}})

@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'POST,OPTIONS'
    return response

def is_authorized(data):
    return data.get("api_key") == API_KEY

@app.route('/ml_suggest', methods=['POST'])
def suggest_code():
    data = request.json
    if not is_authorized(data):
        return jsonify({"error": "Unauthorized"}), 401
    code = data.get('code', '')
    language = data.get('language', 'python')
    suggestion = get_suggestion(code, language)
    return jsonify({"suggestion": suggestion})

@app.route('/detect_language', methods=['POST'])
def detect():
    data = request.json
    if not is_authorized(data):
        return jsonify({"error": "Unauthorized"}), 401
    code = data.get('code', '')
    language = detect_language(code)
    return jsonify({"language": language})

@app.route('/syntax_check', methods=['POST'])
def syntax_check():
    data = request.json
    if not is_authorized(data):
        return jsonify({"error": "Unauthorized"}), 401
    code = data.get('code', '')
    language = data.get('language', 'python')
    errors = lint_code(code, language)
    return jsonify({"errors": errors})

@app.route('/score', methods=['POST'])
def score():
    data = request.json
    if not is_authorized(data):
        return jsonify({"error": "Unauthorized"}), 401
    original = data.get('original', '')
    corrected = data.get('corrected', '')
    similarity = calculate_score(original, corrected)
    return jsonify({"similarity": similarity})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"\U0001F680 Starting Flask server at http://0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port)