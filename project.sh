#!/bin/bash

# Comprehensive K8s project management script
ENV=${1:-development}
ACTION=${2:-help}

# Environment configuration
if [ "$ENV" = "staging" ]; then
    NS="linkshortener-staging"
    PATH_K8S="overlays/staging/"
else
    NS="linkshortener"
    PATH_K8S="base/"
fi

case $ACTION in
    # Project lifecycle
    deploy|up|enable)
        echo "🚀 Deploying $ENV environment..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
        kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
        kubectl apply -k $PATH_K8S
        echo "✅ $ENV deployed - add to /etc/hosts: 127.0.0.1 linkshortener.local analytics.local"
        ;;
    
    disable|down)
        echo "🔻 Disabling $ENV..."
        kubectl scale deployment --all --replicas=0 -n $NS
        kubectl delete ingress --all -n $NS 2>/dev/null
        kubectl delete namespace ingress-nginx 2>/dev/null
        echo "✅ $ENV disabled"
        ;;
    
    delete)
        read -p "Delete $ENV environment? (y/N): " confirm
        [ "$confirm" = "y" ] && kubectl delete -k $PATH_K8S && echo "✅ $ENV deleted" || echo "Cancelled"
        ;;
    
    # Access methods
    nodeport)
        echo "🌐 Setting up NodePort access..."
        kubectl apply -f base/nodeport-services.yaml
        echo "✅ Access: http://localhost:30080 (app), http://localhost:30081 (analytics)"
        ;;
    
    loadbalancer)
        echo "☁️ Setting up LoadBalancer..."
        kubectl apply -f base/loadbalancer-services.yaml
        kubectl get svc -n $NS -w
        ;;
    
    port-forward|pf)
        echo "🔗 Port-forwarding (Ctrl+C to stop)..."
        kubectl port-forward -n $NS svc/linkshortener 8080:80 &
        kubectl port-forward -n $NS svc/linkshortener-analytics 8081:80 &
        kubectl port-forward -n $NS svc/postgres 5432:5432
        ;;
    
    # Information
    status|info)
        echo "📊 $ENV Status:"
        kubectl get deployments,pods,svc,ingress -n $NS
        ;;
    
    logs)
        POD=${3:-linkshortener}
        echo "📜 Logs for $POD:"
        kubectl logs -n $NS -l app=$POD --tail=50 -f
        ;;
    
    # Secrets helper
    encode-secret)
        read -p "Enter secret to encode: " -s secret
        echo ""
        echo "Base64: $(echo -n "$secret" | base64)"
        ;;
    
    generate-password)
        password=$(openssl rand -base64 12)
        echo "Password: $password"
        echo "Base64: $(echo -n "$password" | base64)"
        ;;
    
    help|*)
        cat << 'EOF'
🚀 Kubernetes Project Manager

USAGE: ./project.sh [environment] [action]

ENVIRONMENTS:
  development (default)  staging

ACTIONS:
  Lifecycle:
    deploy, up, enable     Deploy/start project
    disable, down          Stop project (keep configs)
    delete                 Delete everything
    
  Access:
    nodeport              Use NodePort (localhost:30080/30081)
    loadbalancer          Use LoadBalancer (cloud)
    port-forward, pf      Port-forward all services (8080=app, 8081=analytics, 5432=postgres)
    
  Info:
    status, info          Show project status
    logs [pod-name]       Show logs (default: linkshortener)
    
  Secrets:
    encode-secret         Encode secret for K8s
    generate-password     Generate random password

EXAMPLES:
  ./project.sh                          # Show help
  ./project.sh development deploy        # Deploy dev environment
  ./project.sh staging disable          # Disable staging
  ./project.sh development nodeport     # Setup NodePort access
  ./project.sh development pf           # Port-forward all (app:8080, analytics:8081, db:5432)
  ./project.sh development db           # Port-forward PostgreSQL only
  ./project.sh development logs kafka   # Show Kafka logs
EOF
        ;;
esac
