param (
    # Settings Json
    [Parameter(Mandatory = $false)]
    [string]
    $SettingsFile = "settings.json",

    # Azure DevOps PAT Token
    [Parameter(Mandatory = $true)]
    [string]
    $AdoPat
)

