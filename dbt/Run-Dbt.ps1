# Run dbt
$currentDirectory = Get-Location

$dbtProjectPath = Join-Path $PSScriptRoot swim_data_warehouse_dbt

Set-Location $dbtProjectPath

dbt build

Set-Location $currentDirectory
