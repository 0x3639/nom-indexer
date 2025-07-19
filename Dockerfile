# Build stage
FROM dart:3.0 AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml .

# Install dependencies
RUN dart pub get

# Copy source code
COPY bin/ ./bin/

# Compile the application
RUN dart compile exe bin/main.dart -o nom-indexer

# Runtime stage
FROM debian:bullseye-slim

# Install required runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 indexer

# Set working directory
WORKDIR /app

# Copy the compiled binary from build stage
COPY --from=build /app/nom-indexer .

# Change ownership
RUN chown -R indexer:indexer /app

# Switch to non-root user
USER indexer

# Run the indexer
CMD ["./nom-indexer"]