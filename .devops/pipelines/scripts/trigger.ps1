param(
    [string]
    $Address,

    [int]
    $PipelineId,

    [string]
    $Token,

    [string]
    $Branch
)

$uri = "$($Address)/_apis/pipelines/$($PipelineId)/runs?api-version=7.0"
$header = @{Authorization = "Bearer $Token" }

$body = @{
    "resources" = @{
        "repositories" = @{
            "self" = @{
                "refName" = $branch
            }
        }
    }
}

$run = Invoke-RestMethod -Method POST -Uri $uri -Headers $header -ContentType "application/json" -Body $($body | ConvertTo-Json -Depth 10)

while ($run.state -eq "inProgress") {
    Write-Output "Pipeline is in progress."
    $run = Invoke-RestMethod -Method GET -Uri $run.url -Headers $header -ContentType "application/json"
    Start-Sleep 5
}

if ($run.result -ne "succeeded") {
    exit 3
} else {
    exit 0
}