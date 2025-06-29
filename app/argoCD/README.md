# ArgoCD for Your POC

⚠️ **SECURITY-FIRST CONFIGURATION** - Read the warnings below before deploying!

Simple ArgoCD setup for your 3-node AKS cluster with 3 microservices, featuring Azure AD authentication, full monitoring, and network security.

## 🚨 CRITICAL DEPLOYMENT WARNINGS

**This configuration prioritizes security and requires specific deployment order:**

1. **🔒 Network Policies are ENABLED** - Zero-trust networking by default
2. **📊 Monitoring Dependencies** - Deploy Prometheus FIRST or lose metrics
3. **🔐 Azure AD Required** - No local admin access without AAD setup
4. **📋 Prerequisites** - AKS cluster needs network policy support

**READ `SECURITY-FIRST-DEPLOYMENT.md` BEFORE DEPLOYING!**

## �️ Deployment Process

**⚠️ MANDATORY ORDER - Security and networking dependencies:**

1. **Prerequisites Check** - Verify network policies, Azure AD, AGIC
2. **Deploy Monitoring** - Prometheus/Grafana FIRST (required for metrics)
3. **Azure AD Setup** - Configure app registration and groups
4. **Deploy ArgoCD** - Run deployment script
5. **Validate Security** - Verify network policies and authentication

## 🚀 Quick Deploy (After Prerequisites)

```bash
# OPTION 1: Use the security-first deployment guide (RECOMMENDED)
# Follow step-by-step process in SECURITY-FIRST-DEPLOYMENT.md

# OPTION 2: If prerequisites are already met
# PowerShell (Windows)
./deploy-argocd-dev.ps1

# Bash (Linux/Mac/WSL)
chmod +x deploy-argocd-dev.sh
./deploy-argocd-dev.sh
```

## 📁 What's Here

- `argocd-dev-values.yaml` - ArgoCD configuration with Azure AD + Full Monitoring
- `deploy-argocd-dev.sh` - Bash deployment script  
- `deploy-argocd-dev.ps1` - PowerShell deployment script
- `AZURE-AD-SETUP.md` - Guide for Azure Active Directory integration
- `MONITORING-SETUP.md` - Complete monitoring setup with Prometheus & Grafana
- `README.md` - This file

## 🎯 Your Setup

- **Cluster**: 3 nodes × Standard_D2s_v3 (2 vCPUs, 8GB RAM each)
- **ArgoCD Resources**: ~1.5 CPU cores, ~3.5GB RAM (leaves plenty for your apps)
- **Replicas**: 1 of each component (appropriate for POC)
- **Authentication**: Azure Active Directory integration
- **Monitoring**: Full metrics with Prometheus integration
- **SSL**: HTTPS with automatic redirect

## 📋 Prerequisites

1. **kubectl** connected to your AKS cluster
2. **Helm 3.x** installed
3. **DNS** - Point `argocd.nexus.local` to your Application Gateway IP

## � Access ArgoCD

**After deployment:**

1. **Get password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. **Access via ingress:** https://argocd.nexus.local
   - Username: `admin`
   - Password: (from step 1)

3. **OR port-forward for testing:**
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Then open: https://localhost:8080
```

## �️ Next Steps

1. **Deploy your apps** through ArgoCD
2. **Connect your Git repos** for GitOps
3. **Learn ArgoCD** with your 3 microservices

## 🔧 Troubleshooting

**Pods not starting?**
```bash
kubectl get pods -n argocd
kubectl describe pod <pod-name> -n argocd
```

**Can't access ingress?**
```bash
kubectl get ingress -n argocd
# Check if argocd.nexus.local resolves to your Application Gateway IP
```

**Need help?** Check [ArgoCD docs](https://argo-cd.readthedocs.io/)
