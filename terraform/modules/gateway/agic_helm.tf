resource "helm_release" "agic_controller" {
  name       = "ingress-azure"
  chart      = "${path.module}/../../../ingress-azure-1.8.1.tgz"  

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
      name  = "aksClusterConfiguration.resourceGroup" 
      value = var.resource_group_name
    },
    {
      name  = "aksClusterConfiguration.clusterName"
      value = var.cluster_name
    },
    {
      name = "aksClusterConfiguration.provideSslCertificates"
      value = "true" 
    },
    {
      name = "appgw.shared"
      value = "false" 
    },
    {
      name = "rbac.enabled"
      value = "true"
    }
  ]

  depends_on = [
    azurerm_application_gateway.agic_gateway
  ]
}

data "azurerm_subscription" "current" {}