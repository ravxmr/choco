$ErrorActionPreference = 'Stop'

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version    = '0.18.5.0'
$installDir = 'C:\Program Files\Monero GUI Wallet'

# ---- CONFIGURATION ----
$url64      = "https://downloads.getmonero.org/gui/monero-gui-install-win-x64-v$version.exe"
$checksum64 = '2aee0fb9a4a858199da46ce3344e7d6dec080efeab21c599903379e3e1d29dec'
# ------------------------

# ============================================================
# WINDOWS DEFENDER EXCLUSIONS
# Monero wallets are frequently flagged as malicious by
# Windows Defender (false positive). We add exclusions BEFORE
# the download and install to prevent quarantine.
# ============================================================

# Temp directory where Chocolatey caches downloads
$chocoTempDir = $env:TEMP

Write-Host "Adding Windows Defender exclusions to prevent false-positive quarantine..." -ForegroundColor Cyan

# Exclude the Chocolatey temp/cache folder so the installer
#    binary is not quarantined mid-download.
try {
    Add-MpPreference -ExclusionPath $chocoTempDir\monero-wallet-gui -ErrorAction Stop
    Write-Host "  [OK] Excluded download cache: $chocoTempDir"
}
catch {
    Write-Warning "Could not add Defender exclusion for download cache: $_"
}

# Pre-create & exclude the install target directory so that
#    Defender doesn't quarantine files as they are extracted.
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}
try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction Stop
    Write-Host "  [OK] Excluded install directory: $installDir"
}
catch {
    Write-Warning "Could not add Defender exclusion for install directory: $_"
}

# Exclude the monero-wallet-gui.exe process so it isn't killed at runtime.
try {
    Add-MpPreference -ExclusionProcess 'monero-wallet-gui.exe' -ErrorAction Stop
    Write-Host "  [OK] Excluded process: monero-wallet-gui.exe"
}
catch {
    Write-Warning "Could not add Defender process exclusion: $_"
}

# Exclude the monerod.exe process so it isn't killed at runtime.
try {
    Add-MpPreference -ExclusionProcess 'monerod.exe' -ErrorAction Stop
    Write-Host "  [OK] Excluded process: monerod.exe"
}
catch {
    Write-Warning "Could not add Defender process exclusion: $_"
}
# ============================================================
# INSTALL
# ============================================================

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName  = 'Monero GUI Wallet*'
  fileType       = 'exe'
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
  silentArgs     = "/VERYSILENT /DIR=`"$installDir`""
  validExitCodes = @(0)
}

Write-Host "`nInstalling Monero GUI Wallet..." -ForegroundColor Cyan
Install-ChocolateyPackage @packageArgs

# ============================================================
# POST-INSTALL: Clean up the temp exclusion
# The install-directory & process exclusions must REMAIN so
# that Defender doesn't quarantine Monero-GUI at runtime.
# The temp/cache exclusion is no longer needed.
# ============================================================

try {
    Remove-MpPreference -ExclusionPath $chocoTempDir\monero-wallet-gui -ErrorAction Stop
    Write-Host "`nRemoved Defender exclusion for download cache (no longer needed)." -ForegroundColor DarkGray
}
catch {
    # Non-critical — the temp folder is cleaned up by Chocolatey anyway
    Write-Verbose "Could not remove Defender temp exclusion (non-critical): $_"
}

# Verify the executable survived Defender
$moneroExe = Join-Path $installDir 'monero-wallet-gui.exe'
if (Test-Path $moneroExe) {
    Write-Host "Monero GUI Wallet installed successfully: $moneroExe" -ForegroundColor Green
}
else {
    Write-Warning "monero-wallet-gui.exe not found at expected path. Windows Defender may have quarantined it."
    Write-Warning "If so, open Windows Security -> Protection history -> Restore the file, then add an exclusion manually."
}
