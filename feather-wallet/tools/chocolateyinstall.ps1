$ErrorActionPreference = 'Stop'

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version    = '2.8.1'
$installDir = 'C:\Program Files\Feather Wallet'

# ---- CONFIGURATION ----
$url64      = "https://github.com/feather-wallet/feather/releases/download/$version/FeatherWalletSetup-$version.exe"
$checksum64 = '2763a246ffe6cf0aef290c4344fc12de33582d4fa834b0049e4deb7daa5eb529'
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
    Add-MpPreference -ExclusionPath $chocoTempDir\feather-wallet -ErrorAction Stop
    Write-Host "  [OK] Excluded download cache: $chocoTempDir\feather-wallet"
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

# Exclude the feather.exe process so it isn't killed at runtime.
try {
    Add-MpPreference -ExclusionProcess 'feather.exe' -ErrorAction Stop
    Write-Host "  [OK] Excluded process: feather.exe"
}
catch {
    Write-Warning "Could not add Defender process exclusion: $_"
}

# Exclude the tor.exe process so it isn't killed at runtime.
try {
    Add-MpPreference -ExclusionProcess 'tor.exe' -ErrorAction Stop
    Write-Host "  [OK] Excluded process: tor.exe"
}
catch {
    Write-Warning "Could not add Defender process exclusion: $_"
}

# ============================================================
# INSTALL
# ============================================================

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName  = 'Feather Wallet*'
  fileType       = 'exe'
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
  silentArgs     = "/S /D=`"$installDir`""
  validExitCodes = @(0)
}

Write-Host "`nInstalling Feather Wallet..." -ForegroundColor Cyan
Install-ChocolateyPackage @packageArgs

# ============================================================
# POST-INSTALL: Clean up the temp exclusion
# The install-directory & process exclusions must REMAIN so
# that Defender doesn't quarantine Feather at runtime.
# The temp/cache exclusion is no longer needed.
# ============================================================

try {
    Remove-MpPreference -ExclusionPath $chocoTempDir\feather-wallet -ErrorAction Stop
    Write-Host "`nRemoved Defender exclusion for download cache (no longer needed)." -ForegroundColor DarkGray
}
catch {
    # Non-critical — the temp folder is cleaned up by Chocolatey anyway
    Write-Verbose "Could not remove Defender temp exclusion (non-critical): $_"
}

# Verify the executable survived Defender
$featherExe = Join-Path $installDir 'feather.exe'
if (Test-Path $featherExe) {
    Write-Host "Feather Wallet installed successfully: $featherExe" -ForegroundColor Green
}
else {
    Write-Warning "feather.exe not found at expected path. Windows Defender may have quarantined it."
    Write-Warning "If so, open Windows Security → Protection history → Restore the file, then add an exclusion manually."
}
