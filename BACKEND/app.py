from flask import Flask, request, jsonify
from flask_cors import CORS
from utils.suggest import get_suggestion
from utils.language import detect_language
from utils.linter import lint_code
from utils.score import calculate_score

app = Flask(__name__)
CORS(app) 

@app.route('/ml_suggest', methods=['POST'])
def suggest_code():
    data = request.json
    code = data.get('code', '')
    language = data.get('language', 'python')
    suggestion = get_suggestion(code, language)
    return jsonify({"suggestion": suggestion})


@app.route('/detect_language', methods=['POST'])
def detect():
    data = request.json
    code = data.get('code', '')
    language = detect_language(code)
    return jsonify({"language": language})


@app.route('/syntax_check', methods=['POST'])
def syntax_check():
    data = request.json
    code = data.get('code', '')
    language = data.get('language', 'python')
    errors = lint_code(code, language)
    return jsonify({"errors": errors})


@app.route('/score', methods=['POST'])
def score():
    data = request.json
    original = data.get('original', '')
    corrected = data.get('corrected', '')
    similarity = calculate_score(original, corrected)
    return jsonify({"similarity": similarity})

if __name__ == '__main__':
    print("🚀 Starting Flask server at http://localhost:5000")
    app.run(debug=True)
