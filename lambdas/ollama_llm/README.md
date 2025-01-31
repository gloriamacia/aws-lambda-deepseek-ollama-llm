# Push Docker Image to AWS ECR with Isengard Accounts

This guide outlines the steps to authenticate, build, tag, and push a Docker image to an AWS Elastic Container Registry (ECR) repository when using AWS Isengard accounts.

---

## Steps to Push Docker Image

### 1. Initialize Isengard Credentials

Ensure you are authenticated with AWS Isengard (internal accounts only):

```bash
mwinit -f
isengardcli assume
```

### 2. Authenticate Docker with AWS ECR

Run the following command to authenticate Docker to your AWS ECR repository:

```bash
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
```

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 203918878966.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Build the Docker Image

Build the Docker image using the Dockerfile:

```bash
# docker build -t ollama_llm:latest .
docker build --platform linux/amd64  --progress=plain -t ollama_llm:latest .
```

### 4. Tag the Docker Image

```bash
docker tag ollama_llm:latest <account_id>.dkr.ecr.<region>.amazonaws.com/ollama_llm:latest
```

```bash
docker tag ollama_llm:latest 203918878966.dkr.ecr.us-east-1.amazonaws.com/ollama_llm:latest
```

### 5. Push the Docker Image to ECR

```bash
docker push <account_id>.dkr.ecr.<region>.amazonaws.com/ollama_llm:latest
```

```bash
docker push 203918878966.dkr.ecr.us-east-1.amazonaws.com/ollama_llm:latest
```
