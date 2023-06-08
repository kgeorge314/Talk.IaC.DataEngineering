# Demo Notes

## Setup

> ⛔️ Purge deleted KeyVaults.

```ps1
    az login  
    az account set --subscription Azure-Personal-PayG

    ./IaC/Backend/deploy-core.ps1
    az logout
```

## Terraform

### Init

```ps1
    Push-Location
    Set-Location ./IaC/Terraform/  
    
    $argPrefix = '-backend-config='
    $env:TF_STATE_FILE_NAME = 'tf-state-dev'
    $tfBackEndArgs = '{0}"storage_account_name={1}" {0}"container_name={2}" {0}"key={3}"' -f $argPrefix, $env:TF_STATE_BACKEND_STORAGE_ACCOUNT, $env:TF_STATE_BACKEND_STORAGE_ACCOUNT_CONTAINER, $env:TF_STATE_FILE_NAME
    Write-output "terraform init -input=false -force-copy $tfBackEndArgs"

```

### Plan

```ps1
    terraform plan -input=false -out=tfplan
```

### Apply

```ps1
    terraform apply -input=false -auto-approve tfplan
```

### Review

1. Azure Portal
    1. KeyVault / Secret
    1. StateFile
1. Azure DevOps
    1. Config
1. Run Tests
    1. _Optional_ Manually Edit Global Parameter
    1. _Optional_ Manually Add/Edit Global Parameter
1. Tear Down

### Test

```ps1
    Pop-Location
    Invoke-Pester ./Tests/Infra/rs_infra_core.Test.ps1 -Output Detailed
```

### Destroy

```ps1
    Set-Location ./IaC/Terraform/  
    terraform destroy -auto-approve

```
