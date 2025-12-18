# Stage 1: The Builder (Compiles the code)
FROM golang:1.24-alpine as builder

WORKDIR /app

# Copy dependency files first (for better caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the binary
# ADJUSTMENT: If your main.go is in the root, use "." instead of "./cmd/api"
RUN CGO_ENABLED=0 GOOS=linux go build -o brokerApp ./cmd/api

# Stage 2: The Runner (Tiny image)
FROM alpine:latest

WORKDIR /app

# Copy the binary from the builder
COPY --from=builder /app/brokerApp .

# Expose the port
EXPOSE 80

# Run the binary
CMD ["./brokerApp"]