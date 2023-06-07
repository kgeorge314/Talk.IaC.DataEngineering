$script:temporary_tf_state_file_download_path = "$([system.io.path]::GetTempPath())/$([guid]::NewGuid().Guid)-state.json"

Function Connect-ToAzure {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string]$AzureTenantID = $env:ARM_TENANT_ID,

        [Parameter()]
        [string]$ServicePrincipalID = $env:ARM_CLIENT_ID,

        [Parameter()]
        [string]$ServicePrincipalSecret = $env:ARM_CLIENT_SECRET,

        [Parameter()]
        [string]$SubscriptionID = $env:ARM_SUBSCRIPTION_ID
    )

    if (-not(Get-AzContext)) {
        $SecurePassword = ConvertTo-SecureString -String $ServicePrincipalSecret -AsPlainText -Force
        $SPCredential = [pscredential]::new($ServicePrincipalID, $SecurePassword)
        $Null = Connect-AzAccount -ServicePrincipal -Credential $SPCredential -Tenant $AzureTenantID
    }
    elseif ($SubscriptionID) {
        Set-AzContext -Subscription $SubscriptionID
    }
    $context = Get-AzContext
    Write-Host "Using"
    Write-Host " Subscription : [$($context.Subscription.Name)]"

    return($context)
}

function Get-TerraformStateFile {
    param (
        # Terraform Backend State Storage Account
        [Parameter()]
        [string]
        $BackendStateStorageAccountName = $env:TF_STATE_BACKEND_STORAGE_ACCOUNT
        ,
        # Terraform Backend State Container Name
        [Parameter()]
        [string]
        $BackendStateContainerName = $env:TF_STATE_BACKEND_STORAGE_ACCOUNT_CONTAINER
        ,
        # Terraform Backend State File Name
        [Parameter()]
        [string]
        $BackendStateFileName = $env:TF_STATE_FILE_NAME
    )
    $azStorageAccount = Get-AzStorageAccount | Where-Object -Property StorageAccountName -EQ $BackendStateStorageAccountName | Select-Object -First 1
    if($azStorageAccount -and ($azStorageAccount.StorageAccountName -eq $BackendStateStorageAccountName)){
        $azStorageBlobContent = Get-AzStorageBlobContent -Container $BackendStateContainerName -Blob $BackendStateFileName -Context $azStorageAccount.Context -Destination $script:temporary_tf_state_file_download_path -Force
    }

    if(-not($azStorageBlobContent)){
        Write-Error "Could not download state file"
    }

    Write-Host "StateFile Download completed [$script:temporary_tf_state_file_download_path]"
}

function Remove-TerraformStateFile {
    
    if (Test-Path $script:temporary_tf_state_file_download_path) {
        # Remove temporarily downloaed TF state file
        Remove-Item -path $script:temporary_tf_state_file_download_path
        Write-Host "StateFile Download Removed [$script:temporary_tf_state_file_download_path]"
    }
}

function Get-TerraformOutputValue {
    param(
        # State File Local Path
        [Parameter(Mandatory)]
        [string]
        $VariableName
    )
    
    if (Test-Path $script:temporary_tf_state_file_download_path) {
        $tf_state = Get-Content -path $script:temporary_tf_state_file_download_path | ConvertFrom-Json

        if ($tf_state.outputs."$VariableName".value) {
            return $tf_state.outputs."$VariableName".value
        }
        else {
            return $null
        }

    }
    else {
        Write-Error "$script:temporary_tf_state_file_download_path is invalid, please use Get-TerraformStateFile"
    }

}