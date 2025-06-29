# Security-First ArgoCD Deployment Guide

## ⚠️ CRITICAL DEPLOYMENT WARNINGS

**READ BEFORE DEPLOYING - SECURITY & NETWORKING IMPACT:**

1. **🚨 NETWORK POLICIES ARE ENABLED BY DEFAULT** 
   - This config implements **zero-trust networking**
   - **DEPLOYMENT ORDER MATTERS** - Network policies can block communication
   - You MUST have Azure Network Policy or Calico enabled in your AKS cluster
   - Failure to follow order may result in connectivity issues requiring cluster restart

2. **🔐 AZURE AD AUTHENTICATION IS MANDATORY**
   - ArgoCD will be inaccessible without proper Azure AD setup
   - Complete Azure AD configuration BEFORE deployment
   - Have your AAD group IDs ready

3. **📊 MONITORING DEPENDENCIES**
   - Deploy Prometheus/Grafana FIRST or ArgoCD metrics will be lost
   - Network policies must allow monitoring traffic

## 🛡️ Security-First Approach

Since your developers prioritize security, we'll deploy with:
- ✅ **Network Policies** enabled (zero-trust networking)
- ✅ **Monitoring first** (security observability)
- ✅ **Enhanced security contexts**
- ✅ **Azure AD authentication**

## 📋 Deployment Order (Security-First)

### Phase 1: Prerequisites & Monitoring Stack
Deploy monitoring infrastructure first to have full visibility from day one.

### Phase 2: ArgoCD with Security Hardening
Deploy ArgoCD with all security features enabled.

### Phase 3: Validation & Hardening
Verify security posture and fine-tune.

---

## � MANDATORY PREREQUISITE CHECKS

**⚠️ STOP! Before any deployment, verify these critical requirements:**

### CRITICAL: Network Policy Provider Status
```bash
# MUST return a network policy provider (Azure CNI or Calico)
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'
kubectl get pods -n kube-system | grep -E "(azure-npm|calico|cilium)"

# Check if network policies are supported
kubectl auth can-i create networkpolicies

# If no network policy provider, ArgoCD will have security gaps!
# Enable Azure Network Policy addon:
az aks enable-addons --resource-group <rg-name> --name <cluster-name> --addons azure-policy,azure-keyvault-secrets-provider
```

### CRITICAL: Azure AD Configuration Ready
```bash
# Verify you have these values configured:
echo "Azure AD Tenant ID: ${AZURE_TENANT_ID:-'❌ NOT SET'}"
echo "ArgoCD Client ID: ${ARGOCD_CLIENT_ID:-'❌ NOT SET'}" 
echo "ArgoCD Client Secret: ${ARGOCD_CLIENT_SECRET:-'❌ NOT SET'}"
echo "Admin Group Object ID: ${ADMIN_GROUP_ID:-'❌ NOT SET'}"
echo "Developer Group Object ID: ${DEV_GROUP_ID:-'❌ NOT SET'}"

# If any show "❌ NOT SET", complete AZURE-AD-SETUP.md first!
```

### CRITICAL: Ingress Controller Ready
```bash
# Verify Application Gateway Ingress Controller is running
kubectl get pods -n kube-system | grep ingress-azure
kubectl get ingressclass

# AGIC must be ready before ArgoCD deployment
```

---

## �🚀 Step-by-Step Deployment

### Step 1: Deploy Monitoring Stack First

**Why first?**
- Security observability from the start
- Detect any issues immediately
- Monitor ArgoCD deployment process
- Required for ServiceMonitors to work

```bash
# Add Prometheus community helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Stack with security configurations
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.securityContext.runAsNonRoot=true \
  --set prometheus.prometheusSpec.securityContext.runAsUser=65534 \
  --set grafana.adminPassword=admin123 \
  --set grafana.securityContext.runAsNonRoot=true \
  --set grafana.securityContext.runAsUser=472 \
  --wait \
  --timeout 10m
```

**Verify monitoring stack:**
```bash
# Check all pods are running
kubectl get pods -n monitoring

# Check Prometheus targets (should be empty initially)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/targets
```

### Step 2: Verify Network Policy Support

**Check if your AKS cluster supports network policies:**
```bash
# Check if Calico or Azure Network Policy is enabled
kubectl get pods -n kube-system | grep -i "calico\|network-policy"

# If no network policy provider, enable Azure Network Policy:
# az aks update --resource-group Nexus --name nexus-cluster --network-policy azure
```

### Step 3: Setup Azure AD (Before ArgoCD Deployment)

**Follow AZURE-AD-SETUP.md but collect these values first:**

```bash
# Required values to replace in argocd-dev-values.yaml:
AZURE_TENANT_ID="your-tenant-id"
AZURE_CLIENT_ID="your-client-id"  
AZURE_CLIENT_SECRET="your-client-secret"
ADMIN_GROUP_ID="your-admin-group-object-id"
DEVELOPER_GROUP_ID="your-developer-group-object-id"
```

