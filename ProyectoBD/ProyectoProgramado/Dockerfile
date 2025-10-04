# Build stage
FROM golang:latest  AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o app main.go

# Run stage
FROM golang:latest 
WORKDIR /app
COPY --from=builder /app/app .
COPY app.env .
EXPOSE 8080
CMD ["./app"]