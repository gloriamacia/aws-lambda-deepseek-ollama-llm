# ---- STAGE 1: Pull and finalize the model ----
FROM ollama/ollama:latest AS builder

USER root

# Set HOME and OLLAMA_MODELS to use /tmp for ephemeral storage
ENV HOME=/tmp
ENV OLLAMA_MODELS=/tmp/.ollama/models

# Install curl for API testing
RUN apt-get update && apt-get install -y curl

# Pull the model and ensure it's finalized
RUN bash -exc "\
    echo 'Starting Ollama server in builder stage...' ; \
    OLLAMA_MODELS=/tmp/.ollama/models ollama serve & \
    sleep 5 ; \
    echo 'Pulling the llama3.2:1b model...' ; \
    if ! ollama pull llama3.2:1b; then \
    echo 'Error: Failed to pull llama3.2:1b' && exit 1; \
    fi ; \
    echo 'Ensuring the model is loaded...' ; \
    curl -s -X POST http://localhost:11434/api/chat -H 'Content-Type: application/json' -d '{\"model\":\"llama3.2:1b\",\"messages\":[]}' || true ; \
    sleep 2 ; \
    echo 'Builder stage complete: Listing models:' ; \
    ls -lh /tmp/.ollama/models \
    "

# ---- STAGE 2: Final image with the baked-in model ----
FROM ollama/ollama:latest

USER root

# Set HOME and OLLAMA_MODELS to use /tmp for ephemeral storage
ENV HOME=/tmp
ENV OLLAMA_MODELS=/tmp/.ollama/models

# Copy model files from the builder stage to the Lambda-compatible location
COPY --from=builder /tmp/.ollama /tmp/.ollama
# Ensure proper permissions for the model directory
RUN chmod -R 755 /tmp/.ollama

# Install Python and runtime dependencies
RUN apt-get update && apt-get install -y curl python3 python3-pip
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY lambda_function.py .

# Add an entrypoint script to start both the Ollama server and Lambda runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the custom entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
