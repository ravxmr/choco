$ErrorActionPreference = 'Stop'

$installDir = 'C:\Program Files\Feather Wallet'

# ============================================================
# UNINSTALL FEATHER WALLET
# ============================================================

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName  = 'Feather Wallet*'
  fileType       = 'exe'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

$uninstalled = $false

[array]$key = Get-UninstallRegistryKey -SoftwareName $packageArgs.softwareName

if ($key.Count -eq 1) {
    $key | ForEach-Object {
        $packageArgs.file = $_.UninstallString
        Write-Host "Uninstalling Feather Wallet..." -ForegroundColor Cyan
        Uninstall-ChocolateyPackage @packageArgs
    }
}
elseif ($key.Count -eq 0) {
    Write-Warning "$($packageArgs.packageName) was not found in the registry - it may have already been uninstalled."
}
elseif ($key.Count -gt 1) {
    Write-Warning "$($key.Count) registry matches found for '$($packageArgs.softwareName)'!"
    Write-Warning "No automatic uninstall will be performed to prevent accidental data loss."
    Write-Warning "Uninstall manually or narrow the softwareName filter."
    return
}

# ============================================================
# REMOVE WINDOWS DEFENDER EXCLUSIONS
# ============================================================

Write-Host "`nRemoving Windows Defender exclusions..." -ForegroundColor Cyan

try {
    Remove-MpPreference -ExclusionPath $installDir -ErrorAction Stop
    Write-Host "  [OK] Removed path exclusion: $installDir"
}
catch {
    Write-Verbose "Path exclusion already absent or could not be removed: $_"
}

try {
    Remove-MpPreference -ExclusionProcess 'feather.exe' -ErrorAction Stop
    Write-Host "  [OK] Removed process exclusion: feather.exe"
}
catch {
    Write-Verbose "Process exclusion already absent or could not be removed: $_"
}

try {
    Remove-MpPreference -ExclusionProcess 'tor.exe' -ErrorAction Stop
    Write-Host "  [OK] Removed process exclusion: tor.exe"
}
catch {
    Write-Verbose "Process exclusion already absent or could not be removed: $_"
}

# Clean up the empty install directory if it still exists
if (Test-Path $installDir) {
    try {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Removed leftover directory: $installDir"
    }
    catch {
        Write-Warning "Could not remove '$installDir' - it may contain user data (wallet files). Remove it manually if desired."
    }
}
