locals {
  rg_suffix = substr(tostring(sha1(azurerm_resource_group.rg.id)), 0, 3)
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-demo-terraform-${local.environment}-${local.azure_location_shortcode}"
  location = local.location
}

resource "azurerm_storage_account" "st_main" {
  name                            = "st0${local.environment}0${local.azure_location_shortcode}0${local.rg_suffix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    Environment              = var.environment
    "DataManagement Team"    = "Cool Data Team"
    "DataManagement Layer"   = "Core"
    "DataManagement Purpose" = "Storage account for Data Pipelines"
  }
}

resource "azurerm_data_factory" "adf_main" {
  name                = "adf-${local.environment}-${local.azure_location_shortcode}-${local.rg_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }

  global_parameter {
    name  = "master_storage_account"
    type  = "String"
    value = azurerm_storage_account.st_main.name
  }

  global_parameter {
    name  = "resource_group"
    type  = "String"
    value = azurerm_resource_group.rg.name
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_role_assignment" "adf_main_to_blob" {
  principal_id         = azurerm_data_factory.adf_main.identity[0].principal_id
  scope                = azurerm_storage_account.st_main.id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.st_main.name
  key_vault_id = data.azurerm_key_vault.kv_shared.id

}
