source "$(dirname "$0")/../.env"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install postgres bitnami/postgresql \
  --namespace linkshortener \
  --create-namespace \
  --set auth.username="${POSTGRES_USER}" \
  --set auth.password="${POSTGRES_PASSWORD}" \
  --set auth.database="${POSTGRES_DB}"