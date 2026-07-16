param(
    [Parameter(Mandatory = $true)]
    [string]$FirstApk,

    [Parameter(Mandatory = $true)]
    [string]$SecondApk,

    [Parameter(Mandatory = $true)]
    [string]$ApplicationId
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $FirstApk)) {
    throw "First APK was not found: $FirstApk"
}

if (-not (Test-Path -LiteralPath $SecondApk)) {
    throw "Second APK was not found: $SecondApk"
}

$adb = Get-Command adb -ErrorAction Stop

& $adb.Source devices
if ($LASTEXITCODE -ne 0) {
    throw "adb devices failed."
}

& $adb.Source install -r $FirstApk
if ($LASTEXITCODE -ne 0) {
    throw "First APK install failed."
}

& $adb.Source shell monkey -p $ApplicationId 1
if ($LASTEXITCODE -ne 0) {
    throw "First APK launch failed."
}

& $adb.Source install -r $SecondApk
if ($LASTEXITCODE -ne 0) {
    throw "Upgrade install failed."
}

& $adb.Source shell pm path $ApplicationId
if ($LASTEXITCODE -ne 0) {
    throw "Application package was not found after upgrade."
}

Write-Output "Upgrade install verification passed for $ApplicationId."
