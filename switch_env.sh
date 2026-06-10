#!/bin/bash

# ==============================================================================
# Environment Swapping Utility for Flamehouse Client (Flutter)
# ==============================================================================

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./switch_env.sh [dev|staging|prod]"
  exit 1
fi

case "$ENV" in
  dev)
    echo "Switching to DEVELOPMENT environment..."
    cp .env.development .env
    ;;
  staging)
    echo "Switching to STAGING environment..."
    cp .env.staging .env
    ;;
  prod)
    echo "Switching to PRODUCTION environment..."
    cp .env.production .env
    ;;
  *)
    echo "Invalid environment. Choose from: dev, staging, prod"
    exit 1
    ;;
esac

echo "Environment updated successfully! Active configuration in .env:"
cat .env
