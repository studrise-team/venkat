# AI Quiz Backend

FastAPI backend for AI-powered MCQ generation using Groq.

## Local Development
```bash
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0
```

## Deployment (Render)
Set the environment variable `GROQ_API_KEY` in Render dashboard.
Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
