#!/bin/bash

# ArgoCD Development Deployment Script
# Optimized for POC/Development environments

set -e

# Configuration
NAMESPACE="argocd"
RELEASE_NAME="argocd"
VALUES_FILE="argocd-dev-values.yaml"

echo "🚀 Deploying ArgoCD for Development/POC Environment"
echo "================================================="
echo ""

# CRITICAL SECURITY WARNINGS
echo "🚨 SECURITY CONFIGURATION ACTIVE:"
echo "• Network Policies ENABLED - Zero-trust networking"
echo "• Dex Authentication DISABLED - Using local admin only"
echo "• Full monitoring enabled - ServiceMonitors configured"
echo ""

echo "⚠️  PREREQUISITE CHECKS:"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed or not in PATH"
    exit 1
fi

# Check if connected to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to a Kubernetes cluster"
    echo "Please configure kubectl to connect to your AKS cluster"
    exit 1
fi

# Check for Network Policy support (critical for security)
echo "🔍 Checking Network Policy support..."
if kubectl get pods -n kube-system 2>/dev/null | grep -E "(azure-npm|calico|cilium)" &> /dev/null; then
    echo "✅ Network Policy provider found"
else
    echo "⚠️  Network Policy provider not detected"
    echo "Network policies may not work. Consider enabling Azure Network Policy addon."
fi

# Check for Application Gateway Ingress Controller
echo "🔍 Checking Application Gateway Ingress Controller..."
if kubectl get pods -n kube-system 2>/dev/null | grep "ingress-azure" &> /dev/null; then
    echo "✅ Application Gateway Ingress Controller found"
else
    echo "⚠️  AGIC not found - Ingress may not work"
fi

echo ""
echo "✅ Prerequisites check completed"

# Add ArgoCD Helm repository
echo "📦 Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace if it doesn't exist
echo "🏗️  Creating namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade ArgoCD
echo "⚡ Installing ArgoCD..."
helm upgrade --install $RELEASE_NAME argo/argo-cd \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --timeout 10m \
  --wait

echo "🎉 ArgoCD deployment completed!"
echo ""

# Get initial admin password
echo "🔐 Getting initial admin password..."
ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "📋 ArgoCD Access Information:"
echo "================================"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE_NAME"
echo "Admin Username: admin"
echo "Admin Password: $ADMIN_PASSWORD"
echo ""

# Port forward instructions
echo "🌐 To access ArgoCD locally:"
echo "kubectl port-forward -n $NAMESPACE svc/argocd-server 8080:443"
echo "Then open: https://localhost:8080"
echo ""

# Ingress information
echo "🔗 Or via ingress (once DNS is configured):"
echo "https://argocd.nexus.local"
echo ""

echo "📚 Next Steps:"
echo "1. Configure DNS for argocd.nexus.local to point to your Application Gateway"
echo "2. Access ArgoCD UI using the credentials above"
echo "3. Start deploying your applications!"
echo ""

# Show pod status
echo "📊 Current Pod Status:"
kubectl get pods -n $NAMESPACE
