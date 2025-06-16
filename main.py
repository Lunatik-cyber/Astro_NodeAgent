from fastapi import FastAPI
from app.api import router as api_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Node Agent")
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # или ["http://127.0.0.1:8000"] для безопасности
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)