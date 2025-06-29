echo "=== Linkshortener Access Setup ==="
echo "Choose how you want to access your services:"
echo ""
echo "1. Ingress (Recommended - with nginx)"
echo "2. NodePort (Local development)"
echo "3. LoadBalancer (Cloud environments)"
echo "4. Port-forward (Temporary access)"
echo "5. Show current access methods"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "Setting up Ingress..."
        
        # Check if nginx ingress is installed
        if ! kubectl get ingressclass nginx >/dev/null 2>&1; then
            echo "Installing nginx ingress controller..."
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
            echo "Waiting for ingress controller to be ready..."
            kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
        fi
        
        # Apply ingress
        kubectl apply -f base/ingress.yaml
        
        # Add to /etc/hosts
        echo "Add these lines to your /etc/hosts file:"
        echo "127.0.0.1 linkshortener.local"
        echo "127.0.0.1 analytics.local"
        echo ""
        echo "Then access:"
        echo "Main app: http://linkshortener.local"
        echo "Analytics: http://analytics.local"
        ;;
    2)
        echo "Setting up NodePort services..."
        kubectl apply -f base/nodeport-services.yaml
        echo "Access your services at:"
        echo "Main app: http://localhost:30080"
        echo "Analytics: http://localhost:30081"
        ;;
    3)
        echo "Setting up LoadBalancer services..."
        kubectl apply -f base/loadbalancer-services.yaml
        echo "Waiting for external IPs..."
        kubectl get svc -n linkshortener -w
        ;;
    4)
        echo "Starting port-forward..."
        echo "Main app will be available at http://localhost:8080"
        echo "Analytics will be available at http://localhost:8081"
        echo ""
        echo "Press Ctrl+C to stop"
        kubectl port-forward -n linkshortener svc/linkshortener 8080:80 &
        kubectl port-forward -n linkshortener svc/linkshortener-analytics 8081:80
        ;;
    5)
        echo "Current services:"
        kubectl get svc -n linkshortener
        echo ""
        echo "Current ingresses:"
        kubectl get ingress -n linkshortener
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
