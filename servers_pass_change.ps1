[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$InputFile,
    [string]$OutputDirectory = $PSScriptRoot,
    [string]$LocalAccount = 'Administrator'
)

$ErrorActionPreference = 'Stop'
if (-not $InputFile) {
    $InputFile = Join-Path $OutputDirectory 'servers.txt'
    & (Join-Path $PSScriptRoot 'get_servers.ps1') -OutputFile $InputFile
}
if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    throw "Server list not found: $InputFile"
}
& (Join-Path $PSScriptRoot 'change_password_script.ps1') -InputFile $InputFile -OutputDirectory $OutputDirectory -LocalAccount $LocalAccount -WhatIf:$WhatIfPreference -Confirm:$false
