resource "helm_release" "agic_controller" {
  name       = "ingress-azure"
  chart      = "${path.module}/../../../ingress-azure-1.8.1.tgz"  # Use the local chart file with path.module
  namespace  = "kube-system" # Recommended namespace for AGIC

  set = [
    {
      name  = "appgw.subscriptionId"
      value = data.azurerm_subscription.current.subscription_id
    },
    {
      name  = "appgw.resourceGroup"
      value = var.resource_group_name
    },
    {
      name  = "appgw.name"
      value = azurerm_application_gateway.agic_gateway.name
    },
    {
      name  = "appgw.useManagedIdentity"
      value = "true"
    },
    {
      name  = "aksClusterConfiguration.resourceGroup" # This refers to the RG of the AKS cluster
      value = var.resource_group_name
    },
    {
      name  = "aksClusterConfiguration.clusterName"
      value = var.cluster_name
    },
    {
      name = "aksClusterConfiguration.provideSslCertificates"
      value = "true" # Set to true if you manage SSL certs directly via AGIC
    },
    {
      name = "appgw.shared"
      value = "false" # Set to true if you want to share the Application Gateway with other ingresses (advanced)
    },
    {
      name = "rbac.enabled"
      value = "true" # Recommended for production deployments
    }
  ]

  depends_on = [
    azurerm_application_gateway.agic_gateway
  ]
}

# Data source to retrieve current Azure subscription ID
data "azurerm_subscription" "current" {}