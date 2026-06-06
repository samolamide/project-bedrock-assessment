# Generate grading.json with ONLY the five required capstone outputs (no secrets).
$ErrorActionPreference = "Stop"
Push-Location "$PSScriptRoot\..\terraform"

$required = @(
    "cluster_endpoint",
    "cluster_name",
    "region",
    "vpc_id",
    "assets_bucket_name"
)

$all = terraform output -json | ConvertFrom-Json
$result = @{}
foreach ($key in $required) {
    $result[$key] = $all.$key
}

$json = $result | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText(
    "$PSScriptRoot\..\grading.json",
    $json,
    [System.Text.UTF8Encoding]::new($false)
)

Pop-Location
Write-Host "Wrote grading.json (required outputs only, no secrets)"
