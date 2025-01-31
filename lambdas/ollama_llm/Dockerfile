FROM ollama/ollama:latest

# Set HOME and OLLAMA_MODELS to use /tmp for ephemeral storage
ENV HOME=/tmp
ENV OLLAMA_MODELS=/tmp/.ollama/models

# Install Python, runtime dependencies, and jq
RUN apt-get update && apt-get install -y curl python3 python3-pip jq

WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt
COPY lambda_function.py .

# Add an entrypoint script to start both the Ollama server and Lambda runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use the custom entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
