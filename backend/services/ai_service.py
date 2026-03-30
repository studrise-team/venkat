import sys
import os
import httpx
import json
from typing import List, Dict, Any
from dotenv import load_dotenv

load_dotenv()

# Allow Groq API key via env variable: GROQ_API_KEY
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")


async def generate_mcq_with_ai(text: str, num_questions: int = 5) -> List[Dict[str, Any]]:
    """
    Phase 5: Send theory text to Groq (llama3) and get back MCQs in JSON.
    Requires GROQ_API_KEY environment variable.
    """
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not set. Add it to your environment variables.")

    prompt = f"""
You are an intelligent MCQ parser and generator.

I will provide you with some text. The text might be a raw dump from an exam paper (with mixed languages like Telugu and weird formatting/symbols like ✔ or ✖), OR it might be pure theory text.

Your Task:
1. If the text contains EXISTING multiple-choice questions, EXTRACT them. Fix the formatting, standardize the options, and figure out the correct answer based on context clues or checkmark symbols (e.g., if '3. ✔ 3' is given, the 3rd option is the answer). Ignore the {num_questions} limit and extract ALL of them.
2. If the text is pure theory with NO questions, GENERATE exactly {num_questions} new conceptual multiple-choice questions.

Rules:
- Each question must have exactly 4 options.
- The 'answer' field MUST be the exact string of the correct option from the 'options' array.
- Keep the original languages (e.g. Telugu) intact in the questions and options.
- Return ONLY a valid JSON array. Do not include markdown formatting, tick marks, or any conversational text.

Format:
[
  {{
    "question": "...",
    "options": ["...", "...", "...", "..."],
    "answer": "..."
  }}
]

Text:
{text}
"""

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": "llama-3.3-70b-versatile",
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.4,
            },
        )
        if response.status_code != 200:
            raise Exception(f"Groq API Error {response.status_code}: {response.text}")
        content = response.json()["choices"][0]["message"]["content"]

    # Strip markdown code fences if present
    content = content.replace('```json', '').replace('```', '').strip()

    import re
    # Try to extract just the JSON array part
    match = re.search(r'\[\s*\{.*\}\s*\]', content, re.DOTALL)
    if match:
        content = match.group(0)

    try:
        return json.loads(content)
    except Exception as e:
        print("==== ERROR Parsing Groq AI Output ====")
        print(content)
        raise ValueError(f"AI returned invalid JSON: {content}") from e


async def translate_mcqs_to_telugu(mcqs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Phase 6: Translate English MCQs into Telugu using Groq.
    """
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not set.")

    prompt = f"""
Translate the following English Multiple Choice Questions exactly into Telugu script. 
Keep the JSON array format and keys ('question', 'options', 'answer') exactly as it is, do not translate the keys.
Keep the A, B, C, D indicators as English letters or translate them, but ensure 'answer' matches exactly the translated option or 'A, B, C, D'.
Return ONLY a valid JSON array, nothing else.

Input JSON:
{json.dumps(mcqs, ensure_ascii=False, indent=2)}
"""

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": "llama-3.3-70b-versatile",
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.2,
            },
        )
        response.raise_for_status()
        content = response.json()["choices"][0]["message"]["content"].strip()

    if content.startswith("```"):
        content = content.replace("```json", "", 1).replace("```", "")
    content = content.strip()

    import re
    match = re.search(r'\[.*\]', content, re.DOTALL)
    if match:
        content = match.group(0)

    try:
        return json.loads(content)
    except Exception as e:
        print("Translation parse failed:", content)
        raise e
