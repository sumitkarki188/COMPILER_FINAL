from flask import Flask, request, jsonify
from flask_cors import CORS
from utils.suggest import get_suggestion
from utils.language import detect_language
from utils.linter import lint_code
from utils.score import calculate_score
from dotenv import load_dotenv
import os

load_dotenv()
app = Flask(__name__)
CORS(app)

API_KEY = os.getenv("COHERE_API_KEY")

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
    print("🚀 Starting Flask server at http://localhost:5000")
    app.run(debug=True)
