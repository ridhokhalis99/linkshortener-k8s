echo "=== Ingress Controller Setup ==="
echo "Choose your ingress controller:"
echo ""
echo "1. NGINX Ingress Controller (Recommended)"
echo "2. Traefik (Developer-friendly)"
echo "3. Kong Ingress Controller"
echo "4. Check existing controllers"
echo "5. Skip ingress setup"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "Installing NGINX Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        
        echo "Waiting for NGINX controller to be ready..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=120s
        
        echo "NGINX Ingress Controller installed successfully!"
        ;;
    2)
        echo "Installing Traefik..."
        
        # Create Traefik namespace
        kubectl create namespace traefik-system --dry-run=client -o yaml | kubectl apply -f -
        
        # Install Traefik using official manifests
        kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
        kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
        
        # Create Traefik deployment
        cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-ingress-controller
      containers:
      - name: traefik
        image: traefik:v2.10
        args:
        - --api.insecure=true
        - --providers.kubernetesingress
        - --entrypoints.web.address=:80
        ports:
        - containerPort: 80
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik-system
spec:
  type: LoadBalancer
  selector:
    app: traefik
  ports:
  - port: 80
    targetPort: 80
  - port: 8080
    targetPort: 8080
EOF
        
        echo "Traefik installed successfully!"
        echo "Dashboard available at: http://localhost:8080 (after port-forward)"
        ;;
    3)
        echo "Installing Kong Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/main/deploy/single/all-in-one-dbless.yaml
        
        echo "Waiting for Kong controller to be ready..."
        kubectl wait --namespace kong \
            --for=condition=ready pod \
            --selector=app=ingress-kong \
            --timeout=120s
        
        echo "Kong Ingress Controller installed successfully!"
        ;;
    4)
        echo "Checking existing ingress controllers..."
        kubectl get ingressclass
        echo ""
        kubectl get pods -A | grep -E "(ingress|traefik|kong)"
        ;;
    5)
        echo "Skipping ingress setup..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Applying ingress configuration..."
kubectl apply -f base/ingress.yaml

echo ""
echo "Setup complete! Don't forget to add to /etc/hosts:"
echo "127.0.0.1 linkshortener.local"
echo "127.0.0.1 analytics.local"
