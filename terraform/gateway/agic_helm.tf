resource "helm_release" "agic_controller" {
  name       = "ingress-azure"
  repository = "https://azure.github.io/application-gateway-kubernetes-ingress/"
  chart      = "ingress-azure"
  namespace  = "kube-system" # Recommended namespace for AGIC

  # Ensure AKS has Managed Identity enabled for the cluster for AGIC to work with it
  # Ensure the AKS identity has 'Contributor' permissions on the Application Gateway and its Public IP
  # You might need to grant permissions explicitly if they are not inherited.
  # Example: az role assignment create --assignee <AKS_MANAGED_IDENTITY_ID> --role "Contributor" --scope <APP_GATEWAY_RESOURCE_ID>

  set {
    name  = "appgw.subscriptionId"
    value = data.azurerm_subscription.current.id
  }
  set {
    name  = "appgw.resourceGroup"
    value = var.resource_group_name
  }
  set {
    name  = "appgw.name"
    value = azurerm_application_gateway.agic_gateway.name
  }
  set {
    name  = "appgw.useManagedIdentity"
    value = "true"
  }
  set {
    name  = "aksClusterConfiguration.resourceGroup" # This refers to the RG of the AKS cluster
    value = var.resource_group_name
  }
  set {
    name  = "aksClusterConfiguration.clusterName"
    value = var.cluster_name
  }
  set {
    name = "aksClusterConfiguration.provideSslCertificates"
    value = "true" # Set to true if you manage SSL certs directly via AGIC
  }
  set {
    name = "appgw.shared"
    value = "false" # Set to true if you want to share the Application Gateway with other ingresses (advanced)
  }
  set {
    name = "rbac.enabled"
    value = "true" # Recommended for production deployments
  }
}

# Data source to retrieve current Azure subscription ID
data "azurerm_subscription" "current" {}