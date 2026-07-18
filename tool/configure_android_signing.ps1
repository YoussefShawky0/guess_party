param(
    [string]$KeystorePath = "C:\Users\COMPUMARTS\.guess-party\signing\guess-party-upload.jks",
    [string]$KeyAlias = "guess-party-upload"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $KeystorePath -PathType Leaf)) {
    throw "Upload keystore was not found at the approved path."
}

$storePasswordSecure = Read-Host "Enter the Guess Party upload keystore password" -AsSecureString
$keyPasswordSecure = Read-Host "Enter the Guess Party upload key password" -AsSecureString
$storePasswordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePasswordSecure)
$keyPasswordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPasswordSecure)

try {
    $storePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($storePasswordPtr)
    $keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPasswordPtr)
    if ([string]::IsNullOrWhiteSpace($storePassword) -or [string]::IsNullOrWhiteSpace($keyPassword)) {
        throw "Signing passwords cannot be empty."
    }

    # Windows PowerShell surfaces keytool's harmless JKS-format warning from
    # stderr as NativeCommandError when ErrorActionPreference is Stop. Suppress
    # native output and trust the process exit code for verification.
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & keytool -list -keystore $KeystorePath -alias $KeyAlias -storepass $storePassword 1> $null 2> $null
    $keytoolExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($keytoolExitCode -ne 0) {
        throw "The keystore path, alias, or password could not be verified."
    }

    $propertiesPath = Join-Path $PSScriptRoot "..\android\key.properties"
    $escapedPath = $KeystorePath.Replace("\", "/")
    $contents = @(
        "storeFile=$escapedPath"
        "storePassword=$storePassword"
        "keyAlias=$KeyAlias"
        "keyPassword=$keyPassword"
    )
    [IO.File]::WriteAllLines($propertiesPath, $contents, [Text.UTF8Encoding]::new($false))

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        & icacls $propertiesPath /inheritance:r /grant:r "${env:USERNAME}:(R,W)" *> $null
    }

    Write-Output "Android signing is configured locally. Passwords were not printed."
    Write-Output "The ignored properties file is: $propertiesPath"
} finally {
    if ($null -ne $storePasswordPtr) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($storePasswordPtr)
    }
    if ($null -ne $keyPasswordPtr) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPasswordPtr)
    }
    Remove-Variable storePassword, keyPassword -ErrorAction SilentlyContinue
}
