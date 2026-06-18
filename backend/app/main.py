from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import reports, queues

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

# Register routers
app.include_router(reports.router)
app.include_router(queues.router)


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
    """Lightweight health probe for Render / Koyeb uptime checks."""
    return {"status": "healthy"}
