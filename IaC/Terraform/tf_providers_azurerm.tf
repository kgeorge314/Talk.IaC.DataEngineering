provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

/*
 * export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
 * export ARM_CLIENT_SECRET="12345678-0000-0000-0000-000000000000"
 * export ARM_TENANT_ID="10000000-0000-0000-0000-000000000000"
 * export ARM_SUBSCRIPTION_ID="20000000-0000-0000-0000-000000000000"
*/