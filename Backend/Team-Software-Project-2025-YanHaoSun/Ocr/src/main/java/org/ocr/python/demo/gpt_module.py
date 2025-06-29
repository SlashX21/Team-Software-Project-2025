import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=OPENAI_API_KEY)

def extract_products_from_text(ocr_text: str) -> list:
    prompt = f"""
You are an intelligent receipt parser.

Your task is to extract purchased product information from the following receipt text.

Ignore:
- Store names
- Dates or times
- Total, subtotal, tax, discount, price info
- Payment methods (e.g. Mastercard, Cash)
- Loyalty points or promotions

For each item, try to extract the product **name** and **quantity** if available.

Output in JSON array format:
[
  {{ "name": "Product 1", "quantity": 1 }},
  {{ "name": "Product 2", "quantity": 2 }},
  ...
]

Receipt text:
{ocr_text}
"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}]
    )

    result_text = response.choices[0].message.content.strip()

    # Clean markdown formatting if present
    if result_text.startswith("```json") and result_text.endswith("```"):
        result_text = "\n".join(result_text.split("\n")[1:-1])

    try:
        import json
        return json.loads(result_text)
    except Exception as e:
        print("⚠️ GPT parsing error:", e)
        return []
