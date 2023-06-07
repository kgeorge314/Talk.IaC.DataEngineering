BeforeDiscovery {
    Write-host "Phase[Discovery]: Used only for setting up TestCases" 
    #"Phase[Discovery] variables are NOT Accessible  in It, BeforeAll, BeforeEach, AfterAll or AfterEach" 
    #"UNLESS explicitly linked to a 'Test' using -TestCases/-ForEach"
    # See More https://pester-docs.netlify.app/docs/usage/data-driven-tests#beforediscovery


    Write-Host "Phase[Discovery]: Setup Helper"
    . $PSScriptRoot/../../Tools/Azure/AzureHelper.ps1

    # Connect To Azure
    Write-Host "Phase[Discovery]: Connecting to Azure"
    Connect-ToAzure
    
    # Get the StateFile, so that we can read Tf outputs i.e. Get-TerraformOutputValue
    Write-Host "Phase[Discovery]: Get Terraform statefile"
    Get-TerraformStateFile

    # Test Cases
    Write-Host "Phase[Discovery]: Setup DataDriven Tests"
    
    Write-Host "Phase[Discovery]:   Preparing GlobalParameter Tests"

    $AzureDataFactoryName = @( (Get-TerraformOutputValue 'adf_main').name )

    $TestCaseHasGlobalParameter = @(
         @{GlobalParameterName = 'resource_group'         ; GlobalParameterType = 'String'; ExpectedGlobalParameterValue = (Get-TerraformOutputValue 'resource_group').name } 
        ,@{GlobalParameterName = 'master_storage_account' ; GlobalParameterType = 'String'; ExpectedGlobalParameterValue = (Get-TerraformOutputValue 'st_main').name } 
        
    )

    $TestCaseGlobalParameterCount = @(@{"ExpectedGlobalParameterCount" = $TestCaseHasGlobalParameter.Count })
    
    Write-Host "Phase[Discovery]: Cleanup Post Discovery"
    Remove-TerraformStateFile
}

BeforeAll {
    Write-host "Phase[Run]: only accessible in It, BeforeAll, BeforeEach, AfterAll or AfterEach" 
    Write-Host "Phase[Run]: Setup Helper"
    . $PSScriptRoot/../../Tools/Azure/AzureHelper.ps1

    # Connect To Azure
    Write-Host "Phase[Run]: Connecting to Azure"
    Connect-ToAzure
    
    # Get the StateFile, so that we can read Tf outputs i.e. Get-TerraformOutputValue
    Write-Host "Phase[Run]: Get Terraform statefile"
    Get-TerraformStateFile


}

Describe "DataFactory" -ForEach $AzureDataFactoryName {
    BeforeAll { 
        # See https://pester.dev/docs/usage/data-driven-tests#execution-is-not-top-down
        $azureDataFactoryName = $_ 
        $ActualDataFactory = Get-AzDataFactoryV2 | Where-Object -Property DataFactoryName -EQ $azureDataFactoryName | Select-Object -First 1
        $ActualDataFactoryGlobalParameters = $ActualDataFactory.GlobalParameters
    }
    # DataFactory Deployed
    Context " Delployed" {
        It " a DataFactory exists" {
            $ActualDataFactory | Should -Not -BeNullOrEmpty
        }
        It ' has Global Parameters' {
            $ActualDataFactory.GlobalParameters | Should -Not -BeNullOrEmpty
        }    
    }

    # DataFactory GlobalParameter: Values
    Context ' GlobalParameter (value)' {
        It ' a name of [<GlobalParameterName>] of [<GlobalParameterType>] with value [<ExpectedGlobalParameterValue>]' -TestCases $TestCaseHasGlobalParameter {
            param
            (
                [string] $GlobalParameterName,
                [string] $GlobalParameterType,
                [string] $ExpectedGlobalParameterValue
            )

            # Parameter Exists
            $ActualDataFactoryGlobalParameters.ContainsKey($GlobalParameterName) | Should -Be $true
            # Parameter is correct Type
            $ActualDataFactoryGlobalParameters.$GlobalParameterName.Type        | Should -Be $GlobalParameterType
            # Parameter is correct Value
            $ActualDataFactoryGlobalParameters.$GlobalParameterName.Value       | Should -Be $ExpectedGlobalParameterValue

        }
    }
    # DataFactory GlobalParameter: Count
    Context ' GlobalParameter (count)' {
        It ' is [<ExpectedGlobalParameterCount>]' -TestCases $TestCaseGlobalParameterCount {
            param(
                [int] $ExpectedGlobalParameterCount
            )
            $ActualDataFactoryGlobalParameters.Count | Should -Be $ExpectedGlobalParameterCount
        }
    }
}

AfterAll {
    Write-Host "Cleaning Up"
    Remove-TerraformStateFile
}