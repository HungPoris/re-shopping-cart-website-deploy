#!/bin/bash

# RE Shopping Cart - EC2 Deployment Script
# This script should be placed on the EC2 instance

set -e

# Configuration
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-your-dockerhub-username}"
IMAGE_NAME="re-shopping-cart"
CONTAINER_NAME="re-shopping-cart"
PORT="8080"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}RE Shopping Cart Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check required environment variables
if [ -z "$DB_URL" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Required environment variables are not set${NC}"
    echo "Please set DB_URL, DB_USERNAME, and DB_PASSWORD"
    exit 1
fi

# Pull latest image
echo -e "${YELLOW}Pulling latest Docker image...${NC}"
docker pull ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest

# Stop existing container
echo -e "${YELLOW}Stopping existing container...${NC}"
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Run new container
echo -e "${YELLOW}Starting new container...${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p ${PORT}:8080 \
  -e DB_URL="${DB_URL}" \
  -e DB_USERNAME="${DB_USERNAME}" \
  -e DB_PASSWORD="${DB_PASSWORD}" \
  -e SPRING_PROFILES_ACTIVE=prod \
  ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest

# Wait for container to start
echo -e "${YELLOW}Waiting for container to start...${NC}"
sleep 10

# Check container status
if docker ps | grep -q ${CONTAINER_NAME}; then
    echo -e "${GREEN}✓ Container is running${NC}"

    # Show container logs
    echo -e "${YELLOW}Recent logs:${NC}"
    docker logs --tail 20 ${CONTAINER_NAME}

    # Clean up old images
    echo -e "${YELLOW}Cleaning up old images...${NC}"
    docker image prune -af

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}Application is running on port ${PORT}${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    echo -e "${RED}Showing error logs:${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
fi
