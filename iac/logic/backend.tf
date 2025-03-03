resource "azurerm_public_ip" "gateway_public_ip" {
  name                = "${local.naming_convention}-gateway-public-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine_scale_set" "back_ss" {
  name                = "${local.naming_convention}-back-ss"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"
  admin_password         = "Distribuidos2022"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${local.naming_convention}-back-nic"
    primary = true

    ip_configuration {
      name      = "publicbackend"
      primary   = true
      subnet_id = azurerm_subnet.subnet_backend.id
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.gateway.backend_address_pool[*].id
    }
  }
}

resource "azurerm_application_gateway" "gateway" {
  name                = "${local.naming_convention}-application-gateway"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${local.naming_convention}-gateway-ip"
    subnet_id = azurerm_subnet.subnet_gateway.id
  }

  frontend_port {
    name = "${local.naming_convention}-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.naming_convention}-gateway-public-ip"
    public_ip_address_id = azurerm_public_ip.gateway_public_ip.id
  }

  backend_address_pool {
    name = "${local.naming_convention}-backend-address-pool"
  }

  backend_http_settings {
    name                  = "${local.naming_convention}-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${local.naming_convention}-http-listener"
    frontend_ip_configuration_name = "${local.naming_convention}-gateway-public-ip"
    frontend_port_name             = "${local.naming_convention}-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.naming_convention}-request-routing-roule"
    rule_type                  = "Basic"
    http_listener_name         = "${local.naming_convention}-http-listener"
    backend_address_pool_name  = "${local.naming_convention}-backend-address-pool"
    backend_http_settings_name = "${local.naming_convention}-http-settings"
  }
}