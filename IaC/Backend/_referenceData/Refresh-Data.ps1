Write-Output "Checking Azure Connection"
# Check if connected to Azure
if (! (Get-AzContext -ErrorAction SilentlyContinue)) {
    Connect-AzAccount    
}

Write-Output "Refresing Azure Locations"
# Get All Azure Locations
Write-Output " * Collecting Azure Locations"
$azLocations = Get-AzLocation


Write-Output " * Calculating ShortCodes"
$kvp = @{}
$lasyDuplicateCheck = @{}
# Generate a Shortcode - First Letter between a space
foreach ($a in $azLocations) {
    
    #Split SouthEast to (SE), Split Norway to (NR), to keep codes unique
    $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Norway', 'No Rway').Split(' ')  | ForEach-Object { $_[0] }) -join ''

    #exceptions 
    switch -regex ($a.DisplayName) {
        'UK South' { $shortCode = 'UKS' }
        'UK West' { $shortCode = 'UKW' }
        'East US' { $shortCode = 'EUS' }
        'East US 2' { $shortCode = 'US2' }
        'East US 2 EUAP' { $shortCode = 'USP' }
        'Global' { $shortCode = 'GLB' }
        'Asia' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Asia', 'A Sia').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Switzerland' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Switzerland', 'Swit Zerland').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Australia' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Australia', 'A Ustralia').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Europe' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Europe', 'E Urope').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Japan' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Japan', 'Ja Pan').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Korea' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Korea', 'Ko Rea').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'UAE' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('UAE', 'A E').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'India' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('India', 'I Ndia').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'France' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('France', 'F Rance').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Canada' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Canada', 'Ca Nada').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        'Qatar' { $shortCode = ($a.DisplayName.Replace('Southeast', 'South East').Replace('Qatar', 'Qa Tar').Split(' ')  | ForEach-Object { $_[0] }) -join '' }
        Default {}
    }
    

    if ($lasyDuplicateCheck.ContainsKey($shortCode)) {
        Write-Warning "Skipping [$($a.DisplayName)], the code [$shortCode] conflicts with [$($lasyDuplicateCheck["$shortCode"])]"
    }
    else {
        # Location | Shortcode KVP
        Write-verbose "  $($a.DisplayName) | $($shortCode)"
        $kvp.Add($a.Location, $shortCode)
        $lasyDuplicateCheck.Add($shortCode, $a.DisplayName)
    }
}

# Write Data
Write-Output " * Saving Data to .\Data.Azure.Locations.json"
$azLocations | Sort-Object -Property Location | Select-Object Location , DisplayName  , @{n = 'ShortCode'; e = { $kvp["$($_.location)"] } } | ConvertTo-Json | Out-File -Encoding utf8 -FilePath "$($PSScriptRoot)\Data.Azure.Locations.json"

Write-Output " * Generating Data to .\LookupVariable.Azure.Locations.json"
$Locations = Get-Content "$($PSScriptRoot)\Data.Azure.Locations.json" | ConvertFrom-Json | Sort-Object -Property location 

$LookupData = [ordered]@{}
foreach ($location in $Locations) {
    $kvp = @{
        "Shortcode"   = $location.Shortcode;
        "DisplayName" = $location.DisplayName;        
    }

    $LookupData.Add($location.Location, $kvp)
}
@{'lookup_azure_locations' = $LookupData } | ConvertTo-Json  | Out-File -Encoding utf8 -FilePath "$($PSScriptRoot)\LookupVariable.Azure.Locations.json"

Write-Output "Refresing Azure Roles"

Write-Output " * Collecting Azure Roles and Data"
$AzRoleList = Get-AzRoleDefinition 

Write-Output " * Saving Data to .\Data.Azure.Roles.json"
$AzRoleList | Sort-Object -Property Name | Select-Object Id, Name, Description , Actions, DataActions, @{n = 'ArmTemplateExpression'; e = { "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Authorization/roleDefinitions/', '$($_.Id)')]" } } | ConvertTo-Json | Out-File -Encoding utf8 -FilePath "$($PSScriptRoot)\Data.Azure.Roles.json"

Write-Output " * Generating Data to .\LookupVariable.Azure.Roles.json"
$Roles = Get-Content "$($PSScriptRoot)\Data.Azure.Roles.json" | ConvertFrom-Json | Sort-Object -Property Name
$LookupData = [ordered]@{}
foreach ($role in $Roles) {
    $kvp =  [ordered]@{
        "Id"          = $role.Id;
        "Expression"  = $role.ArmTemplateExpression;
        "Description" = $role.Description ;
    }

    $LookupData.Add($role.Name, $kvp)
}
@{'lookup_azure_roles' = $LookupData } | ConvertTo-Json | Out-File "$($PSScriptRoot)\LookupVariable.Azure.Roles.json"
