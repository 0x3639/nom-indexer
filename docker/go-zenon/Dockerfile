# Build stage
FROM golang:1.20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make gcc musl-dev linux-headers

# Clone go-zenon repository
WORKDIR /build
RUN git clone https://github.com/zenon-network/go-zenon.git .

# Build znnd
RUN make znnd

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Create zenon user
RUN adduser -D -u 1000 zenon

# Copy binary from builder
COPY --from=builder /build/build/znnd /usr/local/bin/znnd

# Create data directory
RUN mkdir -p /zenon-data && chown -R zenon:zenon /zenon-data

# Switch to zenon user
USER zenon

# Set working directory
WORKDIR /zenon-data

# Expose ports
# 35997: P2P port
# 35998: WebSocket RPC port  
EXPOSE 35997 35998

# Run znnd
ENTRYPOINT ["znnd"]
CMD ["--data", "/zenon-data"]