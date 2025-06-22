resource "azurerm_resource_group" "aks" {
  name     = "${var.cluster_name}-rg"
  location = var.location
  tags = {
    Environment = "shared-infra"
    Project     = "Nexus"
  }
}

resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.cluster_name}-vnet"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags = {
    Environment = "shared-infra"
  }
}

# Subnet for the AKS Cluster
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
  tags = {
    Environment = "shared-infra"
  }
}

# Public IP for the Azure Application Gateway
resource "azurerm_public_ip" "agic_public_ip" {
  name                = "${var.cluster_name}-appgw-pip"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = "shared-infra"
  }
}

# Dedicated subnet for the Azure Application Gateway
resource "azurerm_subnet" "agic_subnet" {
  name                 = "${var.cluster_name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
  service_endpoints    = ["Microsoft.Web", "Microsoft.Storage"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Network/virtualNetworks/subnets/delegations"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  tags = {
    Environment = "shared-infra"
  }
}

# Azure Application Gateway
resource "azurerm_application_gateway" "agic_gateway" {
  name                = "${var.cluster_name}-app-gateway"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.agic_subnet.id
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
    public_ip_address_id = azurerm_public_ip.agic_public_ip.id
  }

  backend_address_pool {
    name = "appGatewayBackendPool"
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.cluster_name}-default-http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "httpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
  }

  tags = {
    Environment = "shared-infra"
  }
}