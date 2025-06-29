# ArgoCD Development Deployment Script (PowerShell)
# Optimized for POC/Development environments

param(
    [string]$Namespace = "argocd",
    [string]$ReleaseName = "argocd",
    [string]$ValuesFile = "argocd-dev-values.yaml"
)

Write-Host "🚀 Deploying ArgoCD for Development/POC Environment" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# CRITICAL SECURITY WARNINGS
Write-Host "🚨 SECURITY CONFIGURATION ACTIVE:" -ForegroundColor Red
Write-Host "• Network Policies ENABLED - Zero-trust networking" -ForegroundColor Yellow
Write-Host "• Dex Authentication DISABLED - Using local admin only" -ForegroundColor Yellow
Write-Host "• Full monitoring enabled - ServiceMonitors configured" -ForegroundColor Yellow
Write-Host ""

Write-Host "⚠️  PREREQUISITE CHECKS:" -ForegroundColor Cyan

# Check if kubectl is available
try {
    kubectl version --client | Out-Null
    Write-Host "✅ kubectl is available" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if helm is available
try {
    helm version --short | Out-Null
    Write-Host "✅ Helm is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if connected to Kubernetes cluster
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected to a Kubernetes cluster" -ForegroundColor Red
    Write-Host "Please configure kubectl to connect to your AKS cluster" -ForegroundColor Yellow
    exit 1
}

# Check for Network Policy support (critical for security)
Write-Host "🔍 Checking Network Policy support..." -ForegroundColor Cyan
try {
    $networkPolicySupport = kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}' 2>$null
    $networkPolicyPods = kubectl get pods -n kube-system 2>$null | Select-String -Pattern "(azure-npm|calico|cilium)"
    
    if ($networkPolicyPods) {
        Write-Host "✅ Network Policy provider found" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Network Policy provider not detected" -ForegroundColor Yellow
        Write-Host "Network policies may not work. Consider enabling Azure Network Policy addon." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check Network Policy support" -ForegroundColor Yellow
}

# Check for Application Gateway Ingress Controller
Write-Host "🔍 Checking Application Gateway Ingress Controller..." -ForegroundColor Cyan
try {
    $agicPods = kubectl get pods -n kube-system 2>$null | Select-String -Pattern "ingress-azure"
    if ($agicPods) {
        Write-Host "✅ Application Gateway Ingress Controller found" -ForegroundColor Green
    } else {
        Write-Host "⚠️  AGIC not found - Ingress may not work" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check AGIC status" -ForegroundColor Yellow
}

Write-Host ""

# Add ArgoCD Helm repository
Write-Host "📦 Adding ArgoCD Helm repository..." -ForegroundColor Cyan
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace if it doesn't exist
Write-Host "🏗️  Creating namespace '$Namespace'..." -ForegroundColor Cyan
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade ArgoCD
Write-Host "⚡ Installing ArgoCD..." -ForegroundColor Cyan
helm upgrade --install $ReleaseName argo/argo-cd `
  --namespace $Namespace `
  --values $ValuesFile `
  --timeout 10m `
  --wait

Write-Host "🎉 ArgoCD deployment completed!" -ForegroundColor Green
Write-Host ""

# Get initial admin password
Write-Host "🔐 Getting initial admin password..." -ForegroundColor Cyan
try {
    $AdminPasswordBase64 = kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
    $AdminPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($AdminPasswordBase64))
    
    Write-Host "📋 ArgoCD Access Information:" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Yellow
    Write-Host "Namespace: $Namespace"
    Write-Host "Release: $ReleaseName"
    Write-Host "Admin Username: admin"
    Write-Host "Admin Password: $AdminPassword"
    Write-Host ""
} catch {
    Write-Host "⚠️  Could not retrieve admin password. It may not be ready yet." -ForegroundColor Yellow
    Write-Host "Try running this command in a few minutes:" -ForegroundColor Yellow
    Write-Host "kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d" -ForegroundColor Gray
    Write-Host ""
}

# Port forward instructions
Write-Host "🌐 To access ArgoCD locally:" -ForegroundColor Cyan
Write-Host "kubectl port-forward -n $Namespace svc/argocd-server 8080:443" -ForegroundColor Gray
Write-Host "Then open: https://localhost:8080" -ForegroundColor Gray
Write-Host ""

# Ingress information
Write-Host "🔗 Or via ingress (once DNS is configured):" -ForegroundColor Cyan
Write-Host "https://argocd.nexus.local" -ForegroundColor Gray
Write-Host ""

Write-Host "📚 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure DNS for argocd.nexus.local to point to your Application Gateway"
Write-Host "2. Access ArgoCD UI using the credentials above"
Write-Host "3. Start deploying your applications!"
Write-Host ""

# Show pod status
Write-Host "📊 Current Pod Status:" -ForegroundColor Cyan
kubectl get pods -n $Namespace
