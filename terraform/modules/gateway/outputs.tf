output "application_gateway_public_ip" {
  value = azurerm_public_ip.agic_public_ip.ip_address
  description = "The public IP address of the Azure Application Gateway."
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks_subnet.id
  description = "The ID of the subnet dedicated for AKS."
}

# output "key_vault_uri" {
#   value       = azurerm_key_vault.main_kv.vault_uri
#   description = "The URI of the main Azure Key Vault."
# }

# output "key_vault_name" {
#   value       = azurerm_key_vault.main_kv.name
#   description = "The name of the main Azure Key Vault."
# }