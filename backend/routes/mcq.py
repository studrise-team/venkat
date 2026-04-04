from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from services.parser_service import parse_mcq_from_text
from services.ai_service import generate_mcq_with_ai, translate_mcqs_to_telugu

router = APIRouter(prefix="/mcq", tags=["MCQ"])


class TextInput(BaseModel):
    text: str
    num_questions: int = 5


class MCQItem(BaseModel):
    question: str
    options: List[str]
    answer: str


@router.post("/parse", response_model=List[MCQItem])
def parse_questions(body: TextInput):
    """
    Phase 4: Parse MCQs from raw text using regex.
    Falls back to AI if regex returns nothing.
    """
    if not body.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty.")

    results = parse_mcq_from_text(body.text)
    if not results:
        raise HTTPException(
            status_code=422,
            detail="No MCQs detected. Make sure text uses A) B) C) D) Answer: X format."
        )
    return results


@router.post("/generate", response_model=List[MCQItem])
async def generate_questions(body: TextInput):
    """
    Phase 5: Generate MCQs from theory text using Groq AI.
    """
    if not body.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty.")

    try:
        results = await generate_mcq_with_ai(body.text, body.num_questions)
        return results
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation failed: {e}")

class TranslateRequest(BaseModel):
    mcqs: List[Dict[str, Any]]

@router.post("/translate")
async def translate_mcq(req: TranslateRequest):
    """
    Phase 6: Translate English MCQs into Telugu.
    """
    try:
        translated = await translate_mcqs_to_telugu(req.mcqs)
        return {"status": "success", "data": translated}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")
