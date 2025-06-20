import tempfile
import subprocess
import os

def lint_code(code, lang):
    ext_map = {
        'python': '.py',
        'java': '.java',
        'c': '.c',
        'cpp': '.cpp'
    }

    extension = ext_map.get(lang.lower(), '.txt')

    with tempfile.NamedTemporaryFile(delete=False, suffix=extension, mode='w') as temp:
        temp.write(code)
        temp_path = temp.name

    errors = []

    try:
        if lang == 'python':
            result = subprocess.run(['python', '-m', 'py_compile', temp_path],
                                    stderr=subprocess.PIPE, text=True)
        elif lang == 'java':
            result = subprocess.run(['javac', temp_path],
                                    stderr=subprocess.PIPE, text=True)
        elif lang == 'c':
            result = subprocess.run(['gcc', '-fsyntax-only', temp_path],
                                    stderr=subprocess.PIPE, text=True)
        elif lang == 'cpp':
            result = subprocess.run(['g++', '-fsyntax-only', temp_path],
                                    stderr=subprocess.PIPE, text=True)
        else:
            return ['Unsupported language']

        if result.stderr:
            errors = result.stderr.strip().split('\n')
    finally:
        os.remove(temp_path)

    return errors
