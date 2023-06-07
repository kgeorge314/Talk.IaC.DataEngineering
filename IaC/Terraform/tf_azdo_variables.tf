resource "null_resource" "var_az_resource_group_name" {
  triggers = {
    if_changes = azurerm_resource_group.rg.name
  }

  provisioner "local-exec" {
    command     = "${path.module}/../../Tools/AzureDevOps/Set-LibraryGroupVariable.ps1  -Organization '${local.azdo_organization}' -ProjectNameOrId '${local.azdo_projectNameOrId}' -VariableGroupName '${local.azdo_variableGroupName}' -VariableGroupDescription '${local.azdo_variableGroupDescription}' -VariableName az_resource_group_name -VariableValue '${azurerm_resource_group.rg.name}'"
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "ByPass", "-Command"]
  }
  depends_on = [azurerm_resource_group.rg]
}

resource "null_resource" "var_az_adf_name" {
  triggers = {
    if_changes = azurerm_data_factory.adf_main.name
  }

  provisioner "local-exec" {
    command     = "${path.module}/../../Tools/AzureDevOps/Set-LibraryGroupVariable.ps1  -Organization '${local.azdo_organization}' -ProjectNameOrId '${local.azdo_projectNameOrId}' -VariableGroupName '${local.azdo_variableGroupName}' -VariableGroupDescription '${local.azdo_variableGroupDescription}' -VariableName az_adf_name -VariableValue '${azurerm_data_factory.adf_main.name}'"
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "ByPass", "-Command"]
  }
  depends_on = [azurerm_resource_group.rg]
}

resource "null_resource" "var_az_storage_account_name" {
  triggers = {
    if_changes = azurerm_storage_account.st_main.name
  }

  provisioner "local-exec" {
    command     = "${path.module}/../../Tools/AzureDevOps/Set-LibraryGroupVariable.ps1  -Organization '${local.azdo_organization}' -ProjectNameOrId '${local.azdo_projectNameOrId}' -VariableGroupName '${local.azdo_variableGroupName}' -VariableGroupDescription '${local.azdo_variableGroupDescription}' -VariableName az_storage_account_name -VariableValue '${azurerm_storage_account.st_main.name}'"
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "ByPass", "-Command"]
  }
  depends_on = [azurerm_resource_group.rg]
}

resource "null_resource" "var_az_storage_account_key_secret" {
  triggers = {
    if_changes = azurerm_storage_account.st_main.primary_access_key
  }

  provisioner "local-exec" {
    command     = "${path.module}/../../Tools/AzureDevOps/Set-LibraryGroupVariable.ps1  -Organization '${local.azdo_organization}' -ProjectNameOrId '${local.azdo_projectNameOrId}' -VariableGroupName '${local.azdo_variableGroupName}' -VariableGroupDescription '${local.azdo_variableGroupDescription}' -VariableName az_storage_account_key -VariableValue '${azurerm_storage_account.st_main.primary_access_key}' -Secret"
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "ByPass", "-Command"]
  }
  depends_on = [azurerm_resource_group.rg]
}