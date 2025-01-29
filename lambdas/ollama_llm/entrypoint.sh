#!/bin/sh
set -e

# Ensure the OLLAMA_MODELS environment variable is exported
export OLLAMA_MODELS=/tmp/.ollama/models
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"

# Start the Ollama server in the background, explicitly passing the model directory
echo "Starting Ollama server..."
OLLAMA_MODELS=/tmp/.ollama/models ollama serve &
OLLAMA_PID=$!

# Wait for the Ollama server to be ready
echo "Waiting for Ollama server to start..."
while ! curl -s http://localhost:11434/api/tags > /dev/null; do
    sleep 1
done
echo "Ollama server is ready."

# Ensure the required model is pulled before use
MODEL_NAME="llama3.2:1b"
echo "Checking if model '$MODEL_NAME' is available..."
if ! curl -s http://localhost:11434/api/tags | grep -q "$MODEL_NAME"; then
    echo "Model '$MODEL_NAME' not found. Pulling it now..."
    ollama pull "$MODEL_NAME"
else
    echo "Model '$MODEL_NAME' is already available."
fi

# Load the model into memory
echo "Loading the '$MODEL_NAME' model..."
curl -s -X POST http://localhost:11434/api/generate -H 'Content-Type: application/json' -d "{\"model\":\"$MODEL_NAME\"}" || true
echo "Model loaded."

# Start the AWS Lambda runtime
echo "Starting AWS Lambda runtime..."
exec python3 -m awslambdaric lambda_function.lambda_handler
