param(
    $sampleFile,
    $type = 'CSV', 
    $csvHeader = "",
    $csvDelimiter = ","
)

Add-Type -AssemblyName Newtonsoft.Json.Schema

$logs = Get-Content $sampleFile

switch ($type) {
    "CSV" {
        $parameters = @{}
        if($csvHeader){
            $parameters.Add('Header', $csvHeader)
        }
        if($csvDelimiter){
            $parameters.Add('Delimiter', $csvDelimiter)
        }
        $data = $logs | ConvertFrom-Csv @parameters | ConvertTo-Json
    }
}

$schemaGenerator = [Newtonsoft.Json.Schema.JsonSchemaGenerator]::new()
$schema = $schemaGenerator.Generate([System.IO.StringReader]::new($data))

# Convert the schema to JSON and write it to a file
$schemaJson = $schema.ToString()
Set-Content -Path "$sampleFile.schema.json" -Value $schemaJson

