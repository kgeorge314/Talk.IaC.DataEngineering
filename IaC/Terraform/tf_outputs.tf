output "resource_group" {
  description = "The resource group where Azure resources for this environment are deployed"
  value       = azurerm_resource_group.rg
}

output "adf_main" {
  description = "Main Azure Data Factory"
  value       = azurerm_data_factory.adf_main
}

output "st_main" {
  description = "Main Storage Account"
  value       = azurerm_storage_account.st_main
  sensitive   = true

}