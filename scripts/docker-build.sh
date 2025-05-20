#!/bin/bash

# Script to build and manage Docker images for CodexContinue project
# This script provides utilities for building, tagging, and pushing images

set -e

# Configuration
PROJECT_NAME="codexcontinue"
REGISTRY="registry.example.com"  # Change to your Docker registry if needed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BUILD_BASE_DIR="$(dirname "$SCRIPT_DIR")"
SERVICES=("backend" "frontend" "ml")
ENV="${1:-dev}"  # Default to dev if no environment specified

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

usage() {
    echo "Usage: $0 [dev|prod] [command]"
    echo "Commands:"
    echo "  build      - Build all Docker images"
    echo "  push       - Push all Docker images to registry"
    echo "  clean      - Remove all Docker images"
    echo "  build:SERVICE - Build specific service (backend, frontend, ml)"
    echo "Examples:"
    echo "  $0 dev build        - Build development images"
    echo "  $0 prod build:ml    - Build production ML service image"
    exit 1
}

build_image() {
    local service=$1
    local env=$2
    local tag="${PROJECT_NAME}/${service}:${env}"
    local context="${BUILD_BASE_DIR}/${service}"
    local dockerfile="${BUILD_BASE_DIR}/docker/${service}/Dockerfile"
    local build_args=""
    
    # Set different Dockerfile for development or production
    if [ "$env" == "prod" ]; then
        build_args="--target production"
    else
        build_args="--target development"
    fi
    
    log "Building ${service} image for ${env} environment..."
    docker build ${build_args} -t ${tag} -f ${dockerfile} ${context}
    
    # Tag with registry if registry is configured
    if [ -n "$REGISTRY" ] && [ "$REGISTRY" != "registry.example.com" ]; then
        local registry_tag="${REGISTRY}/${tag}"
        docker tag ${tag} ${registry_tag}
        log "Tagged ${tag} as ${registry_tag}"
    fi
    
    log "Successfully built ${tag}"
}

push_image() {
    local service=$1
    local env=$2
    local tag="${PROJECT_NAME}/${service}:${env}"
    
    # Only push if registry is configured
    if [ -n "$REGISTRY" ] && [ "$REGISTRY" != "registry.example.com" ]; then
        local registry_tag="${REGISTRY}/${tag}"
        log "Pushing ${registry_tag}..."
        docker push ${registry_tag}
        log "Successfully pushed ${registry_tag}"
    else
        warn "Registry not configured. Skipping push."
    fi
}

clean_image() {
    local service=$1
    local env=$2
    local tag="${PROJECT_NAME}/${service}:${env}"
    
    log "Removing ${tag}..."
    docker rmi ${tag} || true
    
    # Remove registry tag if configured
    if [ -n "$REGISTRY" ] && [ "$REGISTRY" != "registry.example.com" ]; then
        local registry_tag="${REGISTRY}/${tag}"
        docker rmi ${registry_tag} || true
    fi
}

# Check command argument
COMMAND="${2:-build}"  # Default to build if no command specified

case "$COMMAND" in
    build)
        for service in "${SERVICES[@]}"; do
            build_image "$service" "$ENV"
        done
        ;;
    push)
        for service in "${SERVICES[@]}"; do
            push_image "$service" "$ENV"
        done
        ;;
    clean)
        for service in "${SERVICES[@]}"; do
            clean_image "$service" "$ENV"
        done
        ;;
    build:*)
        service="${COMMAND#build:}"
        if [[ " ${SERVICES[@]} " =~ " ${service} " ]]; then
            build_image "$service" "$ENV"
        else
            error "Unknown service: $service"
        fi
        ;;
    *)
        usage
        ;;
esac

log "Operation completed successfully!"
exit 0
