output "resource_group" {
  description = "The resource group where Azure resources for this environment are deployed"
  value       = azurerm_resource_group.rg
}