**Update the configuration file:**
```bash
# Edit argocd-dev-values.yaml and replace placeholders:
# - YOUR_AZURE_APP_CLIENT_ID
# - YOUR_AZURE_APP_CLIENT_SECRET  
# - YOUR_AZURE_TENANT_ID
# - 12345678-1234-1234-1234-123456789012 (admin group)
# - 87654321-4321-4321-4321-210987654321 (developer group)
```

### Step 4: Deploy ArgoCD with Security Hardening

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create ArgoCD namespace
kubectl create namespace argocd

# Deploy ArgoCD with security-first configuration
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values argocd-dev-values.yaml \
  --timeout 15m \
  --wait
```

### Step 5: Verify Security Configuration

**Check network policies are created:**
```bash
# List all network policies
kubectl get networkpolicy -n argocd

# Example policies that should exist:
# - argocd-application-controller-network-policy
# - argocd-server-network-policy
# - argocd-repo-server-network-policy
# - argocd-redis-network-policy
```

**Verify pod security contexts:**
```bash
# Check security context is applied
kubectl get pod -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# Should show: runAsNonRoot:true, runAsUser:999, etc.
```

**Test network isolation:**
```bash
# Create test pod to verify network policies work
kubectl run test-pod --image=busybox -n default --rm -it -- sh

# Try to connect to ArgoCD (should be blocked)
nc -v argocd-server.argocd.svc.cluster.local 80
# Expected: Connection refused or timeout

# Exit test pod
exit
```

### Step 6: Verify Monitoring Integration

**Check ServiceMonitors are created:**
```bash
kubectl get servicemonitor -n argocd
```

**Verify metrics in Prometheus:**
```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Open: http://localhost:9090/targets
# Should see ArgoCD targets: argocd-application-controller, argocd-server, etc.
```

**Access Grafana:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Open: http://localhost:3000
# Username: admin, Password: admin123
```

### Step 7: Security Validation Checklist

**✅ Network Security:**
```bash
# Network policies are active
kubectl get networkpolicy -n argocd | wc -l  # Should be > 0

# Inter-pod communication is restricted
kubectl exec -n argocd argocd-server-xxx -- nc -v argocd-redis 6379  # Should work
kubectl exec -n default some-pod -- nc -v argocd-server.argocd 80    # Should fail
```

**✅ Pod Security:**
```bash
# Pods run as non-root
kubectl get pods -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.securityContext.runAsNonRoot}{"\n"}{end}'

# Containers have security context
kubectl describe pod -n argocd | grep -A5 "Security Context"
```

**✅ Authentication Security:**
```bash
# Azure AD is configured
kubectl get configmap argocd-cm -n argocd -o yaml | grep -i dex

# RBAC policies are restrictive
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
```

**✅ TLS/Encryption:**
```bash
# Ingress uses TLS
kubectl get ingress -n argocd -o yaml | grep tls

# Backend protocol is HTTPS
kubectl get ingress -n argocd -o yaml | grep https
```

---

## 🛡️ Security Features Enabled

### Network Security
- **Network Policies**: Zero-trust networking between pods
- **Default Deny**: All traffic blocked unless explicitly allowed
- **Ingress Control**: Only Application Gateway can reach ArgoCD
- **Inter-service Communication**: Restricted to necessary paths only

### Pod Security
- **Non-root Execution**: All containers run as user 999
- **Read-only Filesystems**: Where possible
- **Security Profiles**: Seccomp runtime default
- **Resource Limits**: Prevent resource exhaustion attacks

### Authentication & Authorization
- **Azure AD Integration**: No local user accounts (except emergency admin)
- **RBAC Policies**: Role-based access control
- **Group-based Access**: Permissions via Azure AD groups
- **API Key Restrictions**: Limited admin API access

### Transport Security
- **TLS Everywhere**: HTTPS ingress and backend communication
- **Certificate Management**: Automated via Application Gateway
- **Secure Headers**: SSL redirect and security headers

---

## 🚨 Security Monitoring Alerts

The monitoring stack will alert on:

```yaml
# Critical security events
- Pods running as root
- Network policy violations  
- Failed authentication attempts
- Privilege escalation attempts
- Resource limit breaches
- Unauthorized API access
```

---

## 🔧 Troubleshooting Security Issues

### Network Policy Problems
```bash
# Check if network policies are blocking legitimate traffic
kubectl describe networkpolicy -n argocd

# Temporarily disable to test
kubectl patch networkpolicy <policy-name> -n argocd -p '{"spec":{"podSelector":{}}}'
```

### Authentication Issues
```bash
# Check Azure AD configuration
kubectl logs -n argocd deployment/argocd-dex-server

# Verify RBAC policies
kubectl auth can-i get applications --as=system:serviceaccount:argocd:argocd-server -n argocd
```

### Security Context Problems
```bash
# Check if containers are failing to start due to security restrictions
kubectl describe pod -n argocd | grep -A10 "Events:"

# Check security context configuration
kubectl get pod -n argocd -o yaml | grep -A10 securityContext
```

This security-first approach ensures your ArgoCD deployment meets enterprise security standards from day one!
