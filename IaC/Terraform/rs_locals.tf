locals {
  location    = var.location
  environment = var.environment

  # AzureDevOps
  azdo_organization             = "kgeorge314"
  azdo_projectNameOrId          = "Playground"
  azdo_variableGroupName        = "IaC.${data.azurerm_subscription.current.display_name}.${azurerm_resource_group.rg.name}"
  azdo_variableGroupDescription = "IaC Setup via Terraform for ${azurerm_resource_group.rg.name}"
}