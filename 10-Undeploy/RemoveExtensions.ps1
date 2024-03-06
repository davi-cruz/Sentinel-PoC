## Connect to Azure Account
Connect-AzAccount

## ARG Queries
$query_DCR = @"
resources
| where ['type'] == "microsoft.insights/datacollectionrules"
| project id
"@

$query_extensions = @"
resources
| where ['type'] == "microsoft.hybridcompute/machines/extensions"
| project id
"@

## List all DCR associations in the tenant
$DCRs = Search-AzGraph -Query $query_DCR
foreach($dcr in $DCRs.id){
    $result = Invoke-AzRestMethod -Path "$dcr/associations?api-version=2022-06-01" -Method GET | Select-Object -ExpandProperty Content
    $associations += $result | ConvertFrom-Json | Select-Object -ExpandProperty value
}

## Remove all associations
foreach($association in $associations){
    Invoke-AzRestMethod -Method DELETE -Path "$($association.id)?api-version=2022-06-01"
}

## List all extensions in the tenant
$Extensions = Search-AzGraph -Query $query_extensions

## Remove all extensions
foreach($extension in $Extensions){
    Invoke-AzRestMethod -Method DELETE -Path "$($extension.id)?api-version=2023-06-20-preview"
}