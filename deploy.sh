echo "Creating namespace..."
kubectl apply -f namespace.yaml

echo "Installing PostgreSQL..."
bash helm/install-postgres.sh

echo "Installing Kafka..."
bash helm/install-kafka.sh

echo "Deploying linkshortener..."
kubectl apply -f linkshortener/

echo "Deploying linkshortener-analytics..."
kubectl apply -f linkshortener-analytics/

echo "Done"
