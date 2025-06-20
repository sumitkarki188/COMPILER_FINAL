import google.generativeai as genai

genai.configure(api_key="AILKALL")

model = genai.GenerativeModel("gemini-pro")

response = model.generate_content("Write a Python function that adds two numbers.")
print(response.text)
