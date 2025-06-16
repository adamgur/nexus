output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.aks.name
}

output "aks_name" {
  description = "The name of the created AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  description = "Kubernetes config file for the AKS cluster as a map"
  value = {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
    client_key             = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  }
  sensitive = true
}
