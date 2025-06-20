import re

def detect_language(code):
    code = code.strip()
    lines = code.splitlines()

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith(('#', '//', '/*', '*', '*/')):
            continue
        first_real_line = stripped
        break
    else:
        return 'plaintext'

    if '#include' in code:
        return 'cpp' if 'std::' in code or 'cout' in code else 'c'
    if 'import java' in code or 'System.out.println' in code:
        return 'java'
    if 'def ' in code or re.search(r'^\s*import\s+\w+', code, re.MULTILINE):
        return 'python'

    return 'plaintext'
