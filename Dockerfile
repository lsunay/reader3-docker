# Build stage
FROM debian:12-slim AS builder
# Install required packages for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv git \
    && rm -rf /var/lib/apt/lists/*
# Install uv package manager
RUN pip3 install --break-system-packages uv
WORKDIR /build
# Clone the custom reader3 repo with Docker fixes
RUN git clone -b feature/docker-setup --single-branch \
    https://github.com/lsunay/reader3-docker.git .

# Runtime stage
FROM debian:12-slim
# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 curl \
    && rm -rf /var/lib/apt/lists/*
# Copy built files from builder stage
COPY --from=builder /build /app
COPY --from=builder /usr/local/bin/uv /usr/local/bin/uv
COPY --from=builder /usr/local/lib/python3.*/dist-packages/uv* /usr/local/lib/python3/dist-packages/
# Set working directory
WORKDIR /app
# Define volumes for books and data
VOLUME ["/app/books", "/app/data"]
# Create directories for books and data
RUN mkdir -p /app/books /app/data
# Create a non-root user for security
RUN useradd -m -u 1000 reader && chown -R reader:reader /app /app/books /app/data
# Copy and set permissions for the entrypoint script
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# Expose port 8123 for the web server
EXPOSE 8123
# Switch to the non-root user
USER reader
# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["uv", "run", "python3", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8123"]
