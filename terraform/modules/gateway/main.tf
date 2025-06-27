terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
    Project     = "Nexus"
  }
}

resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.cluster_name}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
  service_endpoints    = ["Microsoft.Web", "Microsoft.Storage"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_public_ip" "agic_public_ip" {
  name                = "${var.cluster_name}-appgw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_subnet" "agic_subnet" {
  name                 = "${var.cluster_name}-appgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
  service_endpoints    = ["Microsoft.Web", "Microsoft.Storage"]
}

resource "azurerm_application_gateway" "agic_gateway" {
  name                = "${var.cluster_name}-app-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
  min_capacity = 2
  max_capacity = 4
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
    priority                   = 100 
  }

  tags = {
    Environment = var.environment
  }
}