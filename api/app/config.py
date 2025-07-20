from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://postgres:nomIndexerPass123@postgres:5432/nom_indexer"
    
    # OpenAI
    openai_api_key: str
    openai_model: str = "gpt-4-turbo-preview"
    
    # API Settings
    api_title: str = "NoM Natural Language Query API"
    api_version: str = "1.0.0"
    
    # Security
    query_timeout_seconds: int = 30
    max_query_results: int = 1000
    
    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:3001", "http://frontend:3000"]
    
    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()