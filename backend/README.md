# AI Quiz Backend

## Setup

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| GET | `/` | Health check |
| POST | `/mcq/parse` | Parse MCQs from raw OCR text (regex) |
| POST | `/mcq/generate` | Generate MCQs from theory text (Groq AI) |

## /mcq/parse — Request body

```json
{
  "text": "1. What is AI?\nA) Robot\nB) Intelligence\nC) Computer\nD) Data\nAnswer: B"
}
```

## /mcq/generate — Request body

```json
{
  "text": "Photosynthesis is the process by which plants make food using sunlight.",
  "num_questions": 5
}
```

Set your Groq API key before using `/generate`:

```bash
# Windows PowerShell
$env:GROQ_API_KEY = "your_key_here"

# Linux / Mac
export GROQ_API_KEY=your_key_here
```

Get a free key at https://console.groq.com
