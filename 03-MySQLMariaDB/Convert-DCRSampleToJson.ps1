<#
.SYNOPSIS
Converts a sample log file to JSON format to be used with Log Analytics new Table Wizard

.DESCRIPTION
This script reads a sample log file and converts it to JSON format. The output is written to a file with the same name as the input file, but with a .json extension.

.PARAMETER sampleFile
The path to the sample log file to convert.

.EXAMPLE
Convert-DCRSampleToJson.ps1 -sampleFile "C:\Logs\sample.log"
Converts the sample.log file to JSON format and writes the output to sample.log.json.

.NOTES
Author: Davi Cruz
Date:   10/5/2023
#>

param(
    $sampleFile
)

$logs = Get-Content $sampleFile
$data = $logs | ForEach-Object {
    Select-Object -Property @{Name='RawData';Expression={$_}}
}

$data | ConvertTo-Json | Out-File -FilePath "$sampleFile.json" -Encoding utf8

param(
    $sampleFile
)

$logs = Get-Content $sampleFile
$data = $logs | ForEach-Object {
    Select-Object -Property @{Name='RawData';Expression={$_}}
}

$data | ConvertTo-Json | Out-File -FilePath "$sampleFile.json" -Encoding utf8