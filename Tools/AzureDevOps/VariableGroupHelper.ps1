$Script:Connect_AzureDevOps_Success = $false

function Connect-AzureDevOpsProject {
    [CmdletBinding()]
    param (
        # DevOps Organization
        [Parameter(Mandatory)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Organization
        ,
        # DevOps Project
        [Parameter(Mandatory)]
        [string]
        [ValidateNotNullOrEmpty()]
        $ProjectNameOrId
    )
    
    begin {
        Write-Host "1. Authenticating to Azure DevOps"
        Write-Host "   * Requires Agent setting 'Allow scripts to access the OAuth token' enabled"
        Write-Host "   * Requires Environment variable [AZURE_DEVOPS_EXT_PAT]"
        Write-Host "     see more here https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows#from-a-variable" 

        if ($null -eq $env:AZURE_DEVOPS_EXT_PAT -or '' -eq $env:AZURE_DEVOPS_EXT_PAT) {
            Write-Error "Azure [AZURE_DEVOPS_EXT_PAT] to be set and Agent setting 'Allow scripts to access the OAuth token' enabled"
        }
    }
    
    process {
        Write-Host " a. Logging into [https://dev.azure.com/$Organization/]"
        Write-Output  "$env:AZURE_DEVOPS_EXT_PAT"  | az devops login --organization "https://dev.azure.com/$Organization/"
    
        Write-Host " b. Connecting to Organization and Project [https://dev.azure.com/$Organization/$ProjectName]"
        Write-Host "     * Setting Organization:[$Organization]"
        $null = az devops configure -d organization="https://dev.azure.com/$Organization/"
        Write-Host "     * Setting Project:[$Organization]/[$ProjectNameOrId] (Spaces are accepted for ProjectName)"
        $null = az devops configure -d project="$ProjectNameOrId"
    }
    
    end {
        $Script:Connect_AzureDevOps_Success = $true
        return $null
    }
}

function Get-AzureDevOpsVariableGroup {
    [CmdletBinding()]
    param (
        # VariableGroup Name
        [Parameter(Mandatory)]
        [String]            
        [ValidateNotNullOrEmpty()]
        $VariableGroupName
    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }
    }
    
    process {
        
    }
    
    end {
        return (az pipelines variable-group list --group-name $VariableGroupName | ConvertFrom-Json | Select-Object -First 1)
    }
}

function Set-AzureDevOpsVariableGroup {
    [CmdletBinding()]
    param (
        # VariableGroup Name
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableGroupName
        ,
        # VariableGroup Description
        [Parameter(Mandatory = $false)]
        [String]
        $VariableGroupDescription
     
    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }

        # Setup Default Variable
        $default_variable = 'comment_variable_group_creator="Set-AzureDevOpsVariableGroup"'
        
        # Check Blank Description
        if ($null -eq $VariableGroupDescription -or '' -eq $VariableGroupDescription) {
            $VariableGroupDescription = "Variable Created using Set-AzureDevOpsVariableGroup on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }    
    }
    
    process {
        Write-Host "* Searching for Variable Group [$VariableGroupName]"

        $variableGroup = az pipelines variable-group list --group-name $VariableGroupName | ConvertFrom-Json | Select-Object -First 1

        if (-not($variableGroup)) {
            Write-Host " * Creating Variable Group [$VariableGroupName]"
            $result = az pipelines variable-group create --name $VariableGroupName --description "'$($VariableGroupDescription | ConvertTo-Json)'" --authorize $true --variables $default_variable
            $VariableGroupName = ($result | ConvertFrom-Json).name
        }

        
    }
    
    end {
        return (Get-AzureDevOpsVariableGroup -VariableGroupName $VariableGroupName)
    }
}

function Get-AzureDevOpsVariableGroupVariableValue {
    [CmdletBinding()]
    param (
        # VariableGroup Name
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableGroupName
        ,
        # Variable Name
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableName
    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }
        $VariableGroup = Get-AzureDevOpsVariableGroup -VariableGroupName $VariableGroupName
        if (-not($VariableGroup)) {
            Write-Error "Cannot Find VariableGroup [$VariableGroupName]"
        }
    }
    
    process {
        if ($VariableGroup.variables.$VariableName) {
            $variable = $VariableGroup.variables.$VariableName
        }
        else {
            $variable = $null
        }
    }
    
    end {
        return $variable
    }
}

