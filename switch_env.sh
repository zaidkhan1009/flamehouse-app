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
    APP_NAME="Flamehouse Dev"
    ;;
  staging)
    echo "Switching to STAGING environment..."
    cp .env.staging .env
    APP_NAME="Flamehouse UAT"
    ;;
  prod)
    echo "Switching to PRODUCTION environment..."
    cp .env.production .env
    APP_NAME="Flamehouse"
    ;;
  *)
    echo "Invalid environment. Choose from: dev, staging, prod"
    exit 1
    ;;
esac

echo "Updating application display names to '$APP_NAME'..."

# Update Android Manifest label
sed -i '' 's/android:label="[^"]*"/android:label="'"$APP_NAME"'"/g' android/app/src/main/AndroidManifest.xml

# Update iOS Info.plist display names
plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist
plutil -replace CFBundleName -string "$APP_NAME" ios/Runner/Info.plist

echo "Environment updated successfully! Active configuration in .env:"
cat .env
