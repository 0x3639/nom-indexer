from fastapi import FastAPI, HTTPException
from contextlib import asynccontextmanager
from .config import get_settings
from .routers import query
from .services.database import db
from .middleware import cors_middleware

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await db.connect()
    yield
    # Shutdown
    await db.disconnect()


# Create FastAPI app
app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    lifespan=lifespan
)

# Add custom CORS middleware
app.middleware("http")(cors_middleware)

# Include routers
app.include_router(query.router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"message": "NoM Natural Language Query API", "version": settings.api_version}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    db_connected = await db.test_connection()
    return {
        "status": "healthy" if db_connected else "unhealthy",
        "database": "connected" if db_connected else "disconnected"
    }