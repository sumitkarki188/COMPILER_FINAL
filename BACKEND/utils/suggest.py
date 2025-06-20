import cohere
import os
import re

cohere_client = cohere.Client("USE YOUR API KEY")

def is_garbage_output(text):
    patterns = [
        r"^[{}()\[\]<>\"'\\\s]*$",
        r"\(x, y\)+",
        r"[\s{}\[\]();:\"'\\]{10,}",
        r"^\s*$"
    ]
    return any(re.fullmatch(p, text) or len(set(text)) <= 5 for p in patterns)

prompt_template = """\
You are a senior code reviewer and fixer.

Analyze the following {language} code:
- Fix all syntax and logical errors
- Return only the corrected code
- **Add explanation as comments using the correct syntax for {language}**

For example:
- Use `# comment` for Python
- Use `// comment` for C, C++, Java, JavaScript

Do not include any markdown. Just return a valid {language} code file with comments explaining the fixes.

### Original {language} Code:
{code}

### Corrected and Commented Code:
"""

def get_suggestion(code: str, language: str = "python") -> str:
    code = code.strip()
    if not code:
        return "⚠️ No code input provided."

    prompt = prompt_template.format(language=language.capitalize(), code=code)

    try:
        response = cohere_client.chat(
            message=prompt,
            model="command-r-plus",  
            temperature=0.3
        )
        suggestion = response.text.strip()

        if is_garbage_output(suggestion):
            return "⚠️ No useful suggestion generated. Try again."

        return suggestion

    except Exception as e:
        return f"❌ Cohere Error: {e}"


#PBL PROJECT OF BTECH CSE 3RD YEAR BY SK###