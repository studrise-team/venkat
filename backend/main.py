from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.mcq import router as mcq_router

app = FastAPI(
    title="AI Quiz Backend",
    description="OCR text → MCQ parser + AI generator for the Flutter AI Quiz App",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(mcq_router)


@app.get("/")
def health():
    return {"status": "ok", "message": "AI Quiz Backend is running 🚀"}
