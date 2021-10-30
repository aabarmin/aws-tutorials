#!/bin/bash -xe

# Checking if ghost image is pulled locally
LOCAL_COUNT=$(docker image ls ghost | wc -l)
if [ $LOCAL_COUNT == "1" ]; then
    docker pull ghost:latest
fi

# Checking if ghost image is available in the ghost_repository
REPOSITORY_NAME="ghost_repository"
ECR_COUNT=$(aws ecr list-images --repository-name $REPOSITORY_NAME --query 'imageIds[*].imageDigest' --output text | wc -l)
if [ $ECR_COUNT == "0" ]; then
    # Getting necessary parameters
    ECR_URI=$(aws ecr describe-repositories --output text --query "repositories[?repositoryName=='$REPOSITORY_NAME'].repositoryUri")
    ECR_NAME=$(awk '{print substr($0, 1, index($0, "/") - 1)}' <<< $ECR_URI)
    
    # Authenticating local Docker in ECR
    aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_NAME
    
    # Tagging ghost image in the local repository 
    docker tag ghost:latest "$ECR_URI:latest"

    # Pushing
    docker push "$ECR_URI:latest"
fi