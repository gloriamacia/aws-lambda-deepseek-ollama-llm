import json
import requests
from typing import Dict, Callable

# OpenWeatherMap API Key
API_KEY = "<YOUR KEY HERE>"

# OpenWeatherMap Endpoints
GEO_URL = "http://api.openweathermap.org/geo/1.0/direct"
WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"

def get_current_weather(location: str) -> str:
    """
    Fetches real-time weather data using OpenWeatherMap's Geocoding & Weather APIs.
    """
    print(f"[get_current_weather] Fetching weather for: {location}")

    # 1️⃣ First Call: Geocode the location to get latitude/longitude
    geo_params = {"q": location, "limit": 1, "appid": API_KEY}
    
    try:
        geo_response = requests.get(GEO_URL, params=geo_params)
        geo_response.raise_for_status()
        geo_data = geo_response.json()

        if not geo_data:
            print(f"[get_current_weather] ERROR: Location '{location}' not found.")
            return f"Could not find weather data for '{location}'."

        lat = geo_data[0]["lat"]
        lon = geo_data[0]["lon"]
        city_name = geo_data[0]["name"]
        country = geo_data[0]["country"]

        print(f"[get_current_weather] Geocoding Result: {city_name}, {country} (Lat: {lat}, Lon: {lon})")

    except requests.RequestException as e:
        print(f"[get_current_weather] ERROR: {str(e)}")
        return f"Error fetching geolocation for '{location}'."

    # 2️⃣ Second Call: Get Weather using lat/lon
    weather_params = {"lat": lat, "lon": lon, "appid": API_KEY, "units": "metric"}
    
    try:
        weather_response = requests.get(WEATHER_URL, params=weather_params)
        weather_response.raise_for_status()
        weather_data = weather_response.json()

        temperature = weather_data["main"]["temp"]
        description = weather_data["weather"][0]["description"].capitalize()

        result = f"The current temperature in {city_name}, {country} is {temperature}°C with {description}."
        print(f"[get_current_weather] Result: {result}")

        return result

    except requests.RequestException as e:
        print(f"[get_current_weather] ERROR: {str(e)}")
        return f"Could not retrieve weather for '{location}'."

# Map function names to actual Python callables
available_functions: Dict[str, Callable] = {
    'get_current_weather': get_current_weather
}

def lambda_handler(event, context):
    """
    AWS Lambda handler that takes a user question and model name from the event,
    sends it to the Ollama (or Deepseek) API, and returns the answer.
    """
    # Default values
    default_message = "What is the meaning of life?"
    default_model = "MFDoom/deepseek-r1-tool-calling:1.5b"

    # Parse the event body
    body = event.get("body")
    if body:
        try:
            body_data = json.loads(body)
            user_message = body_data.get("user_message", default_message)
            model_name = body_data.get("model_name", default_model)
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Invalid JSON format in request body."})
            }
    else:
        user_message = default_message
        model_name = default_model

    # Define the "tool" for function calling
    get_current_weather_tool = {
        "type": "function",
        "function": {
            "name": "get_current_weather",
            "description": "Get the current weather for a location",
            "parameters": {
                "type": "object",
                "required": ["location"],
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "The location to get the weather for, e.g. Paris"
                    }
                }
            }
        }
    }

    # Construct request for Deepseek API
    url = "http://localhost:11434/api/chat"
    payload = {
        "model": model_name,
        "messages": [
            {
                "role": "user",
                "content": user_message
            }
        ],
        "stream": False,
        "tools": [get_current_weather_tool]  # Add the weather function tool
    }

    # Send request to the container
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
    except requests.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

    # Parse JSON response from the API
    try:
        data = response.json()
    except json.JSONDecodeError:
        data = {"response": response.text}

    # Check if the model decided to call our function
    function_results = []
    message = data.get("message", {})
    tool_calls = message.get("tool_calls", [])

    if tool_calls:
        for tool_call in tool_calls:
            fn_info = tool_call.get("function", {})
            fn_name = fn_info.get("name")

            # Don't parse a dict!
            args = fn_info.get("arguments", {})

            if fn_name in available_functions:
                # Call the actual Python function
                fn_result = available_functions[fn_name](**args)
                function_results.append({
                    "name": fn_name,
                    "arguments": args,
                    "result": fn_result
                })

    # Attach function results to response
    if function_results:
        data["function_results"] = function_results

    # Return structured response
    return {
        "statusCode": 200,
        "body": json.dumps(data)
    }
