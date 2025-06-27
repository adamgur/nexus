output "application_gateway_public_ip" {
  value = azurerm_public_ip.agic_public_ip.ip_address
  description = "The public IP address of the Azure Application Gateway."
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks_subnet.id
  description = "The ID of the subnet dedicated for AKS."
}