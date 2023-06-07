<#
  .SYNOPSIS
  Create or Update a variable within a Library Variable Group 

  .DESCRIPTION
  You can use Set-LibraryGroupVariable to update/create a variable in an AzureDevOps Variable Group. If the variable group does not exist, it will create one. 

  Note: You cannot create a variable group with a secret as the first value.

  .EXAMPLE

  # Update a variable named `myVariableName` in a library-variable-group `myVariableGroup` within the project `ERIS Application build` that is in the Organization `ULERIS`
  PS> .\Set-LibraryGroupVariable.ps1 -Organization 'ULERIS' -ProjectNameOrId 'ERIS Application build' -VariableGroupName 'myVariableGroup' -VariableName 'myVariableName' -VariableValue 'myVariableValue' 

  .EXAMPLE

  # Update a SECRET variable named `myVariableName` in a library-variable-group `myVariableGroup` within the project `ERIS Application build` that is in the Organization `ULERIS`
  PS> .\Set-LibraryGroupVariable.ps1 -Organization 'ULERIS' -ProjectNameOrId 'ERIS Application build' -VariableGroupName 'myVariableGroup' -VariableName 'myVariableName' -VariableValue $env:SecretValue -SECRET

  .LINK

  https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows#from-a-variable

  .LINK

  https://docs.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az_pipelines_variable_group_create

  .LINK

  https://docs.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az_pipelines_variable_group_update

  .LINK

  https://docs.microsoft.com/en-us/cli/azure/pipelines/variable-group?view=azure-cli-latest#az_pipelines_variable_group_list

#>
[CmdletBinding()]
param (
    # DevOps Organization
    [Parameter(Mandatory)]
    [string]
    $Organization
    ,
    # DevOps Project
    [Parameter(Mandatory)]
    [string]
    $ProjectNameOrId
    ,
    # VariableGroup Name
    [Parameter(Mandatory)]
    [String]
    $VariableGroupName
    ,
    # VariableGroup Description
    [Parameter(Mandatory = $false)]
    [String]
    $VariableGroupDescription
    ,
    # Variable Name
    [Parameter(Mandatory)]
    [String]
    $VariableName
    ,
    # VariableValue
    [Parameter(Mandatory)]
    [System.Object]
    $VariableValue
    ,
    # VariableValue
    [Parameter()]
    [switch]
    $Secret
)

$HelpersPath = Get-item -Path "$($PSScriptRoot)/VariableGroupHelper.ps1"
. $HelpersPath

$null = Connect-AzureDevOpsProject -Organization $Organization -ProjectNameOrId $ProjectNameOrId

if ($Secret) {
    $null = Set-AzureDevOpsVariableGroupVariable -VariableGroupName $VariableGroupName -VariableName $VariableName -VariableValue $VariableValue -Secret
}else{
    $null = Set-AzureDevOpsVariableGroupVariable -VariableGroupName $VariableGroupName -VariableName $VariableName -VariableValue $VariableValue
}