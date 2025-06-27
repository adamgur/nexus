output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.aks.name
}

output "aks_name" {
  description = "The name of the created AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0]
  sensitive = true
  description = "Raw kubeconfig block from the AKS cluster for use by providers."
}