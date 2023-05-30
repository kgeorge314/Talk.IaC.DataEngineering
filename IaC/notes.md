# Demo Notes

## Setup

```ps1
    az login  
    az account set --subscription Azure-Personal-PayG
    ./IaC/Backend/deploy-core.ps1
    az logout
```

## Terraform Init

```ps1
    $BackendArg = '-backend-config='
    $BackendStateFile = 'tf-state-dev'
    $BackendConfigArgs = '{0}"storage_account_name={1}" {0}"container_name={2}" {0}"key={3}"' -f $BackendArg, $env:BACKEND_STORAGE_ACCOUNT, $env:BACKEND_STORAGE_ACCOUNT_CONTAINER, $BackendStateFile
    Write-output "terraform init -input=false -force-copy $BackendConfigArgs"
```