#!/bin/bash

# Variables
AWS_REGION="us-east-1"  # Change to your AWS region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_NAME="ollama-llm"
IMAGE_TAG=$(date +%s)  # Unique timestamp for tagging
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"
STACK_NAME="OllamaLambdaStack"

# Step 1: Authenticate with AWS ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Step 2: Ensure ECR Repository Exists
echo "Checking if ECR repository exists..."
aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "ECR repository not found. Creating..."
    aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}
else
    echo "ECR repository already exists."
fi

# Step 3: Build and Tag Docker Image
echo "Building Docker image..."
docker build --platform linux/amd64 --progress=plain -t ${ECR_REPO_NAME}:latest ./lambdas/ollama_llm

echo "Tagging image with timestamp ${IMAGE_TAG}..."
docker tag ${ECR_REPO_NAME}:latest ${IMAGE_URI}

# Step 4: Push Image to ECR
echo "Pushing Docker image to ECR..."
docker push ${IMAGE_URI}

# Step 5: Deploy CloudFormation Stack
# echo "Deploying CloudFormation stack..."
# aws cloudformation deploy \
#   --template-file template.yaml \
#   --stack-name ${STACK_NAME} \
#   --capabilities CAPABILITY_NAMED_IAM \
#   --parameter-overrides ImageUri=${IMAGE_URI}

# Step 6: Force AWS Lambda to Update the Image
# echo "Checking if Lambda function exists..."
# if aws lambda get-function --function-name ${STACK_NAME} >/dev/null 2>&1; then
#     echo "Lambda function exists. Updating the image..."
#     aws lambda update-function-code \
#       --function-name ${STACK_NAME} \
#       --image-uri ${IMAGE_URI}
# else
#     echo "Lambda function does not exist yet. Skipping update."
# fi

echo "Deployment completed successfully!"
