variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "ssh_key_name_prefix" {
  type        = string
  default     = "ssh"
  description = "SSH prefix"
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg_demo_service"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}