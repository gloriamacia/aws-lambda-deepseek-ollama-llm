# **🚀 Deploying Large Language Models (LLMs) in AWS Lambda with Ollama**

![alt text](./image.png)

This project enables **serverless LLM inference** using **AWS Lambda** with **Ollama** as Infrastracture as Code (IaC). It is designed to work **within Lambda’s limits** (max **10GB ephemeral storage** and **10GB memory**). Deploy Cutting-Edge LLMs like DeepSeek R1, Falcon, Mistral and LLaMA models... among others at the lowest cost on AWS Lambda with Ollama.

**To deploy your function, simply run**:

```bash
bash deploy.sh
```

This script automates the **entire setup**, including **image building, ECR upload, and Lambda deployment**.

---

## How does it work? 

**Distilled models** are smaller, optimized versions of LLMs that retain most capabilities while reducing computational overhead, making them ideal for serverless execution. **Ollama** enables efficient deployment of large language models (LLMs) locally. As a challenge, we are pushing the limits by deploying LLMs within AWS Lambda's 10GB ephemeral storage and memory constraints, optimizing for performance while maintaining flexibility.

For **production-grade applications**, AWS provides alternatives such as:  
- **DeepSeek-R1 and Llama distilled variants on Amazon SageMaker AI** for scalable inference.  
- **Amazon Bedrock (via Custom Model Import)** for managed model hosting.

## **1️⃣ AWS Lambda Resource Limits**

AWS Lambda has strict resource constraints. This setup is optimized for:

- **Memory**: **Up to 10GB** (`--memory-size 10240`).
- **Ephemeral Storage**: **Up to 10GB** (`--ephemeral-storage '{"Size": 10240}'`).
- **Timeout**: Currently set to **5 minutes (300s)**

These limits allow **running models within 10GB** (e.g., `deepseek-r1:8b`), but **larger models won’t fit** within this setup.

---

## **2️⃣ How AWS Lambda Runs Ollama**

### **How the Model is Handled in Ephemeral Storage (`/tmp`)**

- AWS Lambda **provides a temporary 10GB storage** at `/tmp`.
- The model is **downloaded only during the first run** (cold start) and stored in `/tmp/.ollama/models`.
- On **subsequent executions (warm start)**, the model **remains available in memory**, preventing repeated downloads.

This ensures **faster inference** without extra startup time **as long as the function stays warm**.

---

## **3️⃣ `awslambdaric`: Making Lambda Work with Ollama**

### **Why We Need `awslambdaric`**

AWS Lambda containers **don’t automatically run Python scripts** in the expected function format (`lambda_handler`). Instead, we use `awslambdaric` (**AWS Lambda Runtime Interface Client**) to:

- **Start an HTTP server inside Lambda.**
- **Bridge requests e.g from AWS API Gateway to our Python function.**
- **Keep the Lambda process alive while running Ollama.**

### **How It Works**

1. The **entrypoint script (`entrypoint.sh`)** starts:
   - The **Ollama LLM server (`ollama serve &`)** in the background.
   - The **Lambda runtime (`awslambdaric lambda_function.lambda_handler`)** in the foreground.
2. The runtime **waits for requests** and forwards them to the local Ollama API (`localhost:11434/api/chat`).
3. The **Lambda function (`lambda_function.py`)** handles user queries and retrieves responses from Ollama.

This setup ensures **AWS Lambda correctly processes requests** while keeping Ollama active.

---

## **4️⃣ API Usage: Running Any LLM Model**

### **Example Request Payload**

The Lambda function accepts a **JSON payload** with a **custom message and model selection**:

```json
{
  "body": "{\"user_message\": \"Why is the sky blue?\", \"model_name\": \"deepseek-r1:8b\"}"
}
```

- The **default model** is `deepseek-r1:8b`, but **any model in Ollama’s library** can be used as long as it fits in the memory of lambda.
- If the model is **not yet downloaded**, it will be **pulled at runtime**.
- **Larger models may require increasing the Lambda timeout** to **prevent failures while downloading**.

### **Example Response**

