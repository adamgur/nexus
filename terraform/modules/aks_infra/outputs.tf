output "client_id" {
  description = "The application id of AzureAD application created."
  value       = module.ServicePrincipal.client_id
}

output "service_principal_name" {
  description = "The service principal name."
  value       = module.ServicePrincipal.service_principal_name
  sensitive   = true

}

output "aks_name" {
  description = "The name of the created AKS cluster"
  value = module.aks_with_acr.aks_name
}

output "kube_config" {
  description = "Kubernetes config file for the AKS cluster as a map"
  value = module.aks_with_acr.kube_config
  sensitive = true
}