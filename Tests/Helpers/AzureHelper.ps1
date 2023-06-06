
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