```json
{
  "statusCode": 200,
  "body": "{\"model\": \"deepseek-r1:8b\", \"created_at\": \"2025-01-31T13:26:15.151417238Z\", \"message\": {\"role\": \"assistant\", \"content\": \"<think>\\nOkay, so I'm trying to figure out why the sky is blue. I remember learning about this in school a while ago, but I don't recall all the details. Let me think through it step by step.\\n\\nFirst, I know that when you look up on a clear day, the sky appears blue. But why? I mean, the sky isn't actually blue; if you could see into space from Earth without any atmosphere, I suppose it would be black because there's no light except for stars and stuff, which are far away and not very bright.\\n\\nSo maybe the sky is blue because of something our atmosphere does to the light. I think it has something to do with Rayleigh scattering. I remember hearing that term before. Rayleigh scattering is when sunlight scatters off molecules or particles in the air, causing the light to change direction and wavelength.\\n\\nWait, how does that work? So, when sunlight enters the Earth's atmosphere, some of its photons scatter in all directions due to interactions with molecules. Since blue light has a shorter wavelength than red or orange light, it is scattered more by these small particles. So blue light scatters more, making the sky look blue from our perspective here on Earth.\\n\\nBut I'm not entirely sure why blue scatters more. Let me think about the electromagnetic spectrum. Blue has a higher frequency and a shorter wavelength compared to colors like red or orange. Maybe it's because of this higher energy that blue light scatters more effectively when it interacts with air molecules.\\n\\nAlso, the scattering isn't random; there's something called the Rayleigh law which describes how the intensity of scattered light depends on the wavelength and the properties of the medium, in this case, the Earth's atmosphere. So, as sunlight travels through our atmosphere, blue photons are scattered in all directions, including towards the sky, making the sky appear blue to us.\\n\\nWait, but if that's the case, then from above the atmosphere, like on the moon or somewhere else without an atmosphere, we would see black because there's no scattering. That makes sense because when you're in space, you can see the true colors of things without atmospheric distortion.\\n\\nSo putting it all together, the sky is blue because our atmosphere scatters sunlight more effectively at blue wavelengths due to Rayleigh scattering. This scattering causes light from the sun to redirect its direction and color, creating the blue appearance we see when looking up on a clear day.\\n\\nI think that covers it, but I might be missing some details or mixing things up. Let me just recap to ensure I have the main points: shorter wavelengths (like blue) scatter more in the atmosphere, Rayleigh scattering explains this effect, and without an atmosphere, the sky wouldn't be blue.\\n</think>\\n\\nThe sky appears blue due to a phenomenon known as Rayleigh scattering. This occurs because sunlight, which is composed of various colors with different wavelengths, interacts with molecules in Earth's atmosphere. The shorter wavelength of blue light (compared to longer wavelengths like red or orange) causes it to scatter more effectively off these molecules. According to the Rayleigh law, the intensity of scattered light depends on both its wavelength and the properties of the medium (in this case, our atmosphere). As sunlight travels through our atmosphere, blue photons are scattered in all directions, including upwards, which we perceive as the sky's color.\\n\\nThis scattering effect is absent without an atmosphere, such as on the moon or in space, where the sky would appear black because there is no atmospheric distortion to scatter the light. Therefore, the blue color of the sky is a result of this Rayleigh scattering process, where blue light scatters more efficiently than other wavelengths.\"}, \"done_reason\": \"stop\", \"done\": true, \"total_duration\": 130048726617, \"load_duration\": 28849936, \"prompt_eval_count\": 9, \"prompt_eval_duration\": 877000000, \"eval_count\": 744, \"eval_duration\": 129138000000}"
}
```

---

## **5️⃣ Deploying with Infrastructure as Code (`deploy.sh`)**

### **Why Use IaC?**

Infrastructure as Code (IaC) **automates AWS resource creation**, ensuring:
✅ **Consistency** – No manual setup errors.  
✅ **Repeatability** – Deploy the same stack anytime.  
✅ **Version Control** – Track changes via Git.

### **What `deploy.sh` Does (Step-by-Step)**

1. **Authenticates** with AWS Elastic Container Registry (ECR).
2. **Checks if the ECR repository exists** (creates it if needed).
3. **Builds the Docker image** with Ollama and Lambda runtime.
4. **Tags the image with a timestamp** for version control.
5. **Pushes the image** to AWS ECR.
6. **Deploys the Lambda function using AWS CloudFormation.**
7. **Forces AWS Lambda to update the image** (to ensure new deployments take effect).
### **Running the Deployment**

---

## **6️⃣ Next Steps**  

### **1️. Try Different LLM Models**  

### **2️. Enable AWS Lambda Response Streaming**  
- **Stream responses** instead of waiting for full output ([AWS Streaming](https://aws.amazon.com/blogs/compute/introducing-aws-lambda-response-streaming/)).  

### **3️. Add Memory & Conversation History**  
- **Use DynamoDB** to store chat history with a **Session ID**.  
- Modify `lambda_function.py` to **retrieve & update** session context.  

### **4️. Contribute & Improve**  
1. **Fork the Repository** – Clone and start developing.  
2. **Implement Features** – Streaming, session memory, efficiency optimizations.  
3. **Submit a Pull Request** – Ensure code is **tested & documented**.  
4. **Star the Repo ⭐** – Help others discover this project!  

### **Disclaimer**  

This project is a **personal experiment** to explore the feasibility of running **LLMs on AWS Lambda** using Ollama. It is **not an official AWS architecture recommendation** or an endorsed best practice. While this approach demonstrates a **creative workaround for deploying models within Lambda's constraints**, production-grade applications should consider **AWS-managed solutions** like **Amazon SageMaker** or **Amazon Bedrock** for scalability, reliability, and support.

If you found this toy project useful feel free to connect with me on LinkedIn: https://www.linkedin.com/in/gloriamacia/
