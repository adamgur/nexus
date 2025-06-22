# terraform/application_gateway.tf

# Create a resource group for each cluster, named dynamically
resource "azurerm_resource_group" "per_cluster_rg" {
  for_each = var.clusters
  name     = "${each.value.cluster_name}-rg"
  location = var.location
  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Define the Virtual Network for each cluster
resource "azurerm_virtual_network" "per_cluster_vnet" {
  for_each            = var.clusters
  name                = "${each.value.cluster_name}-vnet"
  resource_group_name = azurerm_resource_group.per_cluster_rg[each.key].name
  location            = var.location
  address_space       = [each.value.vnet_address_space]
  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Subnet for the AKS Cluster (ensure your AKS cluster configuration uses this subnet ID)
resource "azurerm_subnet" "aks_subnet" {
  for_each             = var.clusters
  name                 = "${each.value.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.per_cluster_rg[each.key].name
  virtual_network_name = azurerm_virtual_network.per_cluster_vnet[each.key].name
  address_prefixes     = [each.value.aks_subnet_cidr]
  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Public IP for each Application Gateway
resource "azurerm_public_ip" "agic_public_ip" {
  for_each            = var.clusters
  name                = "${each.value.cluster_name}-appgw-pip"
  resource_group_name = azurerm_resource_group.per_cluster_rg[each.key].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Dedicated subnet for each Application Gateway
resource "azurerm_subnet" "agic_subnet" {
  for_each             = var.clusters
  name                 = "${each.value.cluster_name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.per_cluster_rg[each.key].name
  virtual_network_name = azurerm_virtual_network.per_cluster_vnet[each.key].name
  address_prefixes     = [each.value.appgw_subnet_cidr]
  service_endpoints    = ["Microsoft.Web", "Microsoft.Storage"] 
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Network/virtualNetworks/subnets/delegations"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Azure Application Gateway for each cluster
resource "azurerm_application_gateway" "agic_gateway" {
  for_each            = var.clusters
  name                = "${each.value.cluster_name}-app-gateway"
  resource_group_name = azurerm_resource_group.per_cluster_rg[each.key].name
  location            = var.location

  sku {
    name = "Standard_v2" # Standard_v2 or WAF_v2 is required for AGIC
    tier = "Standard_v2"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.agic_subnet[each.key].id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.agic_public_ip[each.key].id
  }

  backend_address_pool {
    name = "appGatewayBackendPool" # AGIC will manage this
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings" # AGIC will manage this
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20 # seconds
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${each.value.cluster_name}-default-http-routing-rule" # More descriptive name
    rule_type                  = "Basic"
    http_listener_name         = "httpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
  }

  tags = {
    Environment = each.value.environment
    ClusterName = each.value.cluster_name
  }
}

# Output the public IP of each Application Gateway
output "application_gateway_public_ips" {
  value = { for k, v in azurerm_public_ip.agic_public_ip : k => v.ip_address }
  description = "A map of public IP addresses for each Azure Application Gateway, keyed by cluster identifier."
}

# Output the AKS Subnet ID for each cluster
output "aks_subnet_ids" {
  value       = { for k, v in azurerm_subnet.aks_subnet : k => v.id }
  description = "A map of subnet IDs dedicated for AKS, keyed by cluster identifier."
}