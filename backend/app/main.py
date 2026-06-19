import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.database import get_supabase
from app.routers import reports, queues, users

logger = logging.getLogger("uvicorn.error")

app = FastAPI(
    title="CivicPulse API",
    description=(
        "Backend API for CivicPulse — a civic tech platform for infrastructure reporting, "
        "healthcare queue management, and GBV safety coordination."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Allow Flutter app and web clients to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # Tighten this to specific domains before production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event() -> None:
    try:
        get_supabase()
        logger.info("Supabase credentials loaded successfully.")
    except Exception as exc:
        logger.error("Failed to load Supabase credentials: %s", exc)
        raise

# Register routers
app.include_router(reports.router)
app.include_router(queues.router)
app.include_router(users.router)


@app.get("/", tags=["Health"])
async def root():
    """Health check — confirms the API is live."""
    return {
        "status": "ok",
        "service": "CivicPulse API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health():
    """Health probe for Render / Koyeb uptime checks and Supabase readiness."""
    try:
        get_supabase()
        return {
            "status": "healthy",
            "supabase": "ready",
        }
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "supabase": "missing or invalid credentials",
                "error": str(exc),
            },
        )
