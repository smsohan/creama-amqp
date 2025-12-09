# Use the official Golang image as a build stage
FROM golang:1.24.8-alpine AS builder

# Set the current working directory inside the builder image
WORKDIR /app

# Copy go.mod and go.sum files and download dependencies
COPY go.mod ./
COPY go.sum ./
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the producer application
# CGO_ENABLED=0 is important for creating statically linked binaries that run without glibc
# -a ensures all packages are rebuilt, -installsuffix nocgo avoids issues with cgo-specific libraries
# -ldflags "-s -w" reduces the size of the binary by omitting debug information
RUN CGO_ENABLED=0 go build -o consumer ./main.go

# Use a minimal Alpine Linux image as the final stage
FROM alpine:latest

# Set the working directory
WORKDIR /app

# Copy the compiled producer binary from the builder stage
COPY --from=builder /app/consumer .

# Define the command to run the application
ENTRYPOINT ["./consumer"]
