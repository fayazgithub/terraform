output "resource_group_name" {
  value = azurerm_resource_group.rg_demo_service.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.demo_service_vm.public_ip_address
}