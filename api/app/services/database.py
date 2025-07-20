import asyncpg
from typing import List, Dict, Any, Optional
import asyncio
from ..config import get_settings

settings = get_settings()


class DatabaseService:
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None
    
    async def connect(self):
        """Create connection pool"""
        self.pool = await asyncpg.create_pool(
            settings.database_url,
            min_size=10,
            max_size=20,
            command_timeout=settings.query_timeout_seconds
        )
    
    async def disconnect(self):
        """Close connection pool"""
        if self.pool:
            await self.pool.close()
    
    async def execute_query(self, query: str, params: List[Any] = None) -> List[Dict[str, Any]]:
        """
        Execute a SELECT query and return results
        
        Args:
            query: SQL query to execute
            params: Query parameters for parameterized queries
            
        Returns:
            List of dictionaries containing query results
        """
        if not self.pool:
            raise RuntimeError("Database not connected")
        
        # Basic SQL injection prevention - only allow SELECT queries
        normalized_query = query.strip().upper()
        if not normalized_query.startswith("SELECT"):
            raise ValueError("Only SELECT queries are allowed")
        
        # Check for dangerous keywords
        dangerous_keywords = ["INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER", "EXEC", "EXECUTE"]
        for keyword in dangerous_keywords:
            if keyword in normalized_query:
                raise ValueError(f"Query contains forbidden keyword: {keyword}")
        
        async with self.pool.acquire() as connection:
            # Set statement timeout
            await connection.execute(f"SET statement_timeout = {settings.query_timeout_seconds * 1000}")
            
            try:
                # Execute query
                rows = await connection.fetch(query, *params if params else [])
                
                # Convert to list of dicts
                results = []
                for row in rows[:settings.max_query_results]:  # Limit results
                    results.append(dict(row))
                
                return results
            except asyncio.TimeoutError:
                raise ValueError("Query timeout exceeded")
            except Exception as e:
                raise ValueError(f"Query execution error: {str(e)}")
    
    async def test_connection(self) -> bool:
        """Test database connection"""
        try:
            async with self.pool.acquire() as connection:
                await connection.fetchval("SELECT 1")
                return True
        except Exception:
            return False


# Global database instance
db = DatabaseService()