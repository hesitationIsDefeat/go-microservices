FROM golang:1.24-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o brokerApp ./cmd/api

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/brokerApp .

EXPOSE 80

CMD ["./brokerApp"]