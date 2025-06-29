ENVIRONMENT=${1:-development}

if [ "$ENVIRONMENT" = "staging" ]; then
    echo "Deploying to staging environment..."
    kubectl apply -k overlays/staging/
elif [ "$ENVIRONMENT" = "development" ]; then
    echo "Deploying to development environment..."
    kubectl apply -k base/
else
    echo "Unknown environment: $ENVIRONMENT"
    echo "Usage: ./deploy.sh [development|staging]"
    exit 1
fi

echo "Deployment completed for $ENVIRONMENT environment"
