data "azurerm_key_vault" "kv_shared" {
  name                = var.shared_sub_key_vault_name
  resource_group_name = var.shared_sub_key_vault_resource_group
}