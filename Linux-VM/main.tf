resource "azurerm_resource_group" "rg_demo_service" {
  location = var.resource_group_location
  name     = var.resource_group_name_prefix
}

# Create virtual network
resource "azurerm_virtual_network" "demo_service_network" {
  name                = "demoServiceVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_demo_service.location
  resource_group_name = azurerm_resource_group.rg_demo_service.name
}

# Create subnet
resource "azurerm_subnet" "demo_service_subnet" {
  name                 = "demoServiceSubnet"
  resource_group_name  = azurerm_resource_group.rg_demo_service.name
  virtual_network_name = azurerm_virtual_network.demo_service_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "demo_service_public_ip" {
  name                = "demoServiceIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_demo_service.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "demo_service_nsg" {
  name                = "demoServiceNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_demo_service.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "demo_service_nic" {
  name                = "demoServiceNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg_demo_service.name

  ip_configuration {
    name                          = "demoService_nic_configuration"
    subnet_id                     = azurerm_subnet.demo_service_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_service_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.demo_service_nic.id
  network_security_group_id = azurerm_network_security_group.demo_service_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg_demo_service.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "demoService_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg_demo_service.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "demo_service_vm" {
  name                  = "demoServiceVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg_demo_service.name
  network_interface_ids = [azurerm_network_interface.demo_service_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "demoServiceOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}