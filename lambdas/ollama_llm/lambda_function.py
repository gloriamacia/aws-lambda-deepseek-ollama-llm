import json
import requests

def lambda_handler(event, context):
    """
    AWS Lambda handler that takes a question from the 'event',
    sends it to the Ollama API at localhost:11434/api/chat,
    and returns the answer.
    """
    # 1. Parse the incoming event for user input.
    #    The structure depends on how you invoke Lambda (API Gateway, etc.).
    #    For example, if it's a JSON payload with a "user_message" field:
    body = event.get("body")
    if body:
        body_data = json.loads(body)
        user_message = body_data.get("user_message", "Hello from Lambda!")
    else:
        user_message = "Hello from Lambda!"

    # 2. Construct the request for Ollama.
    url = "http://localhost:11434/api/chat"
    payload = {
        "model": "deepseek-r1:8b",  
        "messages": [
            {
                "role": "user",
                "content": user_message
            }
        ],
        "stream": False
    }

    # 3. Send request to Ollama container on localhost.
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
    except requests.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

    # 4. Parse JSON response from Ollama
    try:
        data = response.json()
    except json.JSONDecodeError:
        data = {"response": response.text}

    # 5. Return a structured response for your API Gateway or caller
    return {
        "statusCode": 200,
        "body": json.dumps(data)
    }
