[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$InputFile,

    [string]$OutputDirectory = (Split-Path -Parent (Resolve-Path -LiteralPath $InputFile).Path),

    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]*$')]
    [string]$LocalAccount = 'Administrator'
)

$ErrorActionPreference = 'Stop'
$computers = @(Get-Content -LiteralPath $InputFile -ErrorAction Stop |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and $_ -notmatch '^#' } |
    Sort-Object -Unique)
if ($computers.Count -eq 0) { throw 'Input file contains no computer names.' }
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Output directory does not exist: $OutputDirectory"
}

$results = foreach ($computer in $computers) {
    $status = 'SKIPPED'
    $online = $false
    if ($computer -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*$') {
        [pscustomobject]@{ ComputerName = $computer; IsOnline = $false; PasswordChangeStatus = 'INVALID_NAME' }
        continue
    }

    try {
        $online = [bool](Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop)
    }
    catch {
        $online = $false
    }
    if (-not $online) {
        [pscustomobject]@{ ComputerName = $computer; IsOnline = $false; PasswordChangeStatus = 'UNREACHABLE' }
        continue
    }

    $target = "$computer local account $LocalAccount"
    if (-not $PSCmdlet.ShouldProcess($target, 'Set local account password')) {
        [pscustomobject]@{ ComputerName = $computer; IsOnline = $true; PasswordChangeStatus = 'NOT_EXECUTED' }
        continue
    }

    $firstPtr = [IntPtr]::Zero
    $secondPtr = [IntPtr]::Zero
    $plainPassword = $null
    $plainConfirmation = $null
    try {
        $password = Read-Host "New password for $target" -AsSecureString
        $confirmation = Read-Host "Confirm password for $target" -AsSecureString
        $firstPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $secondPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmation)
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($firstPtr)
        $plainConfirmation = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secondPtr)
        if ([string]::IsNullOrEmpty($plainPassword) -or $plainPassword -cne $plainConfirmation) {
            $status = 'PASSWORD_MISMATCH_OR_EMPTY'
        }
        else {
            $account = [ADSI]("WinNT://$computer/$LocalAccount,user")
            $account.psbase.Invoke('SetPassword', $plainPassword)
            $status = 'SUCCESS'
        }
    }
    catch {
        $status = 'FAILED'
        Write-Warning "Password change failed for $computer. Check permissions, connectivity, and account configuration."
    }
    finally {
        $plainPassword = $null
        $plainConfirmation = $null
        $password = $null
        $confirmation = $null
        if ($firstPtr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($firstPtr)
        }
        if ($secondPtr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secondPtr)
        }
    }
    [pscustomobject]@{ ComputerName = $computer; IsOnline = $online; PasswordChangeStatus = $status }
}

$results | Format-Table -AutoSize
$reportPath = Join-Path $OutputDirectory 'password-change-results.csv'
$results | Export-Csv -LiteralPath $reportPath -NoTypeInformation -ErrorAction Stop
Write-Output "Results saved to $reportPath (no passwords included)."
