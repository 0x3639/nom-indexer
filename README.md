# NoM Indexer
An indexer for Network of Momentum that fetches information from a Zenon node and stores it in a PostgreSQL database in such a way to provide efficient access to on-chain information that is not readily available via the node RPC API.

Please note that the indexer is still WIP.

## Quick Start with Docker

The easiest way to run the NoM Indexer is using Docker Compose:

1. Copy the environment file and configure it:
   ```bash
   cp .env.example .env
   # Edit .env to set your Zenon node WebSocket URL and database password
   ```

2. Start the services:
   ```bash
   docker-compose up -d
   ```

This will:
- Start a PostgreSQL 14 database with optimized settings for indexing
- Build and run the NoM Indexer connected to your Zenon node
- Automatically restart services if they fail

To view logs:
```bash
docker-compose logs -f
```

To stop the services:
```bash
docker-compose down
```

To stop and remove all data:
```bash
docker-compose down -v
```

### Running with a Local Zenon Node

The indexer can optionally run with a local go-zenon node included in the Docker Compose setup:

1. Start the go-zenon node (it will begin syncing from genesis):
   ```bash
   docker-compose up -d go-zenon
   ```

2. Monitor the node's sync progress:
   ```bash
   docker-compose logs -f go-zenon
   ```

3. Check if the node is fully synced:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","id":1,"method":"stats.syncInfo","params":[]}' \
     http://localhost:35998
   ```
   
   The node is fully synced when the response shows `"state": 2` and `currentHeight` equals `targetHeight`.

4. Once synced, update your `.env` file to use the local node:
   ```bash
   # Change from external node:
   # NODE_URL_WS=ws://your-external-node:35998
   
   # To local node:
   NODE_URL_WS=ws://go-zenon:35998
   ```

5. Restart the indexer to use the local node:
   ```bash
   docker-compose restart nom-indexer
   ```

The go-zenon node data persists in a Docker volume, so you won't need to re-sync if you restart the container.

## Building from source
The Dart SDK is required to build the server from source (https://dart.dev/get-dart).
Use the Dart SDK to install the dependencies and compile the program by running the following commands:
```
dart pub get
dart compile exe bin/main.dart
```

## Manual Setup and Configuration

### PostgreSQL Setup
Install PostgreSQL 14 and create a database for the indexer to use. Set the setting ```synchronous_commit = off``` in ```postgresql.conf``` to improve write speed on the initial indexing.

### Configuration Options

The indexer can be configured using either environment variables or a config.yaml file.

#### Using Environment Variables (Recommended for Docker)
Set the following environment variables:
- `NODE_URL_WS`: WebSocket URL of your Zenon node (e.g., ws://127.0.0.1:35998)
- `DATABASE_ADDRESS`: PostgreSQL host address
- `DATABASE_PORT`: PostgreSQL port (default: 5432)
- `DATABASE_NAME`: Database name
- `DATABASE_USERNAME`: Database username
- `DATABASE_PASSWORD`: Database password

#### Using config.yaml
Make a copy of the example.config.yaml file and name the copy "config.yaml". Set your desired configuration in the file.

## Running the indexer
```
dart run bin/main
```

Initially it will take some time for the indexer to index the network up to the current height.
