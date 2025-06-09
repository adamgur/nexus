output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.aks.name
}

output "aks_name" {
  description = "The name of the created AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  description = "Kubernetes config file for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
