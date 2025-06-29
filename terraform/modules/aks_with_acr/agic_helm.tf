# AGIC Helm Chart Installation
resource "helm_release" "agic_controller" {
  name       = "ingress-azure"
  namespace  = "default"
  chart      = "${path.root}/../ingress-azure-1.8.1.tgz"

  values = [
    yamlencode({
      appgw = {
        subscriptionId = data.azurerm_subscription.current.subscription_id
        resourceGroup  = var.resource_group_name
        name          = azurerm_application_gateway.main.name
        useManagedIdentity = true
        userAssignedIdentityID = azurerm_user_assigned_identity.agic_identity.client_id
        shared = false
      }
      
      aksClusterConfiguration = {
        resourceGroup = var.resource_group_name
        clusterName   = azurerm_kubernetes_cluster.aks.name
      }
      
      rbac = {
        enabled = true
      }
      
      armAuth = {
        type = "aadPodIdentity"
        identityResourceID = azurerm_user_assigned_identity.agic_identity.id
        identityClientID   = azurerm_user_assigned_identity.agic_identity.client_id
      }
    })
  ]

  depends_on = [
    azurerm_application_gateway.main,
    azurerm_role_assignment.agic_appgw_contributor,
    azurerm_role_assignment.agic_aks_reader,
    azurerm_role_assignment.agic_managed_identity_operator
  ]
}
