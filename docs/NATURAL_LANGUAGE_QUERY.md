# Natural Language Query Interface

This feature adds a natural language query interface to the NoM indexer, allowing users to ask questions about blockchain data in plain English and receive SQL query results.

## Architecture

The system consists of three main components:

1. **Python FastAPI Backend** (`/api`)
   - Converts natural language to SQL using ChatGPT
   - Validates and executes queries safely
   - Returns formatted results

2. **Nuxt.js Frontend** (`/frontend`)
   - Simple chat interface
   - Displays SQL queries and results
   - Provides example questions

3. **PostgreSQL Database**
   - Contains indexed blockchain data
   - Read-only access for queries

## Setup

1. **Configure OpenAI API Key**
   
   Copy `.env.example` to `.env` and add your OpenAI API key:
   ```bash
   OPENAI_API_KEY=your_api_key_here
   ```

2. **Start the Services**
   
   ```bash
   docker-compose up -d
   ```

   This will start:
   - PostgreSQL database (port 5432)
   - NoM indexer
   - API backend (port 8000)
   - Frontend UI (port 3001)

3. **Access the Interface**
   
   Open http://localhost:3001 in your browser

## Usage

### Example Questions

- "Show me all transactions over 1000 ZNN in the last 10 days"
- "What are the top 10 accounts by ZNN balance?"
- "List all active pillars with their voting activity"
- "Show me the total QSR burned this month"
- "Which accounts received the most staking rewards?"

### API Endpoints

- `POST /api/v1/query` - Process natural language query
- `GET /api/v1/schema` - Get database schema information
- `GET /api/v1/examples` - Get example queries

### Security Features

- Read-only database access
- SQL injection prevention
- Query validation
- Rate limiting
- Query timeout (30 seconds)
- Maximum 1000 results per query

## Development

### Backend Development

```bash
cd api
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

## Configuration

### Environment Variables

- `OPENAI_API_KEY` - Required: Your OpenAI API key
- `OPENAI_MODEL` - Optional: ChatGPT model (default: gpt-4-turbo-preview)
- `POSTGRES_PASSWORD` - Database password
- `NODE_URL_WS` - Zenon node WebSocket URL

### Customization

To add more context for better query generation:

1. Edit `/api/app/utils/schema_context.py`
2. Add more example queries
3. Update table descriptions

## Troubleshooting

### Common Issues

1. **"Failed to generate SQL query"**
   - Check your OpenAI API key is valid
   - Ensure you have API credits

2. **"Query timeout exceeded"**
   - The query is too complex
   - Try a simpler question

3. **"Database disconnected"**
   - Check PostgreSQL is running
   - Verify database credentials

### Logs

View logs for debugging:

```bash
# API logs
docker logs nom-query-api

# Frontend logs
docker logs nom-query-frontend
```