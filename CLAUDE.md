# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Dart-based blockchain indexer for the Network of Momentum (NoM/Zenon). It connects to a Zenon node via WebSocket, fetches blockchain data, and stores it in PostgreSQL for efficient querying.

## Development Commands

```bash
# Install dependencies
dart pub get

# Run the indexer in development
dart run bin/main

# Compile to executable
dart compile exe bin/main.dart -o nom-indexer

# Run compiled executable
./nom-indexer
```

## Architecture

### Core Components

1. **NomIndexer** (`bin/indexer/nom_indexer.dart`): Main indexing engine
   - Syncs blockchain data every 10 seconds via `_sync()` method
   - Updates pillar voting and token holders every 10 minutes via `_updateVotingActivity()`
   - Uses WebSocket polling (not subscriptions) due to reliability issues
   - Handles batch database operations for efficiency

2. **DatabaseService** (`bin/services/database_service.dart`): Database layer singleton
   - Manages PostgreSQL connection pool
   - Defines schemas for 13+ entity tables
   - Provides typed methods for each entity (e.g., `insertMomentum`, `insertAccount`)
   - Uses prepared statements and batch operations

3. **Config** (`bin/config/config.dart`): Configuration management
   - Loads from `config.yaml` (copy from `example.config.yaml`)
   - Static accessors: `Config.nodeWsUrl`, `Config.dbConfig`

### Data Flow

1. IndexerStartup → Config loads → DatabaseService connects → Tables created
2. NomIndexer polls node → Decodes data → Batch inserts to PostgreSQL
3. Special handling for embedded contracts (pillars, sentinels, accelerator, etc.)

### Key Database Tables

- **Core**: momentums, accounts, account_blocks, balances
- **Embedded Contracts**: pillars, sentinels, stakes, projects, tokens
- **Analytics**: cumulative_rewards, reward_transactions, votes

### Important Implementation Details

- Uses `BigInt` for all numeric blockchain values to prevent overflow
- Momentum sync starts from height stored in DB or genesis
- Transaction decoding includes embedded contract function identification
- Token holder counts and voting activity calculated periodically
- All timestamps stored as Unix milliseconds

## Configuration

Create `config.yaml` from `example.config.yaml`:
```yaml
node:
  ws_url: "ws://your-node:35998"  # WebSocket endpoint

database:
  host: "localhost"
  port: 5432
  name: "nom_indexer"
  user: "your_user"
  pass: "your_pass"
```

## Common Tasks

### Adding New Entity Types

1. Add table schema to `DatabaseService._createTables()`
2. Create insert method in `DatabaseService`
3. Add decoding logic in `NomIndexer._sync()`
4. Handle in appropriate embedded contract decoder

### Debugging Sync Issues

- Check `_lastSyncedHeight` in momentum sync loop
- Enable PostgreSQL query logging
- Verify node WebSocket connection is stable
- Check for BigInt serialization issues in database operations

### Database Maintenance

```sql
-- Check sync status
SELECT MAX(height) FROM momentums;

-- View recent account activity
SELECT * FROM account_blocks ORDER BY height DESC LIMIT 10;

-- Check token holder counts
SELECT token_standard, holder_count FROM tokens;
```

## Project Status

This is a WIP (Work In Progress) indexer. Core functionality is implemented but testing infrastructure is not yet in place. The indexer is functional for syncing and querying blockchain data.