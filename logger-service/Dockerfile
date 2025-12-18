# Stage 1: Builder
FROM golang:1.24-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o loggerApp ./cmd/web

# Stage 2: Runner
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/loggerApp .

# Expose all ports (Web, RPC, gRPC)
EXPOSE 80
EXPOSE 5001
EXPOSE 50001

CMD ["./loggerApp"]