import openai
from typing import Dict, Any, Tuple
import sqlparse
import re
from ..config import get_settings
from ..utils.schema_context import SCHEMA_CONTEXT, EXAMPLE_QUERIES

settings = get_settings()

# Initialize OpenAI client
client = openai.OpenAI(api_key=settings.openai_api_key)


class QueryProcessor:
    @staticmethod
    async def natural_language_to_sql(user_query: str) -> Tuple[str, str]:
        """
        Convert natural language query to SQL using ChatGPT
        
        Args:
            user_query: Natural language question from user
            
        Returns:
            Tuple of (sql_query, explanation)
        """
        # Build the prompt with schema context
        system_prompt = f"""
You are a SQL expert for the NoM blockchain database. Convert natural language queries to PostgreSQL queries.

{SCHEMA_CONTEXT}

RULES:
1. Only generate SELECT statements
2. Use proper PostgreSQL syntax
3. Handle timestamps correctly (they are in Unix milliseconds)
4. Consider token decimals when displaying amounts
5. Use lowercase table names
6. Include appropriate JOINs when needed
7. Add ORDER BY and LIMIT when appropriate
8. Return ONLY the SQL query, no explanations or markdown
9. DO NOT include SQL comments (-- or /* */) in the query
"""
        
        # Add examples to help ChatGPT
        examples_text = "\n\nEXAMPLES:\n"
        for example in EXAMPLE_QUERIES[:3]:  # Use first 3 examples
            examples_text += f"Question: {example['question']}\nSQL: {example['sql']}\n\n"
        
        try:
            response = client.chat.completions.create(
                model=settings.openai_model,
                messages=[
                    {"role": "system", "content": system_prompt + examples_text},
                    {"role": "user", "content": f"Convert this to SQL: {user_query}"}
                ],
                temperature=0.1,  # Low temperature for consistent results
                max_tokens=1000
            )
            
            sql_query = response.choices[0].message.content.strip()
            
            # Clean up the query
            sql_query = QueryProcessor._clean_sql_query(sql_query)
            
            # Validate the query
            QueryProcessor._validate_sql_query(sql_query)
            
            # Generate explanation
            explanation = await QueryProcessor._generate_explanation(user_query, sql_query)
            
            return sql_query, explanation
            
        except Exception as e:
            raise ValueError(f"Failed to generate SQL query: {str(e)}")
    
    @staticmethod
    def _clean_sql_query(query: str) -> str:
        """Clean and format SQL query"""
        # Remove markdown code blocks if present
        query = re.sub(r'```sql\s*', '', query)
        query = re.sub(r'```\s*', '', query)
        
        # Format the query nicely
        query = sqlparse.format(
            query,
            reindent=True,
            keyword_case='upper',
            identifier_case='lower'
        )
        
        return query.strip()
    
    @staticmethod
    def _validate_sql_query(query: str) -> None:
        """Validate SQL query for safety"""
        # Parse the query
        parsed = sqlparse.parse(query)
        if not parsed:
            raise ValueError("Invalid SQL query")
        
        # Check if it's a SELECT statement
        statement = parsed[0]
        if statement.get_type() != 'SELECT':
            raise ValueError("Only SELECT queries are allowed")
        
        # Check for dangerous keywords
        dangerous_patterns = [
            r'\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b',
            r';.*\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b',  # Multiple statements
            r';\s*--',  # SQL comments after semicolon that might hide injections
            r'/\*.*\*/',  # Block comments
            r'--.*;\s*',  # Comments that might hide semicolons
        ]
        
        query_upper = query.upper()
        for pattern in dangerous_patterns:
            if re.search(pattern, query_upper):
                raise ValueError("Query contains forbidden operations")
    
    @staticmethod
    async def _generate_explanation(user_query: str, sql_query: str) -> str:
        """Generate a human-readable explanation of what the query does"""
        try:
            response = client.chat.completions.create(
                model=settings.openai_model,
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a helpful assistant that explains SQL queries in simple terms. Keep explanations brief and focused."
                    },
                    {
                        "role": "user", 
                        "content": f"""
User asked: "{user_query}"

Generated SQL:
{sql_query}

Provide a brief explanation of what this query does in 1-2 sentences.
"""
                    }
                ],
                temperature=0.3,
                max_tokens=200
            )
            
            return response.choices[0].message.content.strip()
        except:
            return "This query retrieves data based on your request."