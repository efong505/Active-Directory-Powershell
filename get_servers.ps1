[CmdletBinding()]
param(
    [string]$OutputFile = (Join-Path $PSScriptRoot 'servers.txt'),
    [string]$OperatingSystemFilter = '*Server*'
)

$ErrorActionPreference = 'Stop'
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $servers = @(Get-ADComputer -Filter { OperatingSystem -like $OperatingSystemFilter } -Properties OperatingSystem -ErrorAction Stop |
        Select-Object -ExpandProperty Name |
        Where-Object { $_ -match '^[A-Za-z0-9][A-Za-z0-9.-]*$' } |
        Sort-Object -Unique)
    if ($servers.Count -eq 0) {
        throw 'No matching server computer objects were found. No password changes will be attempted.'
    }
    $servers | Set-Content -LiteralPath $OutputFile -Encoding UTF8 -ErrorAction Stop
    Write-Output "Discovered $($servers.Count) servers. Saved to $OutputFile"
}
catch {
    throw "Server discovery failed. No password changes will be attempted. $($_.Exception.Message)"
}
