
resource "azurerm_resource_group" "rg" {
  name     = "rg-demo-terraform-${local.environment}-"
  location = local.location
}