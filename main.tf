provider "azurerm" {
  features {}
}

resource "null_resource" "vm_manage" {

  depends_on = [null_resource.ip_manage]

  provisioner "local-exec" {
    command = "az vm start --resource-group workstation_group --name workstation"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az vm deallocate --resource-group workstation_group --name workstation"
  }
}

resource "azurerm_public_ip" "workstation" {
  name                = "controller-public-ip"
  location            = "Denmark East"
  resource_group_name = "workstation_group"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "null_resource" "ip_manage" {

  depends_on = [azurerm_public_ip.workstation]

  provisioner "local-exec" {
    command = "az network nic ip-config update --resource-group workstation_group --nic-name workstation636_z1 --name ipconfig1 --public-ip-address controller-public-ip"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az network nic ip-config update --resource-group workstation_group --nic-name workstation636_z1 --name ipconfig1 --public-ip-address \"\""
  }
}

output "ip" {
  value = azurerm_public_ip.workstation.ip_address
}

data "azurerm_subnet" "default" {
  name                 = "default"
  virtual_network_name = "controller-vnet"
  resource_group_name  = "denmark-east-rg"
}

resource "azurerm_public_ip" "natgw" {
  name                = "natgw-public-ip"
  location            = "Denmark East"
  resource_group_name = "denmark-east-rg"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                    = "controller-natgw"
  location                = "Denmark East"
  resource_group_name     = "denmark-east-rg"
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "main" {

  depends_on = [
    azurerm_nat_gateway_public_ip_association.main
  ]

  subnet_id      = data.azurerm_subnet.default.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
