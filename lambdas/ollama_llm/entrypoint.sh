#!/bin/sh
set -e

# Ensure the OLLAMA_MODELS environment variable is exported
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"

# Start the Ollama server in the background
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
MODEL_NAME="deepseek-r1:8b"

pull_model() {
    echo "Pulling model '$MODEL_NAME' again..."
    ollama pull "$MODEL_NAME"
}

# Function to check if the model is loaded
is_model_loaded() {
    response=$(curl -s -X POST http://localhost:11434/api/generate -H 'Content-Type: application/json' -d "{\"model\":\"$MODEL_NAME\", \"stream\": false}")

    # Debugging: Print response
    echo "Raw API Response: '$response'"

    # If the response is empty, pull the model again
    if [ -z "$response" ]; then
        echo "Error: No response from Ollama API! Retrying model pull..."
        pull_model
        return 1
    fi

    # Extract "done" value safely
    done_status=$(echo "$response" | jq -r '.done // empty' 2>/dev/null)

    # Handle parsing failure
    if [ -z "$done_status" ]; then
        echo "Error: Failed to parse JSON response! Retrying model pull..."
        pull_model
        return 1
    fi

    if [ "$done_status" = "true" ]; then
        return 0  # Model is loaded
    else
        return 1  # Model is still loading
    fi
}

# Load the model into memory
echo "Loading the '$MODEL_NAME' model..."

# Loop until the model is successfully loaded
until is_model_loaded; do
    echo "Waiting for model to load..."
    sleep 2
done

echo "Model loaded."

# Check storage use
echo "Checking ephemeral storage usage..."
df -h /tmp
du -sh /tmp/.ollama/models

# Start the AWS Lambda runtime
echo "Starting AWS Lambda runtime..."
exec python3 -m awslambdaric lambda_function.lambda_handler
