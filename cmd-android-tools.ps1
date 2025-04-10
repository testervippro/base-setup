# ===============================
# Minimal Android SDK Setup (Windows) - Lightweight Pixel System Image Only
# ===============================

# Configuration
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$buildToolsVersion = "34.0.0"

# Ensure SDK root directory exists
if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Download SDK if not already downloaded
if (-Not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# Extract command line tools
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# Set environment variables
$env:ANDROID_HOME = $androidSdkRoot
$env:ANDROID_SDK_ROOT = $androidSdkRoot
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")

# Add SDK paths to system PATH
$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Install required packages
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;$buildToolsVersion"
)

function Install-PackageIfMissing {
    param([string]$pkg)
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkg
    if (-not $installed) {
        Write-Host "Installing: $pkg"
        & $sdkmanager $pkg --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "Already installed: $pkg"
    }
}

foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

# ===============================
# Post-Install Checks
# ===============================
Write-Host "`nVerifying installation..."

# Refresh environment for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

# Check if sdkmanager is available
Write-Host "`n[sdkmanager -h]"
sdkmanager -h

# Check if aapt2 is available
Write-Host "`n[aapt2 version]"
aapt2 version

# List available AVDs
Write-Host "`n[emulator -list-avds]"
emulator -list-avds

# List AVDs via avdmanager
Write-Host "`n[avdmanager list avd]"
avdmanager list avd
