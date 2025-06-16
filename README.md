# 🚀 AKS Monitoring with Prometheus and Alertmanager

## **📌 1. Prerequisites**
Before starting, ensure you have the following CLI tools installed on your system:

- **Azure CLI (`az`)** – Used to interact with Azure services.
- **Kubectl (`kubectl`)** – Used to interact with the Kubernetes cluster.
- **Helm (`helm`)** – Used to manage Kubernetes applications.

## **📌 2. Login to Your Azure Account**
Before deploying the AKS cluster, you need to authenticate with Azure.

### **🔹 Step 1: Log in to Azure**
Run the following command to log in to your Azure account:
```bash
az login --allow-no-subscriptions
```

## **📌 3. Navigate to the Terraform Directory**
Once logged into Azure, move to the directory where your Terraform files (`main.tf` and `variables.tf`) are located.

Use the following command to navigate to the directory containing your Terraform configuration files:
```bash
cd terraform/
```

## **📌 4. Initialize and Deploy the AKS Cluster Using Terraform**
Now that you're inside the Terraform directory, you need to **initialize Terraform**, **review the planned changes**, and **apply the configuration** to create the AKS cluster.

### **🔹 Step 1: Initialize Terraform**
Before running Terraform, initialize it with the following command:
```bash
terraform init
```
This command initializes Terraform by downloading the necessary provider plugins and setting up the backend for storing the Terraform state.

### **🔹 Step 2: Review the Terraform Plan**
```bash
terraform plan
```
This command creates an execution plan, showing what Terraform will change in the infrastructure before applying any modifications.

### **🔹 Step 3: Apply the Terraform Configuration**
```bash
terraform apply
```
This command applies the configuration defined in your Terraform files, provisioning the necessary resources in your Azure environment.

> ⚠️ **Important Notes About `terraform apply`**

1. **ACR Name Must Be Globally Unique**  
   When creating an Azure Container Registry (`azurerm_container_registry`), the `name` must be **globally unique across all Azure subscriptions**.  
   If you get an error like `The registry name is already in use`, change the name to something more unique, for example:
   ```hcl
   name = "${var.cluster_name}acr12345"

2. **You Must Provide Your Azure Subscription ID**
    Make sure to set the subscription_id variable in your terraform.tfvars or directly in your main.tf file.
    You can retrieve your Azure Subscription ID using:
    ```bash
    az account show --query id --output tsv
    ```

## **📌 4.5 Connect to the AKS Cluster**
Before deploying ArgoCD, you need to connect to the AKS cluster.

### **🔹 Step 1: Retrieve AKS Credentials**
Use the following command to authenticate with your AKS cluster and configure `kubectl` to use the correct context:
```bash
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
```
This command retrieves the credentials for your AKS cluster and updates your `kubeconfig` file. The `--overwrite-existing` flag ensures that if any previous credentials exist, they are replaced with the new ones.

## **📌 5. Deploy ArgoCD**
After the AKS cluster is deployed, we will install **ArgoCD** to manage Kubernetes applications.

### **🔹 Step 1: Create the ArgoCD Namespace**
Before installing ArgoCD, create a dedicated namespace:
```bash
kubectl create namespace argocd
```

### **🔹 Step 2: Install ArgoCD**
Now, install ArgoCD by applying its official manifest:
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
This command deploys all the necessary ArgoCD components, including the API server, controller, and UI, into the `argocd` namespace.

### **🔹 Step 3: Expose the ArgoCD API Server**
To access the ArgoCD UI externally, update the service type to LoadBalancer:
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```
This command modifies the ArgoCD server service to expose it via an external load balancer.

### **🔹 Step 4: Find the External IP**
Retrieve the external IP assigned to the ArgoCD server:
```bash
kubectl get svc -n argocd argocd-server
```
Use the external IP displayed to access the ArgoCD web UI.

### **🔹 Step 5: Retrieve the ArgoCD Admin Password**
By default, the username is `admin`, and the password is stored in a Kubernetes secret.

To log in, you need the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```
This command fetches and decodes the default admin password, allowing you to log in to the ArgoCD UI.

### **🔹 Step 6: Deploy Application Configuration with ArgoCD**
Once ArgoCD is installed, deploy your application by applying the `application.yaml` file found in the `app/` directory:
```bash
kubectl apply -f app/application.yaml
```
This command configures ArgoCD to manage your application by creating an ArgoCD `Application` resource, which defines the repository, target cluster, and sync settings for deployment.

## **📌 6. Deploy Monitoring with Prometheus and Alertmanager**
After deploying ArgoCD, we will set up **Prometheus and Alertmanager** for monitoring the AKS cluster.

### **🔹 Step 1: Navigate to the Monitoring Directory**
Move to the directory containing monitoring configuration files:
```bash
cd app/monitoring
```

### **🔹 Step 2: Add the Helm Repository**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### **🔹 Step 3: Install Prometheus and Alertmanager**
Use Helm to install the `kube-prometheus-stack` with a custom values file:
```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f alertmanager-values.yaml
```
This values file customizes Alertmanager settings by:
- Configuring **email notifications** for critical alerts.
- Defining **multi-channel alert routing** (email + webhook).
- Ensuring alerts are sent to the appropriate receivers based on severity.

### **🔹 Step 4: Verify the Installation**
Ensure Prometheus and Alertmanager pods are running:
```bash
kubectl get pods -n monitoring
```
### **🔹 Step 6: Deploy Cpu Alert**
```bash
kubectl apply -f cpu-alert.yaml
```
### **🔹 Step 6: Expose Prometheus and Alertmanager**
Expose Prometheus on port 9090:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Once forwarded, you can access Prometheus at: [http://localhost:9090]

Expose Alertmanager on port 9093:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```
Once forwarded, you can access Alertmanager at: [http://localhost:9093]
