from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from ..services.database import db
from ..services.query_processor import QueryProcessor

router = APIRouter(tags=["query"])


class QueryRequest(BaseModel):
    question: str = Field(..., description="Natural language question about the blockchain data")
    include_sql: bool = Field(default=True, description="Include generated SQL in response")


class QueryResponse(BaseModel):
    question: str
    sql_query: Optional[str] = None
    explanation: str
    results: List[Dict[str, Any]]
    row_count: int
    error: Optional[str] = None


@router.post("/query", response_model=QueryResponse)
async def process_query(request: QueryRequest):
    """
    Process a natural language query and return results from the database
    """
    try:
        # Convert natural language to SQL
        sql_query, explanation = await QueryProcessor.natural_language_to_sql(request.question)
        
        # Execute the query
        results = await db.execute_query(sql_query)
        
        # Prepare response
        response = QueryResponse(
            question=request.question,
            sql_query=sql_query if request.include_sql else None,
            explanation=explanation,
            results=results,
            row_count=len(results)
        )
        
        return response
        
    except ValueError as e:
        # Return error response for query issues
        return QueryResponse(
            question=request.question,
            sql_query=None,
            explanation="Failed to process query",
            results=[],
            row_count=0,
            error=str(e)
        )
    except Exception as e:
        # Log the error and return generic message
        print(f"Query processing error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/schema")
async def get_schema_info():
    """
    Get information about the database schema
    """
    return {
        "tables": [
            {"name": "momentums", "description": "Blockchain blocks"},
            {"name": "accountblocks", "description": "All transactions"},
            {"name": "accounts", "description": "Account information"},
            {"name": "balances", "description": "Token balances"},
            {"name": "tokens", "description": "Token information"},
            {"name": "pillars", "description": "Network validators"},
            {"name": "sentinels", "description": "Network sentinels"},
            {"name": "stakes", "description": "ZNN staking entries"},
            {"name": "projects", "description": "Accelerator-Z projects"},
            {"name": "projectphases", "description": "Project phases"},
            {"name": "votes", "description": "Governance votes"},
            {"name": "fusions", "description": "Plasma fusions"},
            {"name": "cumulativerewards", "description": "Reward totals"},
            {"name": "rewardtransactions", "description": "Individual rewards"}
        ],
        "common_tokens": [
            {"symbol": "ZNN", "standard": "zts1znnxxxxxxxxxxxxx9z4ulx", "decimals": 8},
            {"symbol": "QSR", "standard": "zts1qsrxxxxxxxxxxxxxmrhjll", "decimals": 8}
        ]
    }


@router.get("/examples")
async def get_example_queries():
    """
    Get example queries to help users understand what's possible
    """
    return {
        "examples": [
            "Show me all transactions over 1000 ZNN in the last 10 days",
            "What are the top 10 accounts by ZNN balance?",
            "List all active pillars with their voting activity",
            "Show me the total QSR burned this month",
            "Which accounts received the most staking rewards?",
            "What is the current total supply of ZNN?",
            "Show me all Accelerator-Z projects created in the last 30 days",
            "Which pillar has produced the most blocks?",
            "List accounts that have delegated to the top 5 pillars",
            "Show me plasma fusions expiring in the next 7 days"
        ]
    }