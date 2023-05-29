  
$cleanSubName = (az account show | ConvertFrom-Json).name -replace '[^a-zA-Z0-9 ]' , '_'
$displayName = "IaC.AzSpn.Talk.$cleanSubName"
$resourceGroupName = "Talk-IaC-DataEngineer.TerraformState"
$location = "northeurope"


# Setup AAD Application
$existingAdApp = (az ad app list --display-name $displayName  | ConvertFrom-Json | Where-Object -Property displayName -eq $displayName | Select-Object -First 1)
if (-not ($existingAdApp)) {
    $existingAdApp = (az ad app create --display-name $displayName --sign-in-audience 'AzureADMyOrg' --enable-id-token-issuance true | ConvertFrom-Json)
}


# Setup AAD Application SPN
$existingAdAppSpn = (az ad sp list --display-name $displayName | ConvertFrom-Json | Where-Object -Property appId -EQ $existingAdApp.appId)
if(-not($existingAdAppSpn)){
    $existingAdAppSpn = az ad sp create --id $existingAdApp.id
}

# Setup Credential
$secretExpiresIn2Hours = (Get-Date).ToUniversalTime().AddHours(2)
$secretExpiresIn2HoursUnix = [int64](Get-Date $secretExpiresIn2Hours  -UFormat %s)   
$azADSecretsPlain = az ad app credential reset --id $existingAdApp.id --display-name 'rbac' --end-date $secretExpiresIn2Hours.ToString("yyyy-MM-ddTHH:mm:ss+00:00") | ConvertFrom-Json

# Setup Backend Core Resources 
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

az group create --name $resourceGroupName --location $location 
az deployment group create --resource-group $resourceGroupName  --template-file $templateFile --parameters "$($parameters | ConvertTo-Json -Compress)"

