  
$cleanSubName = (az account show | ConvertFrom-Json).name -replace '[^a-zA-Z0-9 ]' , '_'
$commitId = Invoke-Expression "git log --pretty=format:%h -n 1"
$subId = az account show --query id --output tsv
$displayName = "IaC.AzSpn.Talk.$cleanSubName.$commitId"
$resourceGroupName = "Talk-IaC-DataEngineer.TerraformState"
$location = "northeurope"


# Setup AAD Application
Write-Output "1. Creating AAD Application"
$existingAdApp = (az ad app list --display-name $displayName  | ConvertFrom-Json | Where-Object -Property displayName -eq $displayName | Select-Object -First 1)
if (-not ($existingAdApp)) {
    $existingAdApp = (az ad app create --display-name $displayName --sign-in-audience 'AzureADMyOrg' --enable-id-token-issuance true | ConvertFrom-Json)
}


# Setup AAD Application SPN
Write-Output "2. Creating Service Principal for $($existingAdApp.displayName)"
$existingAdAppSpn = (az ad sp list --display-name $displayName | ConvertFrom-Json | Where-Object -Property appId -EQ $existingAdApp.appId)
if(-not($existingAdAppSpn)){
    $null = az ad sp create --id $existingAdApp.id
    $existingAdAppSpn = (az ad sp list --display-name $displayName | ConvertFrom-Json | Where-Object -Property appId -EQ $existingAdApp.appId)
}

# Setup Credential
Write-Output "3. Creating Credential for Service Principal for $($existingAdAppSpn.displayName)"
$secretExpiresIn2Hours = (Get-Date).ToUniversalTime().AddHours(2)
$secretExpiresIn2HoursUnix = [int64](Get-Date $secretExpiresIn2Hours  -UFormat %s)   
$azADSecretsPlain = az ad app credential reset --id $existingAdApp.id --display-name 'rbac' --end-date $secretExpiresIn2Hours.ToString("yyyy-MM-ddTHH:mm:ss+00:00") | ConvertFrom-Json

# Setup Backend Core Resources 
Write-Output "4. Deploying Core Resources to $resourceGroupName"
$templateFile = "$PSScriptRoot/core-resources.bicep"
$tenantId = (az account show | ConvertFrom-Json).tenantId

$parameters = @{
    "TenantId" = @{
        "value" = $tenantId
    };
    "ObjectIds"            = @{
        "value" = @($existingAdAppSpn.id)
    };
    "SPNName" = @{
        "value" = $existingAdAppSpn.displayName
    };
    "SPNSecret" = @{
        "value" = $azADSecretsPlain.password
    };
    "SPNSecretExpiry" = @{
        "value" = $secretExpiresIn2HoursUnix
    };
}

$deploymentName = "$((Get-Item $templateFile).Name)-$((New-Guid).Guid)"
az group create --name $resourceGroupName --location $location 
az deployment group create --name $deploymentName --resource-group $resourceGroupName --template-file $templateFile --parameters "$($parameters | ConvertTo-Json -Compress)"

$outputs = az deployment group show --resource-group $resourceGroupName --name $deploymentName --query properties.outputs | ConvertFrom-Json

# Grant RBAC
Write-Output "5. Grant Contributor Role for $($existingAdAppSpn.displayName)[$($existingAdAppSpn.id)]"

az role assignment create --assignee-object-id $existingAdAppSpn.id --assignee-principal-type ServicePrincipal --role Contributor --scope "/subscriptions/$subId"

# Prepare Terraform
$env:ARM_CLIENT_ID=$existingAdApp.appId
$env:ARM_CLIENT_SECRET=$azADSecretsPlain.password
$env:ARM_TENANT_ID=$tenantId
$env:ARM_SUBSCRIPTION_ID=$subId
$env:ARM_USE_AZUREAD ='true'

$env:BACKEND_STORAGE_ACCOUNT = $outputs.tf_state_storage_account_name.value
$env:BACKEND_STORAGE_ACCOUNT_CONTAINER = $outputs.tf_state_storage_account_container_name.value