function Set-AzureDevOpsVariableGroupVariable {
    [CmdletBinding()]
    param (
        # VariableGroup Name
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableGroupName
        ,
        # Variable Name
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableName
        ,
        # VariableValue
        [Parameter(Mandatory)]
        [System.Object]
        [ValidateNotNullOrEmpty()]
        $VariableValue
        ,
        # Secret
        [Parameter()]
        [switch]
        $Secret        
    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }

        # Get VariableGroup or Create One
        $VariableGroup = Get-AzureDevOpsVariableGroup -VariableGroupName $VariableGroupName
        if (-not($VariableGroup)) {
            $VariableGroup = Set-AzureDevOpsVariableGroup -VariableGroupName $VariableGroupName
        }

        $SecretFlag = $false
        if ($Secret) {
            $SecretFlag = $true
        }
    }
    
    process {
        Write-Host " Selected [$($variableGroup.name)][$($variableGroup.id)]"
        Write-Host "  Found Variables [$($variableGroup.name)][$($variableGroup.id)]"
        ($variableGroup.variables | Get-Member -MemberType NoteProperty) | Select-Object Name | ForEach-Object { Write-Host "     - $($_.Name) $(if ($_.Name.ToLower() -eq $VariableName.ToLower()){'[*]'})" }

        # Set = Create/Update
        if ($variableGroup.variables.$VariableName) {
            Write-Host " Update Variable [$VariableName] in [$VariableGroupName]"
    
            if ($($variableGroup.variables.$VariableName.isSecret)) {
                $currentValue = '******'
            }
            else {
                $currentValue = $($variableGroup.variables.$VariableName.value)
            }

            Write-Host "    Current Value [$VariableName] : [$currentValue]"
            Write-Host "    New Value     [$VariableName] : [$(if(!($Secret)){$VariableValue}else{'******'})]"

            $response = az pipelines variable-group variable update --group-id "$($variableGroup.id)" --name $VariableName --value $VariableValue --secret $SecretFlag 
        
        }
        else {
            Write-Host " Create Variable [$VariableName] in [$VariableGroupName]"
            Write-Host "    New Value    [$VariableName] : [$(if(!($Secret)){$VariableValue}else{'******'})]"

            $response = az pipelines variable-group variable create --group-id "$($variableGroup.id)" --name $VariableName --value $VariableValue --secret $SecretFlag 

        }
        Write-Host "Response = [$response]"
    }
    
    end {
        return ($response | ConvertFrom-Json)
    }
}

function New-AzureDevOpsVariableGroupFromJson {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $JsonConfigPaths   
    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }
    }
    
    process {
        $results = @()
        foreach ($JsonConfigFilePath in $JsonConfigPaths) {

            $thisFile = Get-Item -Path $JsonConfigFilePath -ErrorAction SilentlyContinue
            if(-not($thisFile)){
                Write-Warning "Could not find file [$JsonConfigFilePath], Skipping File"
                continue
            }

            $config = Get-Content -Path $thisFile.FullName | ConvertFrom-Json

            #validate config
            if (-not($config.variableGroupName)) {
                Write-Error "Invalid [variableGroupName] is missing"
            }
            
            # Create VariableGroup
            if ($config.variableGroupDescription) { $variableGroupDescription = $config.variableGroupDescription }else { $variableGroupDescription = '' }
            Set-AzureDevOpsVariableGroup -VariableGroupName $config.variableGroupName -VariableGroupDescription $variableGroupDescription

            $variables = ($config.variableGroupVariables | Get-Member -MemberType NoteProperty).Name
            foreach ($variableName in $variables) {
                $splat_parameters = @{
                    'VariableGroupName' = $config.variableGroupName;
                    'VariableName'      = $variableName;
                    'VariableValue'     = $config.variableGroupVariables.$variableName.value;
                    'Secret'            = $config.variableGroupVariables.$variableName.isSecret;

                }
                $results += Set-AzureDevOpsVariableGroupVariable @splat_parameters
            }
        }        
    }
    
    end {
        return $results
    }
}

function Get-AzureDevOpsVariableGroupToJson {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $VariableGroupName
        

    )
    
    begin {
        # Check if Authenticated
        if (-not($Script:Connect_AzureDevOps_Success)) {
            Write-Error "Run Connect-AzureDevOpsProject First" -ErrorAction Stop
        }
    }
    process {
        $VariableGroup = Get-AzureDevOpsVariableGroup -VariableGroupName $VariableGroupName   

        $VariableGroupConfigObject = New-Object -TypeName PSObject 
        $VariableGroupConfigObject | Add-Member -MemberType NoteProperty -Name 'variableGroupName' -Value $VariableGroup.name
        $VariableGroupConfigObject | Add-Member -MemberType NoteProperty -Name 'variableGroupDescription' -Value $VariableGroup.description

        $variables = ($VariableGroup.variables | Get-Member -MemberType NoteProperty).Name
        $variableGroupVariables = [ordered]@{}
        foreach ($variable in $variables) {

            $value = @{
                'value'    = $VariableGroup.variables.$variable.value;
                'isSecret' = $(if ($VariableGroup.variables.$variable.isSecret) { $true }else { $false })
            }

            $variableGroupVariables.Add($variable,$value)
            

        }
        $VariableGroupConfigObject | Add-Member -MemberType NoteProperty -Name variableGroupVariables -Value $variableGroupVariables
        
    }
    
    end {
        $VariableGroupConfigObject | ConvertTo-Json -Depth 10
    }
}