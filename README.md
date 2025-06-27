# 🚀 Azure Kubernetes Service (AKS) with Application Gateway Ingress Controller (AGIC)

This project deploys a complete AKS infrastructure with Azure Application Gateway Ingress Controller, monitoring, and GitOps capabilities.

## **🏗️ Architecture Overview**

The infrastructure includes:
- **AKS Cluster** with managed identity and RBAC enabled
- **Azure Container Registry (ACR)** for container images
- **Azure Application Gateway** with AGIC for ingress management  
- **Virtual Network** with dedicated subnets for AKS and Application Gateway
- **Monitoring Stack** with Prometheus and Alertmanager
- **GitOps** with ArgoCD for application deployment

## **📌 Prerequisites**

Before starting, ensure you have the following CLI tools installed:

- **Azure CLI (`az`)** – For Azure service interaction
- **Terraform (`>= 1.0.0`)** – For infrastructure provisioning
- **Kubectl** – For Kubernetes cluster management
- **Helm (`>= 3.0`)** – For Kubernetes application management

## **📌 Getting Started**

### **🔹 Step 1: Azure Authentication**
Log in to your Azure account:
```bash
az login
```

Get your subscription ID:
```bash
az account show --query id --output tsv
```

### **� Step 2: Configure Variables**
Update the `terraform.tfvars` file with your specific values:
```hcl
subscription_id     = "your-subscription-id"
cluster_name        = "nexus-cluster"
resource_group_name = "Nexus"
location           = "West Europe"
environment        = "Shared"
acr_name           = "nexusacr20250627"  # Must be globally unique
```

### **🔹 Step 3: Deploy Infrastructure**
Navigate to the terraform directory and deploy:
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

This will create:
- AKS cluster with 3 nodes (Standard_D2s_v3)
- Azure Container Registry
- Virtual Network with subnets
- Azure Application Gateway
- AGIC (Azure Application Gateway Ingress Controller)
- CSI Secrets Store Provider for Azure Key Vault integration

### **🔹 Step 4: Connect to AKS Cluster**
Configure kubectl to connect to your new cluster:
```bash
az aks get-credentials --resource-group Nexus --name nexus-cluster --overwrite-existing
```

Verify connection:
```bash
kubectl get nodes
kubectl get pods -n kube-system
```

## **📌 Application Gateway & Ingress**

### **🔹 AGIC Configuration**
The Application Gateway Ingress Controller is automatically deployed and configured to:
- Watch for Kubernetes Ingress resources
- Automatically configure Azure Application Gateway rules
- Handle SSL termination and routing
- Provide Web Application Firewall (WAF) capabilities

### **🔹 Application Gateway Public IP**
Get the public IP of your Application Gateway:
```bash
az network public-ip show --resource-group Nexus --name nexus-cluster-appgw-pip --query ipAddress --output tsv
```

### **🔹 Deploying Applications with Ingress**
Create applications with Ingress resources that AGIC will automatically handle:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

## **📌 ArgoCD Deployment**

### **🔹 Step 1: Create ArgoCD Namespace**
```bash
kubectl create namespace argocd
```

### **🔹 Step 2: Install ArgoCD**
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### **🔹 Step 3: Expose ArgoCD via Ingress**
Instead of using LoadBalancer, create an Ingress resource for ArgoCD:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

### **🔹 Step 4: Get ArgoCD Admin Password**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### **🔹 Step 5: Deploy Applications**
```bash
kubectl apply -f app/application.yaml
```

## **📌 Monitoring with Prometheus and Alertmanager**

### **🔹 Step 1: Add Helm Repository**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### **🔹 Step 2: Install Monitoring Stack**
```bash
cd app/monitoring
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f alertmanager-values.yaml
```

### **🔹 Step 3: Deploy CPU Alerts**
```bash
kubectl apply -f cpu-alert.yaml
```

### **🔹 Step 4: Access Monitoring UIs via Ingress**
Create Ingress resources for Prometheus and Alertmanager:

```yaml
# Prometheus Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: prometheus.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
```

## **� Troubleshooting**

### **🔹 Common Issues**

1. **ACR Name Conflicts**: The ACR name must be globally unique. If you get naming conflicts, update the `acr_name` variable in `terraform.tfvars`.

2. **AGIC Pod Issues**: Check AGIC logs:
   ```bash
   kubectl logs -n kube-system deployment/ingress-azure
   ```

3. **Application Gateway Configuration**: Verify AGIC is managing the Application Gateway:
   ```bash
   kubectl get ingress --all-namespaces
   ```

4. **Network Connectivity**: Ensure your Application Gateway subnet and AKS subnet don't overlap.

### **� Useful Commands**

```bash
# Check all ingress resources
kubectl get ingress --all-namespaces

# Check AGIC status
kubectl get pods -n kube-system -l app=ingress-azure

# View Application Gateway configuration
az network application-gateway show --resource-group Nexus --name nexus-cluster-app-gateway

# Check Helm releases
helm list --all-namespaces
```

## **� Clean Up**

To destroy all resources:
```bash
terraform destroy
```

## **📌 Architecture Components**

| Component | Purpose | Access Method |
|-----------|---------|---------------|
| AKS Cluster | Kubernetes orchestrator | kubectl |
| Application Gateway | L7 load balancer & WAF | Public IP via AGIC |
| AGIC | Ingress controller | Automatic (watches Ingress resources) |
| ACR | Container registry | Integrated with AKS |
| Prometheus | Metrics collection | Ingress or port-forward |
| Alertmanager | Alert routing | Ingress or port-forward |
| ArgoCD | GitOps CD | Ingress or port-forward |

---

## **🎯 What's Deployed**

✅ **AKS Cluster** with managed identity  
✅ **Azure Application Gateway** with AGIC  
✅ **Azure Container Registry**  
✅ **Virtual Network** with proper subnets  
✅ **CSI Secrets Store Provider** for Key Vault integration  
✅ **Monitoring stack** ready for deployment  
✅ **GitOps** ready with ArgoCD  

**Public IP**: Your Application Gateway is accessible at the public IP shown in the Azure portal or via `az network public-ip show` command.